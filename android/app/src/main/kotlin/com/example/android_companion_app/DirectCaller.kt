package com.example.android_companion_app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build

object DirectCaller {

    fun cleanPhone(phone: String): String {
        val raw = phone.trim()
        if (raw.isBlank()) return ""

        var cleaned = raw.replace(Regex("[^0-9+]"), "")

        if (!cleaned.startsWith("+") && cleaned.length == 10) {
            cleaned = "+91$cleaned"
        }

        if (!cleaned.startsWith("+") && cleaned.length == 12 && cleaned.startsWith("91")) {
            cleaned = "+$cleaned"
        }

        return cleaned
    }

    fun makeCall(context: Context, phone: String, requestId: Int = 0): Boolean {
        val cleaned = cleanPhone(phone)

        if (cleaned.isBlank()) {
            saveLastMessage(context, "Phone number blank/invalid")
            return false
        }

        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            context.checkSelfPermission(Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED
        ) {
            saveLastMessage(context, "Phone permission not allowed")
            return false
        }

        return try {
            val intent = Intent(Intent.ACTION_CALL)
            intent.data = Uri.parse("tel:$cleaned")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.putExtra("crm_request_id", requestId)

            context.startActivity(intent)

            saveLastMessage(context, "Calling $cleaned")
            true
        } catch (e: Exception) {
            saveLastMessage(context, "Call blocked/failed: ${e.message ?: "Unknown error"}")
            false
        }
    }

    private fun saveLastMessage(context: Context, message: String) {
        val prefs = context.getSharedPreferences("companion_prefs", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        editor.putString("last_message", message)
        editor.commit()
    }
}
