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
                "lastRecordingFolder" -> result.success(prefs.getString("recordingFolderPath", "Music/ClickConnectCRM/CallRecordings") ?: "Music/ClickConnectCRM/CallRecordings")
                "ensureRecordingFolder" -> {
                    result.success(CallRecorder(this).ensureVisibleRecordingFolder())
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
                "setSpeakerCaptureMode" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    prefs.edit().putBoolean("speakerCaptureMode", enabled).apply()
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
    private fun readPendingFeedback(): Map<String, Any>? {
        // Mobile feedback removed. Web CRM owns post-call feedback.
        return null
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
        editor.putBoolean("speakerCaptureMode", args["speakerCaptureMode"] as? Boolean ?: prefs.getBoolean("speakerCaptureMode", true))
        val pollingSeconds = ((args["pollingSeconds"] as? Number)?.toInt() ?: 1).coerceIn(1, 10)
        editor.putInt("pollingSeconds", pollingSeconds)
        editor.putInt("maxRecordingMinutes", ((args["maxRecordingMinutes"] as? Number)?.toInt() ?: 30).coerceIn(1, 120))
        editor.apply()
        CallRecorder(this).ensureVisibleRecordingFolder()
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
        if (Build.VERSION.SDK_INT <= Build.VERSION_CODES.P) {
            permissions.add(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            permissions.add(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
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
