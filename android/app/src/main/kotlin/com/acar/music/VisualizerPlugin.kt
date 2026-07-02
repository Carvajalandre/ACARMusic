package com.acar.music

import android.Manifest
import android.content.pm.PackageManager
import android.media.audiofx.Visualizer
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference
import kotlin.math.sqrt

class VisualizerPlugin(
    private val activity: WeakReference<MainActivity>,
    private val flutterEngine: FlutterEngine
) {
    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var listener: Visualizer.OnDataCaptureListener? = null
    private val CHANNEL = "com.acar.music/visualizer"
    private val FFT_CHANNEL = "com.acar.music/visualizer_fft"
    private val RECORD_AUDIO_PERMISSION = 1001

    private val methodChannel: MethodChannel
    private val eventChannel: EventChannel

    private val fftBuffer = FloatArray(64)

    init {
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).apply {
            setMethodCallHandler { call, result ->
                handleMethodCall(call, result)
            }
        }

        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger, FFT_CHANNEL
        ).apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startVisualizer" -> {
                val sessionId = call.argument<Int>("audioSessionId") ?: 0
                if (checkPermission()) {
                    startVisualizer(sessionId)
                    result.success(true)
                } else {
                    requestPermission()
                    result.success(false)
                }
            }
            "stopVisualizer" -> {
                stopVisualizer()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun checkPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val act = activity.get() ?: return false
        return ActivityCompat.checkSelfPermission(
            act, Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestPermission() {
        val act = activity.get() ?: return
        ActivityCompat.requestPermissions(
            act,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            RECORD_AUDIO_PERMISSION
        )
    }

    private fun startVisualizer(sessionId: Int) {
        stopVisualizer()
        try {
            val viz = Visualizer(sessionId)
            viz.enabled = false

            // Use a safe default capture size
            val captureSize = 256
            viz.setCaptureSize(captureSize)

            listener = object : Visualizer.OnDataCaptureListener {
                override fun onWaveFormDataCapture(
                    visualizer: Visualizer?,
                    waveform: ByteArray?,
                    samplingRate: Int
                ) {}

                override fun onFftDataCapture(
                    visualizer: Visualizer?,
                    fft: ByteArray?,
                    samplingRate: Int
                ) {
                    processFft(fft)
                }
            }

            // Use max capture rate for smooth 60fps animation
            val captureRate = Visualizer.getMaxCaptureRate()
            viz.setDataCaptureListener(
                listener,
                captureRate,
                false, // waveform
                true  // fft
            )
            viz.enabled = true
            visualizer = viz
        } catch (e: Exception) {
            // Fallback: no visualizer available
        }
    }

    private fun processFft(fft: ByteArray?) {
        if (fft == null || eventSink == null) return
        val n = minOf(fft.size / 2, fftBuffer.size)
        for (i in 0 until n) {
            val real = fft[i * 2].toDouble()
            val imag = fft[i * 2 + 1].toDouble()
            val magnitude = sqrt(real * real + imag * imag)
            // Scale properly: FFT values are in range -128 to 127 for bytes
            // Magnitude max is ~181 (sqrt(128^2 + 128^2)), normalize to 0-1
            fftBuffer[i] = (magnitude / 181.0).coerceIn(0.0, 1.0).toFloat()
        }
        val data = FloatArray(n)
        System.arraycopy(fftBuffer, 0, data, 0, n)
        eventSink?.success(data.toList())
    }

    private fun stopVisualizer() {
        try {
            visualizer?.apply {
                enabled = false
                release()
            }
            visualizer = null
        } catch (_: Exception) {}
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray
    ): Boolean {
        if (requestCode == RECORD_AUDIO_PERMISSION) {
            if (grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            ) {
                return true
            }
        }
        return false
    }

    fun destroy() {
        stopVisualizer()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }
}
