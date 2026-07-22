package com.example.android_companion_app

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.ContextCompat

object DirectCaller {
    fun call(context: Context, rawPhone: String, requestId: Int = 0): Boolean {
        val phone = cleanPhone(rawPhone)
        if (phone.isBlank()) return false
        val prefs = context.getSharedPreferences("crm_companion", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("lastMessage", "Dialing $phone from request #$requestId")
            .putString("lastDialedPhone", phone)
            .putInt("lastDialedRequestId", requestId)
            .apply()

        val canDirectCall = ContextCompat.checkSelfPermission(context, Manifest.permission.CALL_PHONE) == PackageManager.PERMISSION_GRANTED
        val action = if (canDirectCall) Intent.ACTION_CALL else Intent.ACTION_DIAL
        val intent = Intent(action, Uri.parse("tel:$phone")).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            prefs.edit().putString("lastMessage", "Call failed: ${e.message}").apply()
            false
        }
    }

    fun cleanPhone(value: String): String {
        var phone = value.trim().replace(" ", "").replace("-", "").replace("(", "").replace(")", "")
        phone = phone.replace(Regex("[^0-9+]"), "")
        if (phone.startsWith("00")) phone = "+" + phone.drop(2)
        if (phone.startsWith("+")) return phone
        if (phone.length == 10) return "+91$phone"
        if (phone.startsWith("91") && phone.length == 12) return "+$phone"
        if (phone.startsWith("971") && phone.length in 11..12) return "+$phone"
        if (phone.length > 10) return "+$phone"
        return phone
    }
}
