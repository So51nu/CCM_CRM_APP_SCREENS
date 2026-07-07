package com.example.android_companion_app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.clickconnect.crm_companion/call"
    private var permissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestRequiredPermissions" -> requestRequiredPermissions(result)
                "saveSession" -> {
                    saveSession(call.arguments as? Map<*, *> ?: emptyMap<Any, Any>())
                    val start = call.argument<Boolean>("startService") ?: false
                    if (start) startCallService()
                    result.success(true)
                }
                "clearSession" -> {
                    getSharedPreferences("companion_prefs", Context.MODE_PRIVATE).edit().clear().apply()
                    result.success(true)
                }
                "startService" -> result.success(startCallService())
                "stopService" -> {
                    stopService(Intent(this, CallPollingService::class.java))
                    CallPollingService.isRunning = false
                    result.success(true)
                }
                "isServiceRunning" -> result.success(CallPollingService.isRunning)
                "lastMessage" -> result.success(
                    getSharedPreferences("companion_prefs", Context.MODE_PRIVATE)
                        .getString("last_message", "-")
                )
                "lastRecordingPath" -> result.success(
                    getSharedPreferences("companion_prefs", Context.MODE_PRIVATE)
                        .getString("last_recording_path", "-")
                )
                "lastRecordingUrl" -> result.success(
                    getSharedPreferences("companion_prefs", Context.MODE_PRIVATE)
                        .getString("last_recording_url", "-")
                )
                "setAutoCallEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    getSharedPreferences("companion_prefs", Context.MODE_PRIVATE).edit()
                        .putBoolean("auto_call_enabled", enabled)
                        .apply()
                    result.success(true)
                }
                "setAutoRecordingEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: true
                    getSharedPreferences("companion_prefs", Context.MODE_PRIVATE).edit()
                        .putBoolean("auto_recording_enabled", enabled)
                        .apply()
                    result.success(true)
                }
                "callNow" -> {
                    val phone = call.argument<String>("phone") ?: ""
                    val requestId = call.argument<Int>("requestId") ?: 0
                    result.success(DirectCaller.makeCall(this, phone, requestId))
                }
                "openBatterySettings" -> {
                    openBatterySettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveSession(args: Map<*, *>) {
        val prefs = getSharedPreferences("companion_prefs", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("crm_url", (args["crmUrl"] ?: "").toString().trimEnd('/'))
            .putInt("user_id", (args["userId"] as? Int) ?: args["userId"].toString().toIntOrNull() ?: 0)
            .putString("mobile_token", (args["token"] ?: "").toString())
            .putString("user_name", (args["userName"] ?: "").toString())
            .putString("user_email", (args["userEmail"] ?: "").toString())
            .putBoolean("auto_call_enabled", args["autoCallEnabled"] as? Boolean ?: true)
            .putBoolean("auto_recording_enabled", args["autoRecordingEnabled"] as? Boolean ?: true)
            .putInt("polling_seconds", (args["pollingSeconds"] as? Int) ?: 3)
            .putInt("max_recording_minutes", (args["maxRecordingMinutes"] as? Int) ?: 30)
            .apply()
    }

    private fun hasPermission(permission: String): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestRequiredPermissions(result: MethodChannel.Result) {
        val permissions = mutableListOf<String>()
        if (!hasPermission(Manifest.permission.CALL_PHONE)) permissions.add(Manifest.permission.CALL_PHONE)
        if (!hasPermission(Manifest.permission.RECORD_AUDIO)) permissions.add(Manifest.permission.RECORD_AUDIO)
        if (!hasPermission(Manifest.permission.READ_PHONE_STATE)) permissions.add(Manifest.permission.READ_PHONE_STATE)
        if (Build.VERSION.SDK_INT >= 33 && !hasPermission(Manifest.permission.POST_NOTIFICATIONS)) {
            permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        if (permissions.isEmpty()) {
            result.success(true)
            return
        }
        permissionResult = result
        requestPermissions(permissions.toTypedArray(), 9101)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 9101) {
            val granted = hasPermission(Manifest.permission.CALL_PHONE) &&
                    hasPermission(Manifest.permission.RECORD_AUDIO) &&
                    hasPermission(Manifest.permission.READ_PHONE_STATE)
            permissionResult?.success(granted)
            permissionResult = null
        }
    }

    private fun startCallService(): Boolean {
        val prefs = getSharedPreferences("companion_prefs", Context.MODE_PRIVATE)
        val crmUrl = prefs.getString("crm_url", "") ?: ""
        val token = prefs.getString("mobile_token", "") ?: ""
        val userId = prefs.getInt("user_id", 0)
        if (crmUrl.isBlank() || token.isBlank() || userId <= 0) return false

        val intent = Intent(this, CallPollingService::class.java)
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
            true
        } catch (e: Exception) {
            prefs.edit().putString("last_message", "Service start failed: ${e.message}").apply()
            false
        }
    }

    private fun openBatterySettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            intent.data = Uri.parse("package:$packageName")
            startActivity(intent)
        } catch (_: Exception) {}
    }
}
