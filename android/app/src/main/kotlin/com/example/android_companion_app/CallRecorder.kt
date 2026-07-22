package com.example.android_companion_app

import android.content.Context
import android.media.MediaRecorder
import android.os.Build
import android.os.Environment
import java.io.BufferedInputStream
import java.io.DataOutputStream
import java.io.File
import java.io.FileInputStream
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import org.json.JSONObject

class CallRecorder(private val context: Context) {
    private var recorder: MediaRecorder? = null
    private var outputFile: File? = null
    private var started = false


    fun ensureRecordingFolder(): File {
        val baseDir = context.getExternalFilesDir(Environment.DIRECTORY_MUSIC) ?: context.filesDir
        val dir = File(baseDir, "call_recordings")
        if (!dir.exists()) dir.mkdirs()
        context.getSharedPreferences("crm_companion", Context.MODE_PRIVATE).edit()
            .putString("recordingFolderPath", dir.absolutePath)
            .putString("lastMessage", "Recording folder ready: ${dir.absolutePath}")
            .apply()
        return dir
    }

    fun start(requestId: Int, leadId: Int): String? {
        if (started) return outputFile?.absolutePath
        val dir = ensureRecordingFolder()
        val stamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        outputFile = File(dir, "call_req_${requestId}_lead_${leadId}_$stamp.m4a")

        val sources = intArrayOf(
            MediaRecorder.AudioSource.MIC,
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,
            MediaRecorder.AudioSource.VOICE_RECOGNITION
        )
        var lastError = ""
        for (source in sources) {
            try {
                startWithSource(source, outputFile!!)
                started = true
                context.getSharedPreferences("crm_companion", Context.MODE_PRIVATE).edit()
                    .putString("lastRecordingPath", outputFile!!.absolutePath)
                    .putString("lastMessage", "Recording started: ${outputFile!!.name}")
                    .apply()
                return outputFile!!.absolutePath
            } catch (e: Exception) {
                lastError = e.message ?: e.toString()
                try { recorder?.reset() } catch (_: Exception) {}
                try { recorder?.release() } catch (_: Exception) {}
                recorder = null
                started = false
            }
        }

        context.getSharedPreferences("crm_companion", Context.MODE_PRIVATE).edit()
            .putString("lastMessage", "Recording failed: $lastError")
            .putString("lastRecordingPath", "-")
            .apply()
        return null
    }

    private fun startWithSource(source: Int, file: File) {
        recorder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) MediaRecorder(context) else @Suppress("DEPRECATION") MediaRecorder()
        recorder?.apply {
            setAudioSource(source)
            setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            setAudioEncodingBitRate(64000)
            setAudioSamplingRate(44100)
            setOutputFile(file.absolutePath)
            prepare()
            start()
        }
    }

    fun stop(): File? {
        val file = outputFile
        try {
            if (started) recorder?.stop()
        } catch (_: Exception) {
        } finally {
            try { recorder?.reset() } catch (_: Exception) {}
            try { recorder?.release() } catch (_: Exception) {}
            recorder = null
            started = false
        }
        return if (file != null && file.exists() && file.length() > 64) file else null
    }

    fun uploadRecording(
        crmUrl: String,
        userId: Int,
        token: String,
        requestId: Int,
        leadId: Int,
        file: File,
        duration: String
    ): String {
        val baseUrl = crmUrl.trimEnd('/')
        val boundary = "----CCM${System.currentTimeMillis()}"
        val url = URL("$baseUrl/api/upload-call-recording.php")
        val conn = (url.openConnection() as HttpURLConnection).apply {
            requestMethod = "POST"
            connectTimeout = 20000
            readTimeout = 45000
            doInput = true
            doOutput = true
            setRequestProperty("Accept", "application/json")
            setRequestProperty("X-Mobile-Token", token)
            setRequestProperty("Content-Type", "multipart/form-data; boundary=$boundary")
        }
        DataOutputStream(conn.outputStream).use { out ->
            fun field(name: String, value: String) {
                out.writeBytes("--$boundary\r\n")
                out.writeBytes("Content-Disposition: form-data; name=\"$name\"\r\n\r\n")
                out.writeBytes(value)
                out.writeBytes("\r\n")
            }
            field("user_id", userId.toString())
            field("token", token)
            field("request_id", requestId.toString())
            field("lead_id", leadId.toString())
            field("duration", duration)
            field("title", "Mobile Call Recording")
            out.writeBytes("--$boundary\r\n")
            out.writeBytes("Content-Disposition: form-data; name=\"recording\"; filename=\"${file.name}\"\r\n")
            out.writeBytes("Content-Type: audio/mp4\r\n\r\n")
            BufferedInputStream(FileInputStream(file)).use { input ->
                val buffer = ByteArray(8192)
                var count: Int
                while (input.read(buffer).also { count = it } != -1) {
                    out.write(buffer, 0, count)
                }
            }
            out.writeBytes("\r\n--$boundary--\r\n")
            out.flush()
        }
        val responseText = try {
            conn.inputStream.bufferedReader().use { it.readText() }
        } catch (e: Exception) {
            conn.errorStream?.bufferedReader()?.use { it.readText() } ?: e.message.orEmpty()
        }
        if (conn.responseCode !in 200..299) throw Exception("Upload HTTP ${conn.responseCode}: $responseText")
        val json = JSONObject(responseText)
        if (json.optBoolean("success") == false) throw Exception(json.optString("message", "Upload failed"))
        val direct = json.optString("public_url", json.optString("recording_url", json.optString("url", "")))
        if (direct.isNotBlank()) return direct
        val rec = json.optJSONObject("recording")
        val fileUrl = rec?.optString("file_url", "") ?: ""
        if (fileUrl.isNotBlank()) return if (fileUrl.startsWith("http")) fileUrl else "$baseUrl/${fileUrl.trimStart('/')}"
        return "Uploaded"
    }
}
