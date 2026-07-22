package com.example.android_companion_app

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.clickconnect.crm_companion/call"
    private lateinit var prefs: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        prefs = getSharedPreferences("crm_companion", Context.MODE_PRIVATE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        prefs = getSharedPreferences("crm_companion", Context.MODE_PRIVATE)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestRequiredPermissions" -> {
                    requestRequiredPermissions()
                    result.success(hasCorePermissions())
                }
                "saveSession" -> {
                    val args = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
                    saveSession(args)
                    val startService = args["startService"] as? Boolean ?: false
                    if (startService) CallPollingService.start(this, checkNow = true)
                    result.success(true)
                }
                "startService" -> {
                    CallPollingService.start(this, checkNow = true)
                    result.success(true)
                }
                "stopService" -> {
                    CallPollingService.stop(this)
                    result.success(true)
                }
                "isServiceRunning" -> result.success(CallPollingService.isRunning)
                "lastMessage" -> result.success(prefs.getString("lastMessage", "-") ?: "-")
                "lastRecordingPath" -> result.success(prefs.getString("lastRecordingPath", "-") ?: "-")
                "lastRecordingUrl" -> result.success(prefs.getString("lastRecordingUrl", "-") ?: "-")
                "recordingFolderPath" -> result.success(prefs.getString("recordingFolderPath", "-") ?: "-")
                "ensureRecordingFolder" -> {
                    val folder = CallRecorder(this).ensureRecordingFolder()
                    result.success(folder.absolutePath)
                }
                "setAutoCallEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    prefs.edit().putBoolean("autoCallEnabled", enabled).putBoolean("auto_call_enabled", enabled).apply()
                    if (enabled) CallPollingService.start(this, checkNow = true)
                    result.success(true)
                }
                "setAutoRecordingEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    prefs.edit().putBoolean("autoRecordingEnabled", enabled).putBoolean("auto_recording_enabled", enabled).apply()
                    result.success(true)
                }
                "clearSession" -> {
                    CallPollingService.stop(this)
                    prefs.edit()
                        .remove("crmUrl")
                        .remove("userId")
                        .remove("token")
                        .remove("userName")
                        .remove("userEmail")
                        .remove("activeRequestId")
                        .apply()
                    result.success(true)
                }
                "callNow" -> {
                    val phone = call.argument<String>("phone") ?: ""
                    val requestId = call.argument<Int>("requestId") ?: 0
                    if (phone.isBlank()) {
                        result.error("PHONE_REQUIRED", "Phone number is required", null)
                    } else {
                        DirectCaller.call(this, phone, requestId)
                        result.success(true)
                    }
                }
                "checkNow" -> {
                    CallPollingService.start(this, checkNow = true)
                    result.success(true)
                }
                "pendingFeedback" -> {
                    result.success(readPendingFeedback())
                }
                "clearPendingFeedback" -> {
                    clearPendingFeedback()
                    result.success(true)
                }
                "openBatterySettings" -> {
                    openBatterySettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }



    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 501) {
            if (hasCorePermissions()) {
                try { CallRecorder(this).ensureRecordingFolder() } catch (_: Exception) {}
                val token = prefs.getString("token", "") ?: ""
                if (token.isNotBlank()) CallPollingService.start(this, checkNow = true)
                prefs.edit().putString("lastMessage", "Permissions allowed. Calling and recording service ready.").apply()
            } else {
                prefs.edit().putString("lastMessage", "Phone, Microphone and Phone State permissions are required for calling and recording.").apply()
            }
        }
    }

    private fun readPendingFeedback(): Map<String, Any>? {
        if (!prefs.getBoolean("pendingFeedback", false)) return null
        val requestId = prefs.getInt("pendingFeedbackRequestId", 0)
        if (requestId <= 0) return null
        return mapOf(
            "event_id" to (prefs.getString("pendingFeedbackEventId", "") ?: ""),
            "request_id" to requestId,
            "lead_id" to prefs.getInt("pendingFeedbackLeadId", 0),
            "lead_name" to (prefs.getString("pendingFeedbackLeadName", "") ?: ""),
            "phone" to (prefs.getString("pendingFeedbackPhone", "") ?: ""),
            "duration" to (prefs.getString("pendingFeedbackDuration", "00:00:00") ?: "00:00:00"),
            "call_status" to (prefs.getString("pendingFeedbackCallStatus", "Connected") ?: "Connected"),
            "recording_url" to (prefs.getString("pendingFeedbackRecordingUrl", "") ?: ""),
            "recording_path" to (prefs.getString("lastRecordingPath", "") ?: ""),
            "recording_folder_path" to (prefs.getString("recordingFolderPath", "") ?: ""),
            "notes" to (prefs.getString("pendingFeedbackNotes", "") ?: ""),
            "created_at" to prefs.getLong("pendingFeedbackCreatedAt", 0L)
        )
    }

    private fun clearPendingFeedback() {
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

    private fun saveSession(args: Map<*, *>) {
        val editor = prefs.edit()
        editor.putString("crmUrl", normalizeBaseUrl(args["crmUrl"]?.toString() ?: ""))
        editor.putInt("userId", (args["userId"] as? Number)?.toInt() ?: args["userId"]?.toString()?.toIntOrNull() ?: 0)
        editor.putString("token", args["token"]?.toString() ?: "")
        editor.putString("userName", args["userName"]?.toString() ?: "")
        editor.putString("userEmail", args["userEmail"]?.toString() ?: "")
        val autoCall = args["autoCallEnabled"] as? Boolean ?: true
        val autoRecording = args["autoRecordingEnabled"] as? Boolean ?: true
        editor.putBoolean("autoCallEnabled", autoCall)
        editor.putBoolean("auto_call_enabled", autoCall)
        editor.putBoolean("autoRecordingEnabled", autoRecording)
        editor.putBoolean("auto_recording_enabled", autoRecording)
        val pollingSeconds = ((args["pollingSeconds"] as? Number)?.toInt() ?: 1).coerceIn(1, 10)
        editor.putInt("pollingSeconds", pollingSeconds)
        editor.putInt("maxRecordingMinutes", ((args["maxRecordingMinutes"] as? Number)?.toInt() ?: 30).coerceIn(1, 120))
        editor.apply()
        try { CallRecorder(this).ensureRecordingFolder() } catch (_: Exception) {}
    }

    private fun normalizeBaseUrl(url: String): String {
        var cleaned = url.trim()
        while (cleaned.endsWith("/")) cleaned = cleaned.dropLast(1)
        return cleaned
    }

    private fun hasCorePermissions(): Boolean {
        val call = ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED
        val mic = ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        val state = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
        return call && mic && state
    }

    private fun requestRequiredPermissions() {
        val permissions = mutableListOf(
            Manifest.permission.CALL_PHONE,
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.RECORD_AUDIO
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        val missing = permissions.filter { ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED }
        if (missing.isNotEmpty()) ActivityCompat.requestPermissions(this as Activity, missing.toTypedArray(), 501)
    }

    private fun openBatterySettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.parse("package:$packageName")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            } catch (_: Exception) {}
        }
    }
}
