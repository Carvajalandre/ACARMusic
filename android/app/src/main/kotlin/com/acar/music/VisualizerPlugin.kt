package com.acar.music

import android.media.audiofx.Visualizer
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
    private val fftBuffer = FloatArray(64)
    private var runningMax = 1.0

    private val methodChannel: MethodChannel
    private val eventChannel: EventChannel

    init {
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, CHANNEL
        ).apply {
            setMethodCallHandler { call, result -> handleMethodCall(call, result) }
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
                val ok = startVisualizer(sessionId)
                result.success(ok) // false = Dart usa simulado
            }
            "stopVisualizer" -> {
                stopVisualizer()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    // Un solo intento. Sin retry — Samsung DSP bloquea permanente, no transitorio.
    private fun startVisualizer(sessionId: Int): Boolean {
        stopVisualizer()
        return try {
            val viz = Visualizer(sessionId)
            viz.enabled = false
            val captureSize = Visualizer.getCaptureSizeRange()[1].coerceAtMost(512)
            viz.setCaptureSize(captureSize)

            listener = object : Visualizer.OnDataCaptureListener {
                override fun onWaveFormDataCapture(v: Visualizer?, w: ByteArray?, s: Int) {}
                override fun onFftDataCapture(v: Visualizer?, fft: ByteArray?, s: Int) {
                    processFft(fft)
                }
            }

            val captureRate = Visualizer.getMaxCaptureRate().coerceAtMost(30000)
            viz.setDataCaptureListener(listener, captureRate, false, true)
            viz.enabled = true
            visualizer = viz
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun processFft(fft: ByteArray?) {
        if (fft == null || eventSink == null) return
        val sourceBins = fft.size / 2
        val n = minOf(sourceBins, fftBuffer.size)
        val mags = DoubleArray(sourceBins)
        var frameMax = 0.0
        for (i in 0 until sourceBins) {
            val real = fft[i * 2].toDouble()
            val imag = fft[i * 2 + 1].toDouble()
            val magnitude = sqrt(real * real + imag * imag)
            mags[i] = magnitude
            if (magnitude > frameMax) frameMax = magnitude
        }
        if (frameMax < 1.6) {
            for (i in 0 until n) fftBuffer[i] = 0f
            eventSink?.success(fftBuffer.toList().subList(0, n))
            return
        }
        runningMax = if (frameMax > runningMax) frameMax else runningMax * 0.94
        val gainRef = runningMax.coerceAtLeast(4.0)
        for (i in 0 until n) {
            val start = ((i.toDouble() / n) * sourceBins).toInt().coerceIn(0, sourceBins - 1)
            val end = ((((i + 1).toDouble() / n) * sourceBins).toInt() + 1).coerceIn(start + 1, sourceBins)
            var peak = 0.0
            var sum = 0.0
            for (j in start until end) {
                peak = maxOf(peak, mags[j])
                sum += mags[j]
            }
            val avg = sum / (end - start)
            val normalized = ((peak * 0.7 + avg * 0.3) / gainRef)
            fftBuffer[i] = normalized.toFloat().coerceIn(0f, 1f)
        }
        eventSink?.success(fftBuffer.toList().subList(0, n))
    }

    private fun stopVisualizer() {
        try {
            visualizer?.apply { enabled = false; release() }
            visualizer = null
        } catch (_: Exception) {}
    }

    fun destroy() {
        stopVisualizer()
        methodChannel.setMethodCallHandler(null)
        // Keep the EventChannel handler registered until Flutter disposes the
        // engine. Removing it here makes a Dart subscription cancellation race
        // with activity teardown and can surface MissingPluginException.
    }
}
