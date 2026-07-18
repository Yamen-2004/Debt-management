package com.example.debt_book

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Backs the "debt_book/backup_storage" channel used by BackupService to
 * save JSON backups into the public Download/<subFolder> MediaStore
 * collection on Android 10+ (API 29+), with zero storage permissions —
 * inserting into MediaStore.Downloads never requires WRITE_EXTERNAL_STORAGE,
 * and querying/deleting rows this app itself created is likewise
 * permission-free (unpermissioned queries are scoped to the app's own rows).
 */
class MainActivity : FlutterActivity() {
    private val channelName = "debt_book/backup_storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> {
                        try {
                            val fileName = call.argument<String>("fileName")!!
                            val content = call.argument<String>("content")!!
                            val subFolder = call.argument<String>("subFolder") ?: ""
                            result.success(saveToDownloads(fileName, content, subFolder))
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    "cleanupDownloads" -> {
                        try {
                            val prefix = call.argument<String>("prefix") ?: ""
                            val suffix = call.argument<String>("suffix") ?: ""
                            val subFolder = call.argument<String>("subFolder") ?: ""
                            val keepCount = call.argument<Int>("keepCount") ?: 5
                            cleanupDownloads(prefix, suffix, subFolder, keepCount)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("CLEANUP_FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun relativePath(subFolder: String): String {
        return if (subFolder.isEmpty()) {
            "${Environment.DIRECTORY_DOWNLOADS}/"
        } else {
            "${Environment.DIRECTORY_DOWNLOADS}/$subFolder/"
        }
    }

    private fun saveToDownloads(fileName: String, content: String, subFolder: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            throw UnsupportedOperationException(
                "MediaStore.Downloads requires API 29+ (current: ${Build.VERSION.SDK_INT})"
            )
        }

        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, "application/json")
            put(MediaStore.Downloads.RELATIVE_PATH, relativePath(subFolder))
            put(MediaStore.Downloads.IS_PENDING, 1)
        }

        val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("MediaStore insert returned a null Uri")

        resolver.openOutputStream(uri)?.use { out ->
            out.write(content.toByteArray(Charsets.UTF_8))
        } ?: throw IllegalStateException("Unable to open output stream for $uri")

        val donePending = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
        resolver.update(uri, donePending, null, null)

        return true
    }

    private fun cleanupDownloads(
        prefix: String,
        suffix: String,
        subFolder: String,
        keepCount: Int,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return

        val resolver = applicationContext.contentResolver
        val projection = arrayOf(MediaStore.Downloads._ID, MediaStore.Downloads.DISPLAY_NAME)
        val selection =
            "${MediaStore.Downloads.RELATIVE_PATH} = ? AND ${MediaStore.Downloads.DISPLAY_NAME} LIKE ?"
        val selectionArgs = arrayOf(relativePath(subFolder), "$prefix%$suffix")

        val ids = mutableListOf<Long>()
        resolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            "${MediaStore.Downloads.DISPLAY_NAME} DESC",
        )?.use { cursor ->
            val idCol = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
            while (cursor.moveToNext()) {
                ids.add(cursor.getLong(idCol))
            }
        }

        if (ids.size > keepCount) {
            for (id in ids.drop(keepCount)) {
                val uri = MediaStore.Downloads.EXTERNAL_CONTENT_URI.buildUpon()
                    .appendPath(id.toString())
                    .build()
                resolver.delete(uri, null, null)
            }
        }
    }
}
