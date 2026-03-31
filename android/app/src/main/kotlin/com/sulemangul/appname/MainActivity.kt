package com.sulemangul.appname

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
	private val mediaStoreChannel = "voice_cleaner/media_store"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, mediaStoreChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"saveAudioToDownloads" -> {
						val sourcePath = call.argument<String>("sourcePath")
						val displayName = call.argument<String>("displayName")
						val mimeType = call.argument<String>("mimeType") ?: "audio/wav"
						val subDirectory = call.argument<String>("subDirectory") ?: "VoiceCleaner"

						if (sourcePath.isNullOrBlank() || displayName.isNullOrBlank()) {
							result.error("INVALID_ARGS", "sourcePath and displayName are required", null)
							return@setMethodCallHandler
						}

						try {
							val savedUri = saveAudioToPublicDownloads(
								sourcePath = sourcePath,
								displayName = displayName,
								mimeType = mimeType,
								subDirectory = subDirectory,
							)
							result.success(savedUri)
						} catch (e: Exception) {
							result.error("SAVE_FAILED", e.message, null)
						}
					}

					else -> result.notImplemented()
				}
			}
	}

	private fun saveAudioToPublicDownloads(
		sourcePath: String,
		displayName: String,
		mimeType: String,
		subDirectory: String,
	): String {
		val sourceFile = File(sourcePath)
		if (!sourceFile.exists()) {
			throw IllegalArgumentException("Source file not found: $sourcePath")
		}

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val resolver = applicationContext.contentResolver
			val values = ContentValues().apply {
				put(MediaStore.Downloads.DISPLAY_NAME, displayName)
				put(MediaStore.Downloads.MIME_TYPE, mimeType)
				put(
					MediaStore.Downloads.RELATIVE_PATH,
					Environment.DIRECTORY_DOWNLOADS + File.separator + subDirectory,
				)
				put(MediaStore.Downloads.IS_PENDING, 1)
			}

			val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
				?: throw IllegalStateException("Failed to create MediaStore entry")

			resolver.openOutputStream(uri)?.use { outputStream ->
				FileInputStream(sourceFile).use { inputStream ->
					inputStream.copyTo(outputStream)
				}
			} ?: throw IllegalStateException("Failed to open output stream")

			values.clear()
			values.put(MediaStore.Downloads.IS_PENDING, 0)
			resolver.update(uri, values, null, null)

			return uri.toString()
		}

		@Suppress("DEPRECATION")
		val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
		val targetDir = File(downloadsDir, subDirectory)
		if (!targetDir.exists() && !targetDir.mkdirs()) {
			throw IllegalStateException("Failed to create directory: ${targetDir.absolutePath}")
		}

		val targetFile = File(targetDir, displayName)
		sourceFile.copyTo(targetFile, overwrite = true)
		return targetFile.absolutePath
	}
}
