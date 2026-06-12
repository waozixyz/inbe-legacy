package io.naox.inbe

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val exportChannel = "io.naox.inbe/export"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, exportChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareJsonExport" -> {
                    val fileName = call.argument<String>("fileName")
                    val content = call.argument<String>("content")

                    if (fileName.isNullOrBlank() || content == null) {
                        result.error("invalid_args", "Missing export file name or content", null)
                        return@setMethodCallHandler
                    }

                    try {
                        shareJsonExport(fileName, content)
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("export_failed", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun shareJsonExport(fileName: String, content: String) {
        val exportDir = File(cacheDir, "exports")
        exportDir.mkdirs()

        val exportFile = File(exportDir, fileName)
        exportFile.writeText(content, Charsets.UTF_8)

        val uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            exportFile
        )

        val sendIntent = Intent(Intent.ACTION_SEND).apply {
            type = "application/json"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TITLE, fileName)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        val chooser = Intent.createChooser(sendIntent, fileName).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        startActivity(chooser)
    }
}
