package com.suikai.suikai

import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Bundle
import androidx.media3.common.MediaItem
import androidx.media3.common.MimeTypes
import androidx.media3.effect.BitmapOverlay
import androidx.media3.effect.OverlayEffect
import androidx.media3.effect.StaticOverlaySettings
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.Transformer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
	private companion object {
		const val watermarkChannel = "com.suikai.suikai/video_watermark"
		const val watermarkAlpha = 0.33f
		const val watermarkWidthFraction = 0.08f
		const val watermarkMarginFraction = 0.03f
	}

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, watermarkChannel)
			.setMethodCallHandler { call, result ->
				if (call.method != "apply") {
					result.notImplemented()
					return@setMethodCallHandler
				}
				watermarkVideo(call, result)
			}
	}

	private fun watermarkVideo(call: MethodCall, result: MethodChannel.Result) {
		val sourcePath = call.argument<String>("sourcePath")
		val logoPath = call.argument<String>("logoPath")
		val outputPath = call.argument<String>("outputPath")
		if (sourcePath.isNullOrBlank() || logoPath.isNullOrBlank() || outputPath.isNullOrBlank()) {
			result.error("invalid_arguments", "sourcePath, logoPath and outputPath are required", null)
			return
		}
		val source = File(sourcePath)
		val logo = File(logoPath)
		val output = File(outputPath)
		if (!source.isFile || !logo.isFile) {
			result.error("missing_input", "Video or watermark logo file is missing", null)
			return
		}
		if (output.exists() && !output.delete()) {
			result.error("output_cleanup_failed", "Could not replace an existing watermark output", null)
			return
		}

		val watermark = try {
			loadWatermarkBitmap(sourcePath, logoPath)
		} catch (error: Exception) {
			result.error("watermark_load_failed", error.message, null)
			return
		}
		val settings = StaticOverlaySettings.Builder()
			.setAlphaScale(watermarkAlpha)
			.setOverlayFrameAnchor(1f, 1f)
			.setBackgroundFrameAnchor(
				1f - (2f * watermarkMarginFraction),
				1f - (2f * watermarkMarginFraction),
			)
			.build()
		val overlay = BitmapOverlay.createStaticBitmapOverlay(watermark, settings)
		val editedItem = EditedMediaItem.Builder(MediaItem.fromUri(Uri.fromFile(source)))
			.setEffects(
				Effects(
					emptyList(),
					listOf(OverlayEffect(listOf(overlay))),
				),
			)
			.build()
		val transformer = Transformer.Builder(applicationContext)
			.setVideoMimeType(MimeTypes.VIDEO_H264)
			.setAudioMimeType(MimeTypes.AUDIO_AAC)
			.addListener(object : Transformer.Listener {
				override fun onCompleted(composition: androidx.media3.transformer.Composition, exportResult: ExportResult) {
					if (!output.isFile || output.length() == 0L) {
						result.error("empty_output", "Watermark export produced no video", null)
						return
					}
					result.success(outputPath)
				}

				override fun onError(
					composition: androidx.media3.transformer.Composition,
					exportResult: ExportResult,
					exportException: ExportException,
				) {
					if (output.exists()) output.delete()
					result.error("watermark_export_failed", exportException.message, null)
				}
			})
			.build()
		try {
			transformer.start(editedItem, outputPath)
		} catch (error: Exception) {
			if (output.exists()) output.delete()
			result.error("watermark_export_start_failed", error.message, null)
		}
	}

	private fun loadWatermarkBitmap(videoPath: String, logoPath: String): Bitmap {
		val logo = requireNotNull(BitmapFactory.decodeFile(logoPath)) { "Could not decode watermark logo" }
		val retriever = MediaMetadataRetriever()
		try {
			retriever.setDataSource(videoPath)
			val width = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_WIDTH)?.toIntOrNull() ?: 0
			val height = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_HEIGHT)?.toIntOrNull() ?: 0
			val rotation = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)?.toIntOrNull() ?: 0
			val displayWidth = if (rotation == 90 || rotation == 270) height else width
			check(displayWidth > 0) { "Could not determine video dimensions" }
			val targetWidth = (displayWidth * watermarkWidthFraction).toInt().coerceAtLeast(1)
			val targetHeight = (logo.height * (targetWidth.toFloat() / logo.width)).toInt().coerceAtLeast(1)
			val scaled = Bitmap.createScaledBitmap(logo, targetWidth, targetHeight, true)
			if (scaled !== logo) logo.recycle()
			return scaled
		} finally {
			retriever.release()
		}
	}

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
	}

	override fun onResume() {
		super.onResume()
	}
}
