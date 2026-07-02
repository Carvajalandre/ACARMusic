package com.acar.music

import android.content.ActivityNotFoundException
import android.content.Intent
import android.media.audiofx.AudioEffect
import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

class MainActivity : AudioServiceFragmentActivity() {

    private val CHANNEL = "com.acar.music/equalizer"
    lateinit var visualizerPlugin: VisualizerPlugin

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openEqualizer" -> {
                        val sessionId = call.argument<Int>("audioSessionId") ?: 0
                        try {
                            val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL).apply {
                                putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
                                putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
                                putExtra(AudioEffect.EXTRA_PACKAGE_NAME, packageName)
                            }
                            startActivityForResult(intent, 0)
                            result.success(true)
                        } catch (e: ActivityNotFoundException) {
                            result.success(false)
                        } catch (e: Exception) {
                            result.error("EQ_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        visualizerPlugin = VisualizerPlugin(WeakReference(this), flutterEngine)
    }

    override fun onDestroy() {
        if (::visualizerPlugin.isInitialized) {
            visualizerPlugin.destroy()
        }
        super.onDestroy()
    }
}
