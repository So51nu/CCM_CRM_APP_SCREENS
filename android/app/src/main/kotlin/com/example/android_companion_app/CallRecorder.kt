package com.example.android_companion_app

import android.content.ContentValues
import android.content.Context
import android.media.MediaRecorder
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Environment
import android.provider.MediaStore
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
    private var selectedAudioSource = -1
    private val amplitudeHandler = Handler(Looper.getMainLooper())
    private var maxRecordedAmplitude = 0
    private var amplitudeSamples = 0
    private val amplitudeRunnable = object : Runnable {
        override fun run() {
            if (!started) return
            try {
                val amp = recorder?.maxAmplitude ?: 0
                if (amp > maxRecordedAmplitude) maxRecordedAmplitude = amp
                amplitudeSamples += 1
                context.getSharedPreferences("crm_companion", Context.MODE_PRIVATE).edit()
                    .putInt("lastRecordingMaxAmplitude", maxRecordedAmplitude)
                    .putInt("lastRecordingAmplitudeSamples", amplitudeSamples)
                    .apply()
            } catch (_: Exception) {}
            if (started) amplitudeHandler.postDelayed(this, 500L)
        }
    }

    data class RecordingResult(
        val uploadFile: File?,
        val publicPath: String,
        val publicUri: String,
        val byteSize: Long,
        val message: String,
        val isValid: Boolean,
        val maxAmplitude: Int = 0,
        val audioSource: String = "UNKNOWN"
    )

    fun ensureVisibleRecordingFolder(): Map<String, Any> {
        val folderLabel = "Music/ClickConnectCRM/CallRecordings"
        val editor = context.getSharedPreferences("crm_companion", Context.MODE_PRIVATE).edit()
            .putString("recordingFolderPath", folderLabel)
            .putString("recordingFolderName", "ClickConnectCRM/CallRecordings")

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "ClickConnectCRM/CallRecordings")
            val ok = dir.exists() || dir.mkdirs()
            editor.putString("recordingFolderPath", dir.absolutePath)
                .putBoolean("recordingFolderReady", ok)
                .apply()
            return mapOf("ready" to ok, "path" to dir.absolutePath, "message" to if (ok) "Folder ready" else "Folder permission required")
        }

        // Android 10+ uses scoped storage. Empty public media folders are created by MediaStore
        // when the first recording is inserted. We still keep the visible folder path for the UI.
        editor.putBoolean("recordingFolderReady", true).apply()
        return mapOf(
            "ready" to true,
            "path" to folderLabel,
            "message" to "Folder will be visible in Music after first saved recording"
        )
    }

    fun start(requestId: Int, leadId: Int): String? {
        if (started) return outputFile?.absolutePath
        ensureVisibleRecordingFolder()

        val dir = File(context.getExternalFilesDir(Environment.DIRECTORY_MUSIC), "call_recordings_tmp")
        if (!dir.exists()) dir.mkdirs()
        val stamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        outputFile = File(dir, "call_req_${requestId}_lead_${leadId}_$stamp.m4a")
        maxRecordedAmplitude = 0
        amplitudeSamples = 0

        val sources = intArrayOf(
            MediaRecorder.AudioSource.VOICE_COMMUNICATION,
            MediaRecorder.AudioSource.MIC,
            MediaRecorder.AudioSource.VOICE_RECOGNITION,
            MediaRecorder.AudioSource.CAMCORDER
        )
        var lastError = ""
        for (source in sources) {
            try {
                if (outputFile!!.exists()) outputFile!!.delete()
                startWithSource(source, outputFile!!)
                selectedAudioSource = source
                started = true
                amplitudeHandler.removeCallbacks(amplitudeRunnable)
                amplitudeHandler.postDelayed(amplitudeRunnable, 500L)
                context.getSharedPreferences("crm_companion", Context.MODE_PRIVATE).edit()
                    .putString("lastRecordingPath", "Recording... Music/ClickConnectCRM/CallRecordings/${outputFile!!.name}")
                    .putString("lastRecordingTempPath", outputFile!!.absolutePath)
                    .putString("lastMessage", "Recording started (${audioSourceName(source)}): ${outputFile!!.name}")
                    .apply()
                return outputFile!!.absolutePath
            } catch (e: Exception) {
                lastError = e.message ?: e.toString()
                try { recorder?.reset() } catch (_: Exception) {}
                try { recorder?.release() } catch (_: Exception) {}
                recorder = null
                started = false
                selectedAudioSource = -1
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
            setAudioEncodingBitRate(96000)
            setAudioSamplingRate(44100)
            setMaxDuration(readMaxRecordingMs())
            setOutputFile(file.absolutePath)
            prepare()
            start()
        }
    }

    private fun readMaxRecordingMs(): Int {
        val minutes = context.getSharedPreferences("crm_companion", Context.MODE_PRIVATE)
            .getInt("maxRecordingMinutes", 30)
            .coerceIn(1, 120)
        return minutes * 60 * 1000
    }

    fun stop(): RecordingResult {
        val file = outputFile
        amplitudeHandler.removeCallbacks(amplitudeRunnable)
        var stopError = ""
        try {
            if (started) {
                try { Thread.sleep(250L) } catch (_: InterruptedException) {}
                recorder?.stop()
            }
        } catch (e: Exception) {
            stopError = e.message ?: e.toString()
        } finally {
            try { recorder?.reset() } catch (_: Exception) {}
            try { recorder?.release() } catch (_: Exception) {}
            recorder = null
            started = false
        }

        if (file == null || !file.exists()) {
            return RecordingResult(null, "", "", 0L, "Recording file was not created${if (stopError.isNotBlank()) ": $stopError" else ""}", false, maxRecordedAmplitude, audioSourceName(selectedAudioSource))
        }

        val size = file.length()
        if (size < MIN_VALID_RECORDING_BYTES) {
            val msg = if (stopError.isNotBlank()) "Recording invalid/empty ($size bytes): $stopError" else "Recording invalid/empty ($size bytes). Device blocked call audio capture."
            context.getSharedPreferences("crm_companion", Context.MODE_PRIVATE).edit()
                .putString("lastRecordingPath", file.absolutePath)
                .putString("lastMessage", msg)
                .apply()
            return RecordingResult(file, file.absolutePath, "", size, msg, false, maxRecordedAmplitude, audioSourceName(selectedAudioSource))
        }

        if (maxRecordedAmplitude <= MIN_VALID_AUDIO_AMPLITUDE) {
            val msg = "Recording created but no voice audio was captured (max level $maxRecordedAmplitude). Device/Android blocked cellular call audio. Try Speaker Capture mode or server-side IVR recording."
            context.getSharedPreferences("crm_companion", Context.MODE_PRIVATE).edit()
                .putString("lastRecordingPath", file.absolutePath)
                .putString("lastMessage", msg)
                .putBoolean("lastRecordingSilent", true)
                .apply()
            return RecordingResult(file, file.absolutePath, "", size, msg, false, maxRecordedAmplitude, audioSourceName(selectedAudioSource))
        }

        val public = copyToVisibleStorage(file)
        val publicPath = public.first
        val publicUri = public.second
        val msg = "Recording saved: $publicPath ($size bytes, ${audioSourceName(selectedAudioSource)}, audio level $maxRecordedAmplitude)"
        context.getSharedPreferences("crm_companion", Context.MODE_PRIVATE).edit()
            .putString("lastRecordingPath", publicPath.ifBlank { file.absolutePath })
            .putString("lastRecordingPublicUri", publicUri)
            .putString("lastMessage", msg)
            .apply()
        return RecordingResult(file, publicPath.ifBlank { file.absolutePath }, publicUri, size, msg, true, maxRecordedAmplitude, audioSourceName(selectedAudioSource))
    }

    private fun copyToVisibleStorage(file: File): Pair<String, String> {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val relativePath = "${Environment.DIRECTORY_MUSIC}/ClickConnectCRM/CallRecordings"
                val values = ContentValues().apply {
                    put(MediaStore.Audio.Media.DISPLAY_NAME, file.name)
                    put(MediaStore.Audio.Media.MIME_TYPE, "audio/mp4")
                    put(MediaStore.Audio.Media.RELATIVE_PATH, relativePath)
                    put(MediaStore.Audio.Media.IS_PENDING, 1)
                }
                val uri: Uri = context.contentResolver.insert(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, values)
                    ?: return Pair(file.absolutePath, "")
                try {
                    context.contentResolver.openOutputStream(uri, "w")?.use { out ->
                        FileInputStream(file).use { input -> input.copyTo(out) }
                    }
                    values.clear()
                    values.put(MediaStore.Audio.Media.IS_PENDING, 0)
                    context.contentResolver.update(uri, values, null, null)
                    Pair("$relativePath/${file.name}", uri.toString())
                } catch (e: Exception) {
                    try { context.contentResolver.delete(uri, null, null) } catch (_: Exception) {}
                    Pair(file.absolutePath, "")
                }
            } else {
                val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "ClickConnectCRM/CallRecordings")
                if (!dir.exists()) dir.mkdirs()
                val dest = File(dir, file.name)
                file.copyTo(dest, overwrite = true)
                Pair(dest.absolutePath, Uri.fromFile(dest).toString())
            }
        } catch (_: Exception) {
            Pair(file.absolutePath, "")
        }
    }

    fun uploadRecording(
        crmUrl: String,
        userId: Int,
        token: String,
        requestId: Int,
        leadId: Int,
        file: File,
        duration: String,
        publicPath: String = "",
        publicUri: String = "",
        maxAmplitude: Int = maxRecordedAmplitude
    ): String {
        if (!file.exists() || file.length() < MIN_VALID_RECORDING_BYTES) {
            throw Exception("Recording file is empty or too small: ${file.length()} bytes")
        }
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
            field("local_path", publicPath.ifBlank { file.absolutePath })
            field("local_uri", publicUri)
            field("byte_size", file.length().toString())
            field("audio_source", audioSourceName(selectedAudioSource))
            field("audio_level", maxAmplitude.toString())
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

    private fun audioSourceName(source: Int): String {
        return when (source) {
            MediaRecorder.AudioSource.VOICE_COMMUNICATION -> "VOICE_COMMUNICATION"
            MediaRecorder.AudioSource.MIC -> "MIC"
            MediaRecorder.AudioSource.VOICE_RECOGNITION -> "VOICE_RECOGNITION"
            MediaRecorder.AudioSource.CAMCORDER -> "CAMCORDER"
            else -> "UNKNOWN"
        }
    }

    companion object {
        private const val MIN_VALID_RECORDING_BYTES = 1024L
        private const val MIN_VALID_AUDIO_AMPLITUDE = 100
    }
}
