package com.example.android_companion_app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.io.BufferedReader
import java.io.File
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URLEncoder
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import org.json.JSONArray
import org.json.JSONObject

class CallPollingService : Service() {
    private lateinit var prefs: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private val polling = AtomicBoolean(false)
    private val uploadRetrying = AtomicBoolean(false)
    private var phoneStateListener: PhoneStateListener? = null
    private var telephonyManager: TelephonyManager? = null
    private var recorder: CallRecorder? = null

    private var activeRequestId = 0
    private var activeLeadId = 0
    private var activePhone = ""
    private var activeLeadName = ""
    private var dialedAtMs = 0L
    private var callStartedAtMs = 0L
    private var callSeenOffhook = false
    private var completing = false

    private val pollRunnable = object : Runnable {
        override fun run() {
            pollNow("timer")
            handler.postDelayed(this, POLL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences("crm_companion", Context.MODE_PRIVATE)
        recorder = CallRecorder(this)
        try { recorder?.ensureRecordingFolder() } catch (_: Exception) {}
        isRunning = true
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification("Waiting for CRM call button..."))
        registerPhoneStateListener()
        handler.removeCallbacks(pollRunnable)
        handler.post(pollRunnable)
        setLastMessage("Calling service started. Fast real-time polling active.")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopSelf()
                return START_NOT_STICKY
            }
            ACTION_CHECK_NOW -> pollNow("force")
            else -> pollNow("start")
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        try { telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE) } catch (_: Exception) {}
        try { recorder?.stop() } catch (_: Exception) {}
        executor.shutdownNow()
        isRunning = false
        setLastMessage("Calling service stopped")
        super.onDestroy()
    }

    private fun pollNow(reason: String) {
        if (!prefs.getBoolean("autoCallEnabled", true)) {
            setLastMessage("Auto-call is OFF")
            return
        }

        val crmUrl = prefs.getString("crmUrl", "") ?: ""
        val userId = prefs.getInt("userId", 0)
        val token = prefs.getString("token", "") ?: ""
        if (crmUrl.isBlank() || userId <= 0 || token.isBlank()) {
            setLastMessage("Waiting for valid mobile login/session")
            return
        }

        retryPendingRecordingUploads()

        if (activeRequestId > 0) {
            inspectActiveCallState()
            return
        }

        if (!polling.compareAndSet(false, true)) return
        executor.execute {
            try {
                val url = "$crmUrl/api/get-call-request.php?user_id=$userId&token=${urlEncode(token)}&_=${System.currentTimeMillis()}"
                val json = httpGet(url, token)
                if (!json.optBoolean("success", false)) {
                    setLastMessage(json.optString("message", "Waiting for web call button..."))
                    return@execute
                }
                val req = json.optJSONObject("request") ?: json.optJSONObject("data") ?: json
                val reqId = req.optInt("id", req.optInt("request_id", 0))
                val leadId = req.optInt("lead_id", 0)
                val phone = req.optString("phone", "")
                val leadName = req.optString("lead_name", "Lead")
                if (reqId <= 0 || phone.isBlank()) {
                    setLastMessage("Pending request missing id or phone")
                    return@execute
                }
                handlePendingRequest(reqId, leadId, phone, leadName)
            } catch (e: Exception) {
                val msg = e.message ?: e.toString()
                if (msg.contains("No pending", ignoreCase = true)) {
                    setLastMessage("Waiting for web call button...")
                } else {
                    setLastMessage("Poll failed: $msg")
                }
            } finally {
                polling.set(false)
            }
        }
    }

    private fun handlePendingRequest(reqId: Int, leadId: Int, phone: String, leadName: String) {
        if (activeRequestId > 0) return
        activeRequestId = reqId
        activeLeadId = leadId
        activePhone = phone
        activeLeadName = leadName
        dialedAtMs = System.currentTimeMillis()
        callStartedAtMs = 0L
        callSeenOffhook = false
        completing = false
        prefs.edit()
            .putInt("activeRequestId", reqId)
            .putString("activeLeadName", leadName)
            .putString("activePhone", phone)
            .apply()

        setLastMessage("Web request #$reqId received. Dialing $leadName")
        updateRequest(reqId, "picked", "Android app picked request", "", "")
        val launched = DirectCaller.call(this, phone, reqId)
        if (!launched) {
            savePendingFeedback(reqId, leadId, leadName, phone, "00:00:00", "Not Picked", "")
            completeActiveCall("failed", "Dialer launch failed", "00:00:00", "Not Picked")
            handler.postDelayed({ openAppForFeedback() }, 500L)
            return
        }

        handler.postDelayed({ inspectActiveCallState() }, 1200L)
    }

    private fun registerPhoneStateListener() {
        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        phoneStateListener = object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                super.onCallStateChanged(state, phoneNumber)
                if (activeRequestId <= 0) return
                when (state) {
                    TelephonyManager.CALL_STATE_OFFHOOK -> onCallOffhook()
                    TelephonyManager.CALL_STATE_IDLE -> {
                        // Some devices send IDLE immediately after dialer launch. The watchdog decides whether it is real end.
                        inspectActiveCallState(forceIdleEvent = true)
                    }
                    TelephonyManager.CALL_STATE_RINGING -> setLastMessage("Call ringing for request #$activeRequestId")
                }
            }
        }
        try {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
                telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
            } else {
                setLastMessage("READ_PHONE_STATE permission missing. Allow phone permission for recording completion.")
            }
        } catch (e: Exception) {
            setLastMessage("Phone state listener failed: ${e.message}")
        }
    }

    private fun inspectActiveCallState(forceIdleEvent: Boolean = false) {
        if (activeRequestId <= 0 || completing) return
        val now = System.currentTimeMillis()
        val waited = now - dialedAtMs
        val state = getCallStateSafe()

        if (state == TelephonyManager.CALL_STATE_OFFHOOK) {
            onCallOffhook()
            return
        }

        if (state == TelephonyManager.CALL_STATE_IDLE) {
            if (callSeenOffhook) {
                onCallIdle()
                return
            }
            // If call never reached OFFHOOK within timeout, reset it so next web click is never blocked.
            if (waited > NO_START_TIMEOUT_MS || forceIdleEvent && waited > 8000L) {
                try { recorder?.stop() } catch (_: Exception) {}
                savePendingFeedback(activeRequestId, activeLeadId, activeLeadName, activePhone, "00:00:00", "Not Picked", "")
                completeActiveCall("failed", "Call did not start or phone state was not detected", "00:00:00", "Not Picked")
                handler.postDelayed({ openAppForFeedback() }, 500L)
            }
            return
        }

        if (!callSeenOffhook && waited > NO_START_TIMEOUT_MS) {
            try { recorder?.stop() } catch (_: Exception) {}
            savePendingFeedback(activeRequestId, activeLeadId, activeLeadName, activePhone, "00:00:00", "Not Picked", "")
            completeActiveCall("failed", "Call timeout before connection", "00:00:00", "Not Picked")
            handler.postDelayed({ openAppForFeedback() }, 500L)
        }
    }

    private fun getCallStateSafe(): Int {
        return try {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
                @Suppress("DEPRECATION")
                telephonyManager?.callState ?: TelephonyManager.CALL_STATE_IDLE
            } else {
                TelephonyManager.CALL_STATE_IDLE
            }
        } catch (_: Exception) {
            TelephonyManager.CALL_STATE_IDLE
        }
    }

    private fun onCallOffhook() {
        if (activeRequestId <= 0 || completing) return
        if (callStartedAtMs <= 0L) {
            callStartedAtMs = System.currentTimeMillis()
            callSeenOffhook = true
            updateRequest(activeRequestId, "connected", "Call connected/offhook", "", "Connected")
            if (prefs.getBoolean("autoRecordingEnabled", true)) {
                recorder?.start(activeRequestId, activeLeadId)
            }
            setLastMessage("Call in progress for request #$activeRequestId")
        }
    }

    private fun onCallIdle() {
        if (activeRequestId <= 0 || completing) return
        if (!callSeenOffhook) {
            inspectActiveCallState(forceIdleEvent = true)
            return
        }
        completing = true
        val durationMs = (System.currentTimeMillis() - callStartedAtMs).coerceAtLeast(0L)
        val duration = formatDuration(durationMs)
        val reqId = activeRequestId
        val leadId = activeLeadId
        executor.execute {
            var recordingUrl = ""
            var localFile: File? = null
            try {
                localFile = recorder?.stop()
                if (localFile != null && prefs.getBoolean("autoRecordingEnabled", true)) {
                    recordingUrl = recorder?.uploadRecording(
                        prefs.getString("crmUrl", "") ?: "",
                        prefs.getInt("userId", 0),
                        prefs.getString("token", "") ?: "",
                        reqId,
                        leadId,
                        localFile!!,
                        duration
                    ) ?: ""
                    prefs.edit().putString("lastRecordingUrl", recordingUrl.ifBlank { "Uploaded, URL not returned" }).apply()
                } else {
                    prefs.edit().putString("lastRecordingUrl", "-").apply()
                }
            } catch (e: Exception) {
                val fileToRetry = localFile
                if (fileToRetry != null && fileToRetry.exists()) {
                    enqueuePendingRecordingUpload(reqId, leadId, fileToRetry.absolutePath, duration, e.message ?: e.toString())
                    prefs.edit().putString("lastRecordingUrl", "Upload pending retry").apply()
                    setLastMessage("Recording upload failed. Saved locally and queued for retry: ${e.message}")
                } else {
                    setLastMessage("Recording upload failed: ${e.message}")
                }
            } finally {
                savePendingFeedback(reqId, leadId, activeLeadName, activePhone, duration, "Connected", recordingUrl)
                completeActiveCall("completed", "Mobile call completed${if (recordingUrl.isNotBlank()) " with recording" else ""}", duration, "Connected")
                handler.postDelayed({ openAppForFeedback() }, 500L)
            }
        }
    }

    private fun completeActiveCall(status: String, message: String, duration: String, callStatus: String) {
        val reqId = activeRequestId
        if (reqId <= 0) return
        updateRequest(reqId, status, message, duration, callStatus)
        setLastMessage("Request #$reqId $status. Duration: $duration")
        activeRequestId = 0
        activeLeadId = 0
        activePhone = ""
        activeLeadName = ""
        dialedAtMs = 0L
        callStartedAtMs = 0L
        callSeenOffhook = false
        completing = false
        prefs.edit()
            .remove("activeRequestId")
            .remove("activeLeadName")
            .remove("activePhone")
            .apply()
        handler.postDelayed({ pollNow("after_complete") }, 400L)
    }

    private fun savePendingFeedback(
        requestId: Int,
        leadId: Int,
        leadName: String,
        phone: String,
        duration: String,
        callStatus: String,
        recordingUrl: String
    ) {
        val eventId = "${requestId}-${System.currentTimeMillis()}"
        val autoNotes = buildString {
            if (callStatus.equals("Connected", ignoreCase = true)) {
                append("Call completed from mobile app.")
            } else {
                append("Call not connected / not picked from mobile app.")
            }
            if (leadName.isNotBlank()) append("\nLead: ").append(leadName)
            if (phone.isNotBlank()) append("\nPhone: ").append(phone)
            append("\nDuration: ").append(duration)
            if (recordingUrl.isNotBlank()) append("\nRecording: ").append(recordingUrl)
            append("\n\nDiscussion notes: ")
        }
        prefs.edit()
            .putBoolean("pendingFeedback", true)
            .putString("pendingFeedbackEventId", eventId)
            .putInt("pendingFeedbackRequestId", requestId)
            .putInt("pendingFeedbackLeadId", leadId)
            .putString("pendingFeedbackLeadName", leadName)
            .putString("pendingFeedbackPhone", phone)
            .putString("pendingFeedbackDuration", duration)
            .putString("pendingFeedbackCallStatus", callStatus)
            .putString("pendingFeedbackRecordingUrl", recordingUrl)
            .putString("pendingFeedbackNotes", autoNotes)
            .putLong("pendingFeedbackCreatedAt", System.currentTimeMillis())
            .apply()
    }

    private fun openAppForFeedback() {
        try {
            val intent = packageManager.getLaunchIntentForPackage(packageName) ?: return
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            intent.putExtra("open_feedback", true)
            startActivity(intent)
            setLastMessage("Call ended. Feedback form opened.")
        } catch (e: Exception) {
            setLastMessage("Call ended. Open app Feedback tab. ${e.message ?: ""}")
        }
    }


    private fun enqueuePendingRecordingUpload(requestId: Int, leadId: Int, filePath: String, duration: String, error: String) {
        try {
            val queue = JSONArray(prefs.getString("pendingRecordingUploads", "[]") ?: "[]")
            val item = JSONObject().apply {
                put("request_id", requestId)
                put("lead_id", leadId)
                put("file_path", filePath)
                put("duration", duration)
                put("attempts", 0)
                put("last_error", error)
                put("created_at", System.currentTimeMillis())
            }
            queue.put(item)
            prefs.edit()
                .putString("pendingRecordingUploads", queue.toString())
                .putInt("pendingRecordingUploadCount", queue.length())
                .apply()
        } catch (_: Exception) {}
    }

    private fun retryPendingRecordingUploads() {
        if (!uploadRetrying.compareAndSet(false, true)) return
        executor.execute {
            try {
                val raw = prefs.getString("pendingRecordingUploads", "[]") ?: "[]"
                val queue = JSONArray(raw)
                if (queue.length() == 0) return@execute
                val crmUrl = prefs.getString("crmUrl", "") ?: ""
                val userId = prefs.getInt("userId", 0)
                val token = prefs.getString("token", "") ?: ""
                if (crmUrl.isBlank() || userId <= 0 || token.isBlank()) return@execute

                val remaining = JSONArray()
                for (i in 0 until queue.length()) {
                    val item = queue.optJSONObject(i) ?: continue
                    val requestId = item.optInt("request_id", 0)
                    val leadId = item.optInt("lead_id", 0)
                    val filePath = item.optString("file_path", "")
                    val duration = item.optString("duration", "")
                    val file = File(filePath)
                    if (requestId <= 0 || leadId <= 0 || !file.exists() || file.length() <= 64) continue
                    try {
                        val uploadedUrl = recorder?.uploadRecording(crmUrl, userId, token, requestId, leadId, file, duration) ?: ""
                        prefs.edit().putString("lastRecordingUrl", uploadedUrl.ifBlank { "Uploaded on retry" }).apply()
                        setLastMessage("Pending recording uploaded for request #$requestId")
                    } catch (e: Exception) {
                        item.put("attempts", item.optInt("attempts", 0) + 1)
                        item.put("last_error", e.message ?: e.toString())
                        item.put("last_attempt_at", System.currentTimeMillis())
                        remaining.put(item)
                    }
                }
                prefs.edit()
                    .putString("pendingRecordingUploads", remaining.toString())
                    .putInt("pendingRecordingUploadCount", remaining.length())
                    .apply()
            } catch (e: Exception) {
                setLastMessage("Recording retry failed: ${e.message}")
            } finally {
                uploadRetrying.set(false)
            }
        }
    }

    private fun updateRequest(requestId: Int, status: String, message: String, duration: String, callStatus: String) {
        try {
            val crmUrl = prefs.getString("crmUrl", "") ?: return
            val token = prefs.getString("token", "") ?: return
            val userId = prefs.getInt("userId", 0)
            val body = JSONObject().apply {
                put("user_id", userId)
                put("token", token)
                put("request_id", requestId)
                put("status", status)
                put("message", message)
                if (duration.isNotBlank()) put("duration", duration)
                if (callStatus.isNotBlank()) put("call_status", callStatus)
            }.toString()
            httpPostJson("$crmUrl/api/update-call-request.php", body, token)
        } catch (e: Exception) {
            setLastMessage("Update request failed: ${e.message}")
        }
    }

    private fun httpGet(url: String, token: String): JSONObject {
        val conn = (URL(url).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 3500
            readTimeout = 4500
            setRequestProperty("Accept", "application/json")
            setRequestProperty("Cache-Control", "no-cache")
            setRequestProperty("X-Mobile-Token", token)
        }
        val text = readResponse(conn)
        if (conn.responseCode !in 200..299) throw Exception("HTTP ${conn.responseCode}: $text")
        return JSONObject(text)
    }

    private fun httpPostJson(url: String, jsonBody: String, token: String): JSONObject {
        val conn = (URL(url).openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 3500
            readTimeout = 4500
            doOutput = true
            setRequestProperty("Accept", "application/json")
            setRequestProperty("Content-Type", "application/json")
            setRequestProperty("X-Mobile-Token", token)
        }
        OutputStreamWriter(conn.outputStream).use { it.write(jsonBody) }
        val text = readResponse(conn)
        if (conn.responseCode !in 200..299) throw Exception("HTTP ${conn.responseCode}: $text")
        return JSONObject(text)
    }

    private fun readResponse(conn: HttpURLConnection): String {
        val stream = if (conn.responseCode in 200..299) conn.inputStream else conn.errorStream
        return if (stream != null) BufferedReader(stream.reader()).use { it.readText() } else ""
    }

    private fun urlEncode(value: String) = URLEncoder.encode(value, "UTF-8")

    private fun formatDuration(ms: Long): String {
        val total = (ms / 1000L).toInt()
        val h = total / 3600
        val m = (total % 3600) / 60
        val s = total % 60
        return "%02d:%02d:%02d".format(h, m, s)
    }

    private fun setLastMessage(message: String) {
        prefs.edit().putString("lastMessage", message).apply()
        updateNotification(message)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "CRM Calling Service", NotificationManager.IMPORTANCE_LOW)
            channel.description = "Keeps Click Connect CRM web call sync active"
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private fun buildNotification(message: String): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(this, 0, launchIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Click Connect CRM Calling Active")
            .setContentText(message)
            .setSmallIcon(android.R.drawable.sym_action_call)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(message: String) {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(NOTIFICATION_ID, buildNotification(message))
        } catch (_: Exception) {}
    }

    companion object {
        private const val CHANNEL_ID = "crm_calling_service"
        private const val NOTIFICATION_ID = 101
        private const val POLL_MS = 350L
        private const val NO_START_TIMEOUT_MS = 9000L
        private const val ACTION_START = "com.clickconnect.crm_companion.START"
        private const val ACTION_CHECK_NOW = "com.clickconnect.crm_companion.CHECK_NOW"
        private const val ACTION_STOP = "com.clickconnect.crm_companion.STOP"
        @Volatile var isRunning: Boolean = false

        fun start(context: Context, checkNow: Boolean = false) {
            val intent = Intent(context, CallPollingService::class.java).apply { action = if (checkNow) ACTION_CHECK_NOW else ACTION_START }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) context.startForegroundService(intent) else context.startService(intent)
        }

        fun stop(context: Context) {
            context.startService(Intent(context, CallPollingService::class.java).apply { action = ACTION_STOP })
        }
    }
}
