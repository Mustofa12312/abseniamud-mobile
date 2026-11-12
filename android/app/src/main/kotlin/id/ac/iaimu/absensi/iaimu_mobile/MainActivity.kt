package id.ac.iaimu.absensi.iaimu_mobile

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val DOCUMENT_VIEWER_CHANNEL = "id.ac.iaimu.absensi/document_viewer"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DOCUMENT_VIEWER_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFile" -> {
                    val rawFileName = call.argument<String>("fileName") ?: "lampiran.pdf"
                    val bytes = call.argument<ByteArray>("bytes")
                    val mimeType = call.argument<String>("mimeType") ?: "*/*"

                    if (bytes == null || bytes.isEmpty()) {
                        result.error("EMPTY_FILE", "Berkas dokumen kosong.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val safeName = rawFileName
                            .substringAfterLast('/')
                            .substringAfterLast('\\')
                            .replace(Regex("[^a-zA-Z0-9._-]"), "_")
                            .ifBlank { "lampiran" }

                        val docsDir = File(cacheDir, "leave_documents").apply { mkdirs() }
                        val targetFile = File(docsDir, safeName)
                        targetFile.writeBytes(bytes)

                        val uri = FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.iaimu_fileprovider",
                            targetFile
                        )

                        val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, mimeType)
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }

                        startActivity(viewIntent)
                        result.success(null)
                    } catch (_: ActivityNotFoundException) {
                        result.error(
                            "NO_VIEWER",
                            "Tidak ada aplikasi di perangkat untuk membuka berkas jenis ini.",
                            null
                        )
                    } catch (e: Exception) {
                        result.error("OPEN_ERROR", e.localizedMessage ?: "Gagal membuka berkas.", null)
                    }
                }

                "openUrl" -> {
                    val url = call.argument<String>("url")?.trim()
                    if (url.isNullOrEmpty()) {
                        result.error("INVALID_URL", "URL dokumen kosong.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val uri = Uri.parse(url)
                        val scheme = uri.scheme?.lowercase()
                        if (scheme != "http" && scheme != "https") {
                            result.error("INVALID_URL", "Skema URL tidak didukung.", null)
                            return@setMethodCallHandler
                        }
                        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(null)
                    } catch (_: ActivityNotFoundException) {
                        result.error(
                            "NO_BROWSER",
                            "Tidak ada browser atau aplikasi untuk membuka tautan ini.",
                            null
                        )
                    } catch (e: Exception) {
                        result.error("OPEN_ERROR", e.localizedMessage ?: "Gagal membuka tautan.", null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
