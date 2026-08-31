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
import android.media.AudioManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.io.BufferedReader
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URLEncoder
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import org.json.JSONObject

class CallPollingService : Service() {
    private lateinit var prefs: SharedPreferences
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private val polling = AtomicBoolean(false)
    private var phoneStateListener: PhoneStateListener? = null
    private var telephonyManager: TelephonyManager? = null
    private var recorder: CallRecorder? = null
    private var audioManager: AudioManager? = null
    private var speakerModeApplied = false
    private var originalSpeakerphone = false
    private var originalAudioMode = AudioManager.MODE_NORMAL

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
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
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
        restoreSpeakerCaptureMode()
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

        retryPendingRecordingUpload()

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

    @Suppress("DEPRECATION")
    private fun enableSpeakerCaptureMode() {
        if (!prefs.getBoolean("speakerCaptureMode", true) || speakerModeApplied) return
        try {
            val audio = audioManager ?: return
            originalSpeakerphone = audio.isSpeakerphoneOn
            originalAudioMode = audio.mode
            // This does not bypass Android call-recording restrictions. It only makes the far-end
            // voice audible from loudspeaker so the microphone source has a chance to capture it.
            audio.mode = AudioManager.MODE_IN_CALL
            audio.isSpeakerphoneOn = true
            speakerModeApplied = true
            prefs.edit()
                .putBoolean("speakerCaptureModeApplied", true)
                .putString("lastMessage", "Speaker Capture mode ON: call audio may record through microphone.")
                .apply()
        } catch (e: Exception) {
            prefs.edit().putString("lastMessage", "Speaker Capture mode failed: ${e.message}").apply()
        }
    }

    @Suppress("DEPRECATION")
    private fun restoreSpeakerCaptureMode() {
        if (!speakerModeApplied) return
        try {
            val audio = audioManager ?: return
            audio.isSpeakerphoneOn = originalSpeakerphone
            audio.mode = originalAudioMode
        } catch (_: Exception) {
        } finally {
            speakerModeApplied = false
            prefs.edit().remove("speakerCaptureModeApplied").apply()
        }
    }

