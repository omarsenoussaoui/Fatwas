package com.fatwas.fatwas_app

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.fatwas.fatwas_app/share"
    private var methodChannel: MethodChannel? = null
    private var pendingSharedFiles: List<String>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedFiles" -> {
                    val files = pendingSharedFiles
                    pendingSharedFiles = null
                    result.success(files)
                }
                else -> result.notImplemented()
            }
        }

        // Handle the intent that launched the activity
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        when (intent.action) {
            Intent.ACTION_SEND -> {
                if (intent.type?.startsWith("audio/") == true) {
                    val uri = intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                    if (uri != null) {
                        val filePath = copyUriToLocalFile(uri)
                        if (filePath != null) {
                            pendingSharedFiles = listOf(filePath)
                            // Notify Flutter if already running
                            methodChannel?.invokeMethod("onSharedFiles", listOf(filePath))
                        }
                    }
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                if (intent.type?.startsWith("audio/") == true) {
                    val uris = intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                    if (uris != null) {
                        val filePaths = uris.mapNotNull { copyUriToLocalFile(it) }
                        if (filePaths.isNotEmpty()) {
                            pendingSharedFiles = filePaths
                            methodChannel?.invokeMethod("onSharedFiles", filePaths)
                        }
                    }
                }
            }
        }
    }

    /**
     * Copy content URI to a local file in the app's cache directory.
     * This is necessary because content:// URIs from other apps are temporary
     * and can't be accessed later by the transcription service.
     */
    private fun copyUriToLocalFile(uri: Uri): String? {
        return try {
            val inputStream = contentResolver.openInputStream(uri) ?: return null

            // Get a reasonable filename
            val fileName = getFileName(uri) ?: "shared_audio_${System.currentTimeMillis()}.audio"

            // Save to app's shared_audio directory
            val dir = File(filesDir, "shared_audio")
            if (!dir.exists()) dir.mkdirs()

            val destFile = File(dir, fileName)
            FileOutputStream(destFile).use { output ->
                inputStream.copyTo(output)
            }
            inputStream.close()

            destFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun getFileName(uri: Uri): String? {
        // Try to get display name from content resolver
        val cursor = contentResolver.query(uri, null, null, null, null)
        cursor?.use {
            if (it.moveToFirst()) {
                val nameIndex = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                if (nameIndex >= 0) {
                    return it.getString(nameIndex)
                }
            }
        }
        // Fallback: use last path segment
        return uri.lastPathSegment
    }
}
