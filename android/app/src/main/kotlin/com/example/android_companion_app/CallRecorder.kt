package com.example.android_companion_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.MediaRecorder
import android.os.Build
import android.os.Environment
import org.json.JSONObject
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.BufferedReader
import java.io.File
import java.io.FileInputStream
import java.io.OutputStreamWriter
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object CallRecorder {
    @Volatile var isRecording: Boolean = false
        private set

    private var recorder: MediaRecorder? = null
    private var startedAtMs: Long = 0L
    private var activeFile: File? = null
    private var activeRequestId: Int = 0
    private var activeLeadId: Int = 0
    private var activeLeadName: String = "Lead"

    data class UploadResult(
        val success: Boolean,
        val message: String,
        val fileUrl: String = "",
        val duration: String = "-",
        val localPath: String = ""
    )

    fun hasRequiredPermission(context: Context): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                context.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
    }

    fun preparePending(
        context: Context,
        crmUrl: String,
        token: String,
        userId: Int,
        requestId: Int,
        leadId: Int,
        leadName: String,
        phone: String
    ) {
        prefs(context).edit()
            .putString("active_crm_url", crmUrl.trimEnd('/'))
            .putString("active_token", token)
            .putInt("active_user_id", userId)
            .putInt("active_request_id", requestId)
            .putInt("active_lead_id", leadId)
            .putString("active_lead_name", leadName)
            .putString("active_phone", phone)
            .putBoolean("active_call_offhook", false)
            .putBoolean("active_call_completed", false)
            .apply()
    }

    fun start(context: Context): Boolean {
        val p = prefs(context)
        val requestId = p.getInt("active_request_id", 0)
        val leadId = p.getInt("active_lead_id", 0)
        val leadName = p.getString("active_lead_name", "Lead") ?: "Lead"

        if (requestId <= 0 || leadId <= 0) {
            saveLast(context, "Recording not started: missing active request")
            return false
        }

        return start(context, requestId, leadId, leadName)
    }

    fun start(context: Context, requestId: Int, leadId: Int, leadName: String): Boolean {
        if (isRecording) return true

        if (!hasRequiredPermission(context)) {
            saveLast(context, "Recording permission not allowed")
            return false
        }

        return try {
            val dir = context.getExternalFilesDir(Environment.DIRECTORY_MUSIC)
                ?: File(context.filesDir, "recordings")
            if (!dir.exists()) dir.mkdirs()

            val stamp = SimpleDateFormat("yyyyMMdd-HHmmss", Locale.US).format(Date())
            val file = File(dir, "crm-call-req-$requestId-$stamp.m4a")

            val mr = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                MediaRecorder(context)
            } else {
                @Suppress("DEPRECATION")
                MediaRecorder()
            }

            @Suppress("DEPRECATION")
            mr.setAudioSource(MediaRecorder.AudioSource.MIC)
            mr.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            mr.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            mr.setAudioEncodingBitRate(128000)
            mr.setAudioSamplingRate(44100)
            mr.setOutputFile(file.absolutePath)
            mr.prepare()
            mr.start()

            recorder = mr
            activeFile = file
            startedAtMs = System.currentTimeMillis()
            activeRequestId = requestId
            activeLeadId = leadId
            activeLeadName = leadName
            isRecording = true

            prefs(context).edit()
                .putString("active_recording_path", file.absolutePath)
                .putLong("active_recording_started_ms", startedAtMs)
                .putString("last_recording_path", file.absolutePath)
                .apply()

            saveLast(context, "Recording started for $leadName")
            true
        } catch (e: Exception) {
            saveLast(context, "Recording start failed: ${e.message ?: "Unknown error"}")
            isRecording = false
            recorder = null
            false
        }
    }

    fun stopAndUpload(context: Context, finalStatus: String = "completed"): UploadResult {
        val p = prefs(context)
        val requestId = if (activeRequestId > 0) activeRequestId else p.getInt("active_request_id", 0)
        val leadId = if (activeLeadId > 0) activeLeadId else p.getInt("active_lead_id", 0)
        val leadName = if (activeLeadName.isNotBlank()) activeLeadName else (p.getString("active_lead_name", "Lead") ?: "Lead")
        val crmUrl = p.getString("active_crm_url", p.getString("crm_url", "") ?: "") ?: ""
        val token = p.getString("active_token", p.getString("mobile_token", "") ?: "") ?: ""
        val userId = p.getInt("active_user_id", p.getInt("user_id", 0))

        val started = if (startedAtMs > 0L) startedAtMs else p.getLong("active_recording_started_ms", 0L)
        val durationSeconds = if (started > 0L) ((System.currentTimeMillis() - started) / 1000L).coerceAtLeast(0L) else 0L
        val durationText = formatDuration(durationSeconds)

        val stoppedFile = try {
            val file = activeFile ?: File(p.getString("active_recording_path", "") ?: "")
            if (isRecording) {
                try { recorder?.stop() } catch (_: Exception) {}
                try { recorder?.reset() } catch (_: Exception) {}
                try { recorder?.release() } catch (_: Exception) {}
            }
            file
        } catch (e: Exception) {
            saveLast(context, "Recording stop failed: ${e.message ?: "Unknown error"}")
            activeFile
        } finally {
            recorder = null
            isRecording = false
            activeFile = null
            startedAtMs = 0L
            activeRequestId = 0
            activeLeadId = 0
            activeLeadName = "Lead"
        }

        if (requestId <= 0 || leadId <= 0) {
            return UploadResult(false, "Missing request/lead id", duration = durationText)
        }

        if (stoppedFile == null || !stoppedFile.exists() || stoppedFile.length() <= 100L) {
            saveLast(context, "No usable recording file. Marking call completed only.")
            return UploadResult(false, "Recording file missing/too small", duration = durationText)
        }

        return try {
            val result = uploadRecording(
                crmUrl = crmUrl,
                token = token,
                userId = userId,
                leadId = leadId,
                requestId = requestId,
                leadName = leadName,
                file = stoppedFile,
                duration = durationText,
                notes = "Recorded from Android companion app. Status: $finalStatus"
            )
            prefs(context).edit()
                .putString("last_recording_path", stoppedFile.absolutePath)
                .putString("last_recording_url", result.fileUrl)
                .putString("last_recording_duration", durationText)
                .apply()
            saveLast(context, result.message)
            result
        } catch (e: Exception) {
            val msg = "Recording saved locally but upload failed: ${e.message ?: "Unknown error"}"
            saveLast(context, msg)
            UploadResult(false, msg, duration = durationText, localPath = stoppedFile.absolutePath)
        }
    }

    private fun uploadRecording(
        crmUrl: String,
        token: String,
        userId: Int,
        leadId: Int,
        requestId: Int,
        leadName: String,
        file: File,
        duration: String,
        notes: String
    ): UploadResult {
        if (crmUrl.isBlank() || token.isBlank() || userId <= 0) {
            return UploadResult(false, "CRM login session missing", duration = duration, localPath = file.absolutePath)
        }

        val boundary = "----CRMRecording${System.currentTimeMillis()}"
        val url = URL("${crmUrl.trimEnd('/')}/api/upload-call-recording.php")
        val con = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 30000
            readTimeout = 60000
            doOutput = true
            setRequestProperty("X-Mobile-Token", token)
            setRequestProperty("Accept", "application/json")
            setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")
        }

        BufferedOutputStream(con.outputStream).use { out ->
            writeField(out, boundary, "user_id", userId.toString())
            writeField(out, boundary, "token", token)
            writeField(out, boundary, "lead_id", leadId.toString())
            writeField(out, boundary, "request_id", requestId.toString())
            writeField(out, boundary, "title", "Mobile Call Recording - $leadName")
            writeField(out, boundary, "duration", duration)
            writeField(out, boundary, "notes", notes)
            writeFile(out, boundary, "recording", file, "audio/mp4")
            out.write("--$boundary--\r\n".toByteArray(Charsets.UTF_8))
            out.flush()
        }

        val response = readConnection(con)
        val json = JSONObject(response)
        val ok = con.responseCode in 200..299 && json.optBoolean("success", false)
        if (!ok) {
            return UploadResult(false, json.optString("message", "Upload failed"), duration = duration, localPath = file.absolutePath)
        }
        val recording = json.optJSONObject("recording")
        return UploadResult(
            success = true,
            message = "Recording uploaded successfully",
            fileUrl = recording?.optString("file_url", "") ?: "",
            duration = duration,
            localPath = file.absolutePath
        )
    }

    private fun writeField(out: BufferedOutputStream, boundary: String, name: String, value: String) {
        out.write("--$boundary\r\n".toByteArray(Charsets.UTF_8))
        out.write("Content-Disposition: form-data; name=\"$name\"\r\n\r\n".toByteArray(Charsets.UTF_8))
        out.write(value.toByteArray(Charsets.UTF_8))
        out.write("\r\n".toByteArray(Charsets.UTF_8))
    }

    private fun writeFile(out: BufferedOutputStream, boundary: String, fieldName: String, file: File, contentType: String) {
        out.write("--$boundary\r\n".toByteArray(Charsets.UTF_8))
        out.write("Content-Disposition: form-data; name=\"$fieldName\"; filename=\"${file.name}\"\r\n".toByteArray(Charsets.UTF_8))
        out.write("Content-Type: $contentType\r\n\r\n".toByteArray(Charsets.UTF_8))
        BufferedInputStream(FileInputStream(file)).use { input ->
            val buffer = ByteArray(8192)
            while (true) {
                val read = input.read(buffer)
                if (read == -1) break
                out.write(buffer, 0, read)
            }
        }
        out.write("\r\n".toByteArray(Charsets.UTF_8))
    }

    private fun readConnection(con: HttpURLConnection): String {
        val stream = if (con.responseCode in 200..299) con.inputStream else con.errorStream
        return BufferedReader(stream.reader()).use { it.readText() }
    }

    private fun formatDuration(seconds: Long): String {
        val min = seconds / 60
        val sec = seconds % 60
        return String.format(Locale.US, "%02d:%02d", min, sec)
    }

    private fun prefs(context: Context) = context.getSharedPreferences("companion_prefs", Context.MODE_PRIVATE)

    private fun saveLast(context: Context, message: String) {
        prefs(context).edit().putString("last_message", message).apply()
    }
}
