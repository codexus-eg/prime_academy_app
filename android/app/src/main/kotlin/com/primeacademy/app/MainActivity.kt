package com.primeacademy.app

import android.app.DownloadManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.DocumentsContract
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.google.firebase.installations.FirebaseInstallations
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val FCM_FID_CHANNEL = "prime.academy/fcm_fid"
        private const val FILES_CHANNEL = "prime.academy/files"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Honor LaunchTheme splash attrs (solid bg, no launcher icon).
            installSplashScreen()
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FCM_FID_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "registerAndGetFid" -> registerAndGetFid(result)
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FILES_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openFolder" -> {
                    val path = call.argument<String>("path")
                    openFolder(path, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Opens a public storage folder in the system Files app when possible.
     * Returns true only when an external activity was actually started.
     */
    private fun openFolder(path: String?, result: MethodChannel.Result) {
        if (path.isNullOrBlank()) {
            result.error("INVALID_PATH", "Folder path is required", null)
            return
        }

        try {
            val folder = File(path)
            if (!folder.exists()) {
                folder.mkdirs()
            }

            val documentUri = toExternalStorageDocumentUri(path)
            if (documentUri != null) {
                val viewDir = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(documentUri, DocumentsContract.Document.MIME_TYPE_DIR)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    addCategory(Intent.CATEGORY_DEFAULT)
                }
                if (viewDir.resolveActivity(packageManager) != null) {
                    startActivity(viewDir)
                    result.success(true)
                    return
                }

                // Some OEMs only accept browse intents without an explicit MIME.
                val browse = Intent(Intent.ACTION_VIEW).apply {
                    data = documentUri
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                if (browse.resolveActivity(packageManager) != null) {
                    startActivity(browse)
                    result.success(true)
                    return
                }
            }

            // Public Download paths: at least open system Downloads UI.
            if (path.contains("/Download", ignoreCase = true)) {
                val downloads = Intent(DownloadManager.ACTION_VIEW_DOWNLOADS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                if (downloads.resolveActivity(packageManager) != null) {
                    startActivity(downloads)
                    result.success(true)
                    return
                }
            }

            result.success(false)
        } catch (e: Exception) {
            result.error("OPEN_FOLDER_FAILED", e.message, null)
        }
    }

    /**
     * Maps `/storage/emulated/0/...` to a DocumentsProvider URI that Files can open.
     */
    private fun toExternalStorageDocumentUri(absolutePath: String): Uri? {
        val normalized = absolutePath.replace('\\', '/')
        val roots = listOf(
            "/storage/emulated/0/",
            "/sdcard/",
            "/mnt/sdcard/",
        )
        for (root in roots) {
            if (!normalized.startsWith(root)) continue
            val relative = normalized.removePrefix(root).trim('/')
            if (relative.isEmpty()) continue
            // Avoid advertising private app dirs — DocumentsUI cannot browse them.
            if (relative.startsWith("Android/data/", ignoreCase = true) ||
                relative.startsWith("Android/obb/", ignoreCase = true)
            ) {
                return null
            }
            val docId = "primary:$relative"
            return DocumentsContract.buildDocumentUri(
                "com.android.externalstorage.documents",
                docId,
            )
        }
        return null
    }

    /**
     * Registers this app instance with FCM using the Installation ID path
     * (requires firebase_messaging_installation_id_enabled=true), then returns
     * the FID that Admin SDK can target with FidMulticastMessage.
     */
    private fun registerAndGetFid(result: MethodChannel.Result) {
        FirebaseMessaging.getInstance().register()
            .addOnCompleteListener { registerTask ->
                if (!registerTask.isSuccessful) {
                    result.error(
                        "FCM_REGISTER_FAILED",
                        registerTask.exception?.message ?: "register() failed",
                        null,
                    )
                    return@addOnCompleteListener
                }

                FirebaseInstallations.getInstance().id
                    .addOnCompleteListener { idTask ->
                        val fid = idTask.result
                        if (!idTask.isSuccessful || fid.isNullOrEmpty()) {
                            result.error(
                                "FID_UNAVAILABLE",
                                idTask.exception?.message ?: "Installations.getId failed",
                                null,
                            )
                            return@addOnCompleteListener
                        }
                        result.success(fid)
                    }
            }
    }
}