    private fun onCallOffhook() {
        if (activeRequestId <= 0 || completing) return
        if (callStartedAtMs <= 0L) {
            callStartedAtMs = System.currentTimeMillis()
            callSeenOffhook = true
            updateRequest(activeRequestId, "connected", "Receiver picked / call connected", "", "Connected")
            if (prefs.getBoolean("autoRecordingEnabled", true)) {
                enableSpeakerCaptureMode()
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
            var recordingNote = ""
            try {
                val result = recorder?.stop()
                if (result != null && prefs.getBoolean("autoRecordingEnabled", true)) {
                    recordingNote = result.message
                    if (result.isValid && result.uploadFile != null) {
                        try {
                            recordingUrl = recorder?.uploadRecording(
                                prefs.getString("crmUrl", "") ?: "",
                                prefs.getInt("userId", 0),
                                prefs.getString("token", "") ?: "",
                                reqId,
                                leadId,
                                result.uploadFile,
                                duration,
                                result.publicPath,
                                result.publicUri,
                                result.maxAmplitude
                            ) ?: ""
                            prefs.edit().putString("lastRecordingUrl", recordingUrl.ifBlank { "Uploaded, URL not returned" }).apply()
                        } catch (uploadError: Exception) {
                            savePendingRecordingUpload(reqId, leadId, result.uploadFile.absolutePath, duration, result.publicPath, result.publicUri)
                            prefs.edit().putString("lastRecordingUrl", "Upload pending: ${uploadError.message}").apply()
                            recordingNote = "${result.message}\nUpload pending: ${uploadError.message}"
                        }
                    } else {
                        prefs.edit().putString("lastRecordingUrl", "Recording not uploaded: ${result?.message ?: "No valid audio file"}").apply()
                    }
                } else {
                    prefs.edit().putString("lastRecordingUrl", "-").apply()
                }
            } catch (e: Exception) {
                setLastMessage("Recording save/upload failed: ${e.message}")
                recordingNote = "Recording save/upload failed: ${e.message}"
            } finally {
                restoreSpeakerCaptureMode()
                savePendingFeedback(reqId, leadId, activeLeadName, activePhone, duration, "Connected", recordingUrl, recordingNote)
                completeActiveCall("completed", "Mobile call completed${if (recordingUrl.isNotBlank()) " with recording" else ""}", duration, "Connected")
                handler.postDelayed({ openAppForFeedback() }, 500L)
            }
        }
    }

    private fun completeActiveCall(status: String, message: String, duration: String, callStatus: String) {
        val reqId = activeRequestId
        if (reqId <= 0) return
        updateRequest(reqId, status, message, duration, callStatus)
        restoreSpeakerCaptureMode()
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

    private fun savePendingRecordingUpload(requestId: Int, leadId: Int, filePath: String, duration: String, publicPath: String, publicUri: String) {
        prefs.edit()
            .putBoolean("pendingRecordingUpload", true)
            .putInt("pendingRecordingRequestId", requestId)
            .putInt("pendingRecordingLeadId", leadId)
            .putString("pendingRecordingFilePath", filePath)
            .putString("pendingRecordingDuration", duration)
            .putString("pendingRecordingPublicPath", publicPath)
            .putString("pendingRecordingPublicUri", publicUri)
            .putLong("pendingRecordingCreatedAt", System.currentTimeMillis())
            .apply()
    }

    private fun clearPendingRecordingUpload() {
        prefs.edit()
            .remove("pendingRecordingUpload")
            .remove("pendingRecordingRequestId")
            .remove("pendingRecordingLeadId")
            .remove("pendingRecordingFilePath")
            .remove("pendingRecordingDuration")
            .remove("pendingRecordingPublicPath")
            .remove("pendingRecordingPublicUri")
            .remove("pendingRecordingCreatedAt")
            .apply()
    }

    private fun retryPendingRecordingUpload() {
        if (!prefs.getBoolean("pendingRecordingUpload", false)) return
        if (!polling.compareAndSet(false, true)) return
        executor.execute {
            try {
                val filePath = prefs.getString("pendingRecordingFilePath", "") ?: ""
                val file = java.io.File(filePath)
                if (!file.exists() || file.length() < 1024L) {
                    setLastMessage("Pending recording missing/empty, retry cancelled")
                    clearPendingRecordingUpload()
                    return@execute
                }
                val reqId = prefs.getInt("pendingRecordingRequestId", 0)
                val leadId = prefs.getInt("pendingRecordingLeadId", 0)
                val duration = prefs.getString("pendingRecordingDuration", "") ?: ""
                val publicPath = prefs.getString("pendingRecordingPublicPath", "") ?: ""
                val publicUri = prefs.getString("pendingRecordingPublicUri", "") ?: ""
                val url = recorder?.uploadRecording(
                    prefs.getString("crmUrl", "") ?: "",
                    prefs.getInt("userId", 0),
                    prefs.getString("token", "") ?: "",
                    reqId,
                    leadId,
                    file,
                    duration,
                    publicPath,
                    publicUri,
                    prefs.getInt("lastRecordingMaxAmplitude", 0)
                ) ?: ""
                prefs.edit().putString("lastRecordingUrl", url.ifBlank { "Uploaded" }).apply()
                clearPendingRecordingUpload()
                setLastMessage("Pending recording uploaded to CRM")
            } catch (e: Exception) {
                setLastMessage("Pending recording upload retry failed: ${e.message}")
            } finally {
                polling.set(false)
            }
        }
    }
    private fun savePendingFeedback(
        requestId: Int,
        leadId: Int,
        leadName: String,
        phone: String,
        duration: String,
        callStatus: String,
        recordingUrl: String,
        recordingNote: String = ""
    ) {
        // Mobile feedback workflow removed. The backend marks web feedback pending after updateRequest().
        clearPendingFeedbackPrefs()
    }

    private fun openAppForFeedback() {
        // Do not launch Flutter feedback screen. Web CRM will auto-open feedback form.
        setLastMessage("Call ended. Feedback pending on Web CRM.")
    }

    private fun clearPendingFeedbackPrefs() {
        prefs.edit()
            .remove("pendingFeedback")
            .remove("pendingFeedbackEventId")
            .remove("pendingFeedbackRequestId")
            .remove("pendingFeedbackLeadId")
            .remove("pendingFeedbackLeadName")
            .remove("pendingFeedbackPhone")
            .remove("pendingFeedbackDuration")
            .remove("pendingFeedbackCallStatus")
            .remove("pendingFeedbackRecordingUrl")
            .remove("pendingFeedbackNotes")
            .remove("pendingFeedbackCreatedAt")
            .apply()
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
