package com.example.android_companion_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.telephony.TelephonyManager
import org.json.JSONObject
import java.io.BufferedReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.util.concurrent.Executors

class CallPollingService : Service() {
    companion object {
        @Volatile var isRunning: Boolean = false
        const val CHANNEL_ID = "crm_call_companion_channel"
        const val NOTIFICATION_ID = 7301
    }

    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private var polling = false
    private var endingCall = false
    private var receiverRegistered = false

    private val callStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
            val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
            when (state) {
                TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                    prefs().edit().putBoolean("active_call_offhook", true).apply()
                    saveLast("Call connected/offhook. Starting recording...")
                    updateNotification("Call active. Recording in progress...")
                    if (prefs().getBoolean("auto_recording_enabled", true)) {
                        CallRecorder.start(this@CallPollingService)
                    }
                }
                TelephonyManager.EXTRA_STATE_IDLE -> {
                    val wasOffhook = prefs().getBoolean("active_call_offhook", false)
                    val requestId = prefs().getInt("active_request_id", 0)
                    if (wasOffhook && requestId > 0) {
                        handleCallEnded("Phone returned idle")
                    }
                }
            }
        }
    }

    private val pollRunnable = object : Runnable {
        override fun run() {
            if (isRunning && !polling) pollOnce()
            val seconds = prefs().getInt("polling_seconds", 3).coerceAtLeast(3)
            handler.postDelayed(this, seconds * 1000L)
        }
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createChannel()
        startForeground(NOTIFICATION_ID, buildNotification("Waiting for CRM call request..."))
        registerCallStateReceiver()
        saveLast("Service started. Waiting for call request...")
        handler.post(pollRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        isRunning = true
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        isRunning = false
        handler.removeCallbacksAndMessages(null)
        unregisterCallStateReceiver()
        executor.shutdownNow()
        saveLast("Service stopped")
        super.onDestroy()
    }

    private fun pollOnce() {
        polling = true
        executor.execute {
            try {
                val p = prefs()
                val crmUrl = (p.getString("crm_url", "") ?: "").trimEnd('/')
                val token = p.getString("mobile_token", "") ?: ""
                val userId = p.getInt("user_id", 0)
                val autoCallEnabled = p.getBoolean("auto_call_enabled", true)
                val autoRecordingEnabled = p.getBoolean("auto_recording_enabled", true)

                if (crmUrl.isBlank() || token.isBlank() || userId <= 0) {
                    saveLast("Missing CRM login session")
                    return@execute
                }

                val activeRequestId = p.getInt("active_request_id", 0)
                val activeCompleted = p.getBoolean("active_call_completed", false)
                if (activeRequestId > 0 && !activeCompleted) {
                    saveLast("Active request #$activeRequestId running. Waiting for call end...")
                    return@execute
                }

                val url = "$crmUrl/api/get-call-request.php?user_id=$userId&token=${enc(token)}"
                val body = httpGet(url, token)
                val json = JSONObject(body)

                if (json.optBoolean("success", false)) {
                    val req = json.optJSONObject("request") ?: return@execute
                    val requestId = req.optInt("id", 0)
                    val leadId = req.optInt("lead_id", 0)
                    val phone = req.optString("phone", "")
                    val leadName = req.optString("lead_name", "Lead")

                    if (requestId <= 0 || leadId <= 0 || phone.isBlank()) {
                        saveLast("Invalid pending request received")
                        return@execute
                    }

                    val lastStarted = p.getInt("last_started_request_id", 0)
                    if (lastStarted == requestId) {
                        saveLast("Already handled request #$requestId")
                        return@execute
                    }

                    updateNotification("CRM request found: $leadName")
                    saveLast("Pending request #$requestId found for $leadName $phone")

                    val picked = updateStatus(crmUrl, token, userId, requestId, "picked", "Android app picked request and started mobile SIM call")
                    if (!picked) {
                        saveLast("Could not update picked status for #$requestId")
                        return@execute
                    }

                    p.edit()
                        .putInt("last_started_request_id", requestId)
                        .putInt("active_request_id", requestId)
                        .putInt("active_lead_id", leadId)
                        .putString("active_lead_name", leadName)
                        .putString("active_phone", phone)
                        .putBoolean("active_call_offhook", false)
                        .putBoolean("active_call_completed", false)
                        .apply()

                    CallRecorder.preparePending(this, crmUrl, token, userId, requestId, leadId, leadName, phone)

                    if (autoCallEnabled) {
                        val called = DirectCaller.makeCall(this, phone, requestId)
                        if (called) {
                            saveLast("Direct call started: $leadName $phone")
                            updateNotification("Call started: $leadName")

                            // Fallback: some devices do not send PHONE_STATE quickly for outgoing calls.
                            if (autoRecordingEnabled) {
                                handler.postDelayed({
                                    val currentRequest = prefs().getInt("active_request_id", 0)
                                    val completed = prefs().getBoolean("active_call_completed", false)
                                    if (currentRequest == requestId && !completed && !CallRecorder.isRecording) {
                                        saveLast("Starting recording fallback for request #$requestId")
                                        CallRecorder.start(this)
                                    }
                                }, 4500L)
                            }

                            // Safety fallback: if phone state end event is blocked, complete after configured max minutes.
                            val maxMinutes = prefs().getInt("max_recording_minutes", 30).coerceIn(1, 120)
                            handler.postDelayed({
                                val currentRequest = prefs().getInt("active_request_id", 0)
                                val completed = prefs().getBoolean("active_call_completed", false)
                                if (currentRequest == requestId && !completed) {
                                    handleCallEnded("Max recording time reached")
                                }
                            }, maxMinutes * 60_000L)
                        } else {
                            updateStatus(crmUrl, token, userId, requestId, "failed", "Android blocked direct call or CALL_PHONE permission missing")
                            clearActiveCall()
                            saveLast("Direct call failed/blocked for #$requestId")
                            updateNotification("Call failed/blocked. Open app and allow permission.")
                        }
                    } else {
                        saveLast("Auto-call OFF. Request #$requestId picked but not called.")
                        updateNotification("Auto-call OFF. Open app.")
                    }
                } else {
                    val msg = json.optString("message", "No pending call request")
                    if (!msg.lowercase().contains("no pending")) saveLast(msg)
                    updateNotification("Waiting for CRM call request...")
                }
            } catch (e: Exception) {
                saveLast("Polling error: ${e.message}")
                updateNotification("CRM polling error. Check internet/login.")
            } finally {
                polling = false
            }
        }
    }

    private fun handleCallEnded(reason: String) {
        if (endingCall) return
        endingCall = true
        executor.execute {
            val p = prefs()
            val crmUrl = (p.getString("active_crm_url", p.getString("crm_url", "") ?: "") ?: "").trimEnd('/')
            val token = p.getString("active_token", p.getString("mobile_token", "") ?: "") ?: ""
            val userId = p.getInt("active_user_id", p.getInt("user_id", 0))
            val requestId = p.getInt("active_request_id", 0)

            try {
                if (requestId <= 0 || crmUrl.isBlank() || token.isBlank() || userId <= 0) {
                    saveLast("Call ended but active request/session missing")
                    return@execute
                }

                updateNotification("Call ended. Uploading recording...")
                saveLast("Call ended for request #$requestId. $reason")

                val recordingEnabled = p.getBoolean("auto_recording_enabled", true)
                val uploadResult = if (recordingEnabled) {
                    CallRecorder.stopAndUpload(this, "completed")
                } else {
                    CallRecorder.UploadResult(true, "Recording disabled", duration = "-")
                }

                val message = if (uploadResult.success) {
                    "Call completed. ${uploadResult.message}"
                } else {
                    "Call completed. ${uploadResult.message}"
                }

                updateStatus(
                    crmUrl,
                    token,
                    userId,
                    requestId,
                    "completed",
                    message,
                    duration = uploadResult.duration,
                    notes = message,
                    callStatus = "Completed"
                )

                p.edit()
                    .putBoolean("active_call_completed", true)
                    .putString("last_message", message)
                    .apply()
                updateNotification(message)
                clearActiveCall()
            } catch (e: Exception) {
                saveLast("Call completion failed: ${e.message}")
                updateNotification("Call completed but upload/status failed")
            } finally {
                endingCall = false
            }
        }
    }

    private fun updateStatus(
        crmUrl: String,
        token: String,
        userId: Int,
        requestId: Int,
        status: String,
        message: String,
        duration: String = "",
        notes: String = "",
        callStatus: String = ""
    ): Boolean {
        return try {
            val params = StringBuilder()
                .append("user_id=").append(userId)
                .append("&token=").append(enc(token))
                .append("&request_id=").append(requestId)
                .append("&status=").append(enc(status))
                .append("&message=").append(enc(message))
            if (duration.isNotBlank()) params.append("&duration=").append(enc(duration))
            if (notes.isNotBlank()) params.append("&notes=").append(enc(notes))
            if (callStatus.isNotBlank()) params.append("&call_status=").append(enc(callStatus))
            val response = httpPost("$crmUrl/api/update-call-request.php", token, params.toString())
            JSONObject(response).optBoolean("success", false)
        } catch (e: Exception) {
            saveLast("Status update failed: ${e.message}")
            false
        }
    }

    private fun httpGet(urlText: String, token: String): String {
        val con = (URL(urlText).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 15000
            readTimeout = 15000
            setRequestProperty("X-Mobile-Token", token)
            setRequestProperty("Accept", "application/json")
        }
        return readConnection(con)
    }

    private fun httpPost(urlText: String, token: String, params: String): String {
        val con = (URL(urlText).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 15000
            readTimeout = 15000
            doOutput = true
            setRequestProperty("X-Mobile-Token", token)
            setRequestProperty("Content-Type", "application/x-www-form-urlencoded")
            setRequestProperty("Accept", "application/json")
        }
        OutputStreamWriter(con.outputStream).use { it.write(params) }
        return readConnection(con)
    }

    private fun readConnection(con: HttpURLConnection): String {
        val stream = if (con.responseCode in 200..299) con.inputStream else con.errorStream
        return BufferedReader(stream.reader()).use { it.readText() }
    }

    private fun enc(value: String): String = URLEncoder.encode(value, "UTF-8")

    private fun prefs() = getSharedPreferences("companion_prefs", Context.MODE_PRIVATE)

    private fun saveLast(message: String) {
        prefs().edit().putString("last_message", message).apply()
    }

    private fun clearActiveCall() {
        prefs().edit()
            .remove("active_request_id")
            .remove("active_lead_id")
            .remove("active_lead_name")
            .remove("active_phone")
            .remove("active_call_offhook")
            .remove("active_call_completed")
            .remove("active_recording_path")
            .remove("active_recording_started_ms")
            .remove("active_crm_url")
            .remove("active_token")
            .remove("active_user_id")
            .apply()
    }

    private fun registerCallStateReceiver() {
        if (receiverRegistered) return
        try {
            val filter = IntentFilter(TelephonyManager.ACTION_PHONE_STATE_CHANGED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(callStateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                registerReceiver(callStateReceiver, filter)
            }
            receiverRegistered = true
        } catch (e: Exception) {
            saveLast("Call state receiver failed: ${e.message}")
        }
    }

    private fun unregisterCallStateReceiver() {
        if (!receiverRegistered) return
        try { unregisterReceiver(callStateReceiver) } catch (_: Exception) {}
        receiverRegistered = false
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "CRM Call Companion",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "Keeps CRM mobile calling and recording service active"
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String): Notification {
        val openIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        @Suppress("DEPRECATION")
        return builder
            .setSmallIcon(android.R.drawable.sym_action_call)
            .setContentTitle("CRM Auto-Call Active")
            .setContentText(text)
            .setOngoing(true)
            .setContentIntent(pendingIntent)
            .setPriority(Notification.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(text: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(text))
    }
}
