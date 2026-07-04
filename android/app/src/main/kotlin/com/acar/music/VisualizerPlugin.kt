package com.acar.music

import android.media.audiofx.Visualizer
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference
import kotlin.math.sqrt
import kotlin.math.log10

class VisualizerPlugin(
    private val activity: WeakReference<MainActivity>,
    private val flutterEngine: FlutterEngine
) {
    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var listener: Visualizer.OnDataCaptureListener? = null
    private val CHANNEL = "com.acar.music/visualizer"
    private val FFT_CHANNEL = "com.acar.music/visualizer_fft"

    private val methodChannel: MethodChannel
    private val eventChannel: EventChannel

    private val fftBuffer = FloatArray(64)

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
                startVisualizer(sessionId)
                result.success(true)
            }
            "stopVisualizer" -> {
                stopVisualizer()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun startVisualizer(sessionId: Int) {
        stopVisualizer()
        try {
            val viz = Visualizer(sessionId)
            viz.enabled = false
            viz.setCaptureSize(256)

            listener = object : Visualizer.OnDataCaptureListener {
                override fun onWaveFormDataCapture(
                    visualizer: Visualizer?, waveform: ByteArray?, samplingRate: Int
                ) {}

                override fun onFftDataCapture(
                    visualizer: Visualizer?, fft: ByteArray?, samplingRate: Int
                ) {
                    processFft(fft)
                }
            }

            val captureRate = Visualizer.getMaxCaptureRate()
            viz.setDataCaptureListener(listener, captureRate, false, true)
            viz.enabled = true
            visualizer = viz
        } catch (e: Exception) {
            // sin visualizer nativo — Dart cae a simulado
        }
    }

    private var runningMax = 1.0

    private fun processFft(fft: ByteArray?) {
        if (fft == null || eventSink == null) return
        val n = minOf(fft.size / 2, fftBuffer.size)
        val mags = DoubleArray(n)
        var frameMax = 0.0

        for (i in 0 until n) {
            val real = fft[i * 2].toDouble()
            val imag = fft[i * 2 + 1].toDouble()
            val magnitude = sqrt(real * real + imag * imag)
            mags[i] = magnitude
            if (magnitude > frameMax) frameMax = magnitude
        }

        runningMax = if (frameMax > runningMax) frameMax else runningMax * 0.95
        val gainRef = runningMax.coerceAtLeast(2.0) // floor bajo, no ahoga señal débil

        for (i in 0 until n) {
            fftBuffer[i] = (mags[i] / gainRef).toFloat().coerceIn(0f, 1f)
        }

        val data = FloatArray(n)
        System.arraycopy(fftBuffer, 0, data, 0, n)
        eventSink?.success(data.toList())
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
        eventChannel.setStreamHandler(null)
    }
}