package com.example.gym_app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.sin

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL_NAME = "com.example.gym_app/rest_timer"
        private const val NOTIFICATION_CHANNEL_ID = "rest_timer_channel"
        private const val NOTIFICATION_CHANNEL_NAME = "Temporizador de descanso"
        private const val NOTIFICATION_ID = 4201
        private const val REQUEST_CODE_POST_NOTIFICATIONS = 4202
        private const val ACTION_BROADCAST = "com.example.gym_app.REST_TIMER_ACTION"
        private const val EXTRA_ACTION = "timer_action"

        private const val ACTION_SUB_20 = "sub20"
        private const val ACTION_ADD_20 = "add20"
        private const val ACTION_STOP = "stop"
        private const val ACTION_COMPLETED = "completed"
    }

    private var methodChannel: MethodChannel? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var isReceiverRegistered = false

    private val mainHandler = Handler(Looper.getMainLooper())
    private var isTimerActive = false
    private var isTimerPaused = false
    private var totalSeconds = 90
    private var remainingSeconds = 0
    private var lastDisplayedSeconds = -1
    private var endElapsedRealtimeMs = 0L
    private var soundEnabled = true
    private var vibrationEnabled = true
    private var currentExerciseName: String? = null

    private val tickerRunnable = object : Runnable {
        override fun run() {
            if (!isTimerActive || isTimerPaused) return

            val computed = computeRemainingSeconds()
            if (computed <= 0) {
                remainingSeconds = 0
                lastDisplayedSeconds = 0
                isTimerActive = false
                cancelNotification()
                playCompletionFeedback(soundEnabled, vibrationEnabled)
                dispatchActionToFlutter(ACTION_COMPLETED)
                return
            }

            if (computed != lastDisplayedSeconds) {
                remainingSeconds = computed
                renderNotification()
            }
            mainHandler.postDelayed(this, 500L)
        }
    }

    private val notificationActionReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.getStringExtra(EXTRA_ACTION) ?: return
            handleNotificationButtonAction(action)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        registerNotificationReceiver()

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        methodChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> handleRequestPermission(result)
                "showOrUpdateTimer" -> {
                    val remaining = call.argument<Int>("remainingSeconds") ?: 0
                    val total = call.argument<Int>("totalSeconds") ?: remaining
                    val paused = call.argument<Boolean>("isPaused") ?: false
                    val sound = call.argument<Boolean>("soundEnabled") ?: true
                    val vibrate = call.argument<Boolean>("vibrationEnabled") ?: true
                    val exercise = call.argument<String>("exerciseName")
                    showOrUpdateTimer(remaining, total, paused, sound, vibrate, exercise)
                    result.success(null)
                }
                "cancelTimer" -> {
                    stopNativeTimer(cancelNotif = true)
                    result.success(null)
                }
                "playCompletionFeedback" -> {
                    val playSound = call.argument<Boolean>("playSound") ?: true
                    val vibrate = call.argument<Boolean>("vibrate") ?: true
                    stopNativeTimer(cancelNotif = true)
                    playCompletionFeedback(playSound, vibrate)
                    result.success(null)
                }
                "vibrateLight" -> {
                    vibratePattern(longArrayOf(0L, 18L))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        hideSystemNavigationBar()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            hideSystemNavigationBar()
        }
    }

    private fun hideSystemNavigationBar() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.navigationBars())
                controller.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
            )
        }
    }

    override fun onDestroy() {
        stopNativeTimer(cancelNotif = true)
        unregisterNotificationReceiver()
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        super.onDestroy()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_POST_NOTIFICATIONS) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun handleRequestPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            result.success(true)
            return
        }
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        pendingPermissionResult?.success(false)
        pendingPermissionResult = result
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            REQUEST_CODE_POST_NOTIFICATIONS,
        )
    }

    private fun hasNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun registerNotificationReceiver() {
        if (isReceiverRegistered) return
        val filter = IntentFilter(ACTION_BROADCAST)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(notificationActionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(notificationActionReceiver, filter)
        }
        isReceiverRegistered = true
    }

    private fun unregisterNotificationReceiver() {
        if (!isReceiverRegistered) return
        try {
            unregisterReceiver(notificationActionReceiver)
        } catch (_: IllegalArgumentException) {
            // Ignorado si ya no estaba registrado.
        }
        isReceiverRegistered = false
    }

    private fun showOrUpdateTimer(
        remaining: Int,
        total: Int,
        paused: Boolean,
        sound: Boolean,
        vibrate: Boolean,
        exerciseName: String?,
    ) {
        if (remaining <= 0) {
            stopNativeTimer(cancelNotif = true)
            return
        }

        mainHandler.removeCallbacks(tickerRunnable)
        isTimerActive = true
        isTimerPaused = paused
        remainingSeconds = remaining
        totalSeconds = maxOf(total, remaining, 1)
        soundEnabled = sound
        vibrationEnabled = vibrate
        currentExerciseName = exerciseName?.takeIf { it.isNotBlank() }
        endElapsedRealtimeMs = SystemClock.elapsedRealtime() + remaining * 1000L

        renderNotification()
        if (!paused) {
            mainHandler.postDelayed(tickerRunnable, 500L)
        }
    }

    private fun stopNativeTimer(cancelNotif: Boolean) {
        mainHandler.removeCallbacks(tickerRunnable)
        isTimerActive = false
        isTimerPaused = false
        remainingSeconds = 0
        lastDisplayedSeconds = -1
        if (cancelNotif) {
            cancelNotification()
        }
    }

    private fun handleNotificationButtonAction(action: String) {
        when (action) {
            ACTION_STOP -> {
                vibratePattern(longArrayOf(0L, 18L))
                stopNativeTimer(cancelNotif = true)
                dispatchActionToFlutter(ACTION_STOP)
            }
            ACTION_SUB_20 -> adjustFromNotification(-20, ACTION_SUB_20)
            ACTION_ADD_20 -> adjustFromNotification(20, ACTION_ADD_20)
        }
    }

    private fun adjustFromNotification(deltaSeconds: Int, actionKey: String) {
        vibratePattern(longArrayOf(0L, 18L))
        val current = if (isTimerPaused) remainingSeconds else computeRemainingSeconds()
        val updated = current + deltaSeconds

        if (updated <= 0) {
            stopNativeTimer(cancelNotif = true)
            dispatchActionToFlutter(actionKey)
            return
        }

        mainHandler.removeCallbacks(tickerRunnable)
        remainingSeconds = updated
        totalSeconds = maxOf(totalSeconds, updated, 1)
        endElapsedRealtimeMs = SystemClock.elapsedRealtime() + updated * 1000L
        renderNotification()
        if (!isTimerPaused) {
            mainHandler.postDelayed(tickerRunnable, 500L)
        }
        dispatchActionToFlutter(actionKey)
    }

    private fun dispatchActionToFlutter(action: String) {
        mainHandler.post {
            methodChannel?.invokeMethod("onNotificationAction", mapOf("action" to action))
        }
    }

    private fun computeRemainingSeconds(): Int {
        val diffMs = endElapsedRealtimeMs - SystemClock.elapsedRealtime()
        if (diffMs <= 0L) return 0
        return ((diffMs + 999L) / 1000L).toInt()
    }

    private fun ensureNotificationChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            NOTIFICATION_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Muestra el tiempo restante de descanso y controles rápidos (-20s, +20s, Terminar)"
            setSound(null, null)
            enableVibration(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        manager.createNotificationChannel(channel)
    }

    private fun renderNotification() {
        if (!hasNotificationPermission()) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureNotificationChannel(manager)

        val formatted = formatSeconds(remainingSeconds)
        val statusPrefix = if (isTimerPaused) "En pausa" else "Descanso activo"
        val title = "$statusPrefix · $formatted"
        val body = currentExerciseName?.let { "$it · Ajusta o termina desde aquí" }
            ?: "Recuperación entre series · Controles rápidos"

        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentFlags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        val contentPendingIntent = PendingIntent.getActivity(this, 0, openAppIntent, contentFlags)

        val statIconRes = resources
            .getIdentifier("ic_stat_progressive", "drawable", packageName)
            .takeIf { it != 0 }
            ?: applicationInfo.icon.takeIf { it != 0 }
            ?: android.R.drawable.ic_lock_idle_alarm

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, NOTIFICATION_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        val maxProgress = maxOf(totalSeconds, 1)
        val elapsedProgress = (maxProgress - remainingSeconds).coerceIn(0, maxProgress)

        builder
            .setSmallIcon(statIconRes)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setColor(0xFF448AFF.toInt())
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setProgress(maxProgress, elapsedProgress, false)
            .setContentIntent(contentPendingIntent)
            .addAction(buildNotificationAction("-20s", ACTION_SUB_20, 1))
            .addAction(buildNotificationAction("+20s", ACTION_ADD_20, 2))
            .addAction(buildNotificationAction("Terminar", ACTION_STOP, 3))

        lastDisplayedSeconds = remainingSeconds
        manager.notify(NOTIFICATION_ID, builder.build())
    }

    @Suppress("DEPRECATION")
    private fun buildNotificationAction(
        label: String,
        actionKey: String,
        requestCode: Int,
    ): Notification.Action {
        val intent = Intent(ACTION_BROADCAST).apply {
            setPackage(packageName)
            putExtra(EXTRA_ACTION, actionKey)
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        val pendingIntent = PendingIntent.getBroadcast(this, requestCode, intent, flags)
        return Notification.Action.Builder(0, label, pendingIntent).build()
    }

    private fun cancelNotification() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(NOTIFICATION_ID)
    }

    private fun formatSeconds(secs: Int): String {
        val safe = secs.coerceAtLeast(0)
        val minutes = safe / 60
        val seconds = safe % 60
        return String.format("%02d:%02d", minutes, seconds)
    }

    private fun playCompletionFeedback(playSound: Boolean, vibrate: Boolean) {
        if (vibrate) {
            // Patrón doble perceptible en el bolsillo sin resultar molesto.
            vibratePattern(longArrayOf(0L, 200L, 100L, 280L))
        }
        if (playSound) {
            Thread { playSubtleGymChime() }.start()
        }
    }

    private fun vibratePattern(pattern: LongArray) {
        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        } ?: return

        if (!vibrator.hasVibrator()) return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (pattern.size == 2 && pattern[0] == 0L) {
                vibrator.vibrate(
                    VibrationEffect.createOneShot(pattern[1], VibrationEffect.DEFAULT_AMPLITUDE),
                )
            } else {
                vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
            }
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
    }

    /**
     * Genera un acorde suave de dos notas (528 Hz -> 660 Hz) usando
     * USAGE_ASSISTANCE_SONIFICATION sin pedir AudioFocus para no cortar
     * la música que el usuario esté escuchando en segundo plano.
     */
    private fun playSubtleGymChime() {
        val sampleRate = 22050
        val totalSamples = (sampleRate * 0.42).toInt()
        val splitSample = (sampleRate * 0.17).toInt()
        val pcm = ShortArray(totalSamples)

        for (i in 0 until totalSamples) {
            val isSecondNote = i >= splitSample
            val noteIndex = if (isSecondNote) i - splitSample else i
            val noteLength = if (isSecondNote) totalSamples - splitSample else splitSample
            val freq = if (isSecondNote) 660.0 else 528.0
            val phase = 2.0 * PI * freq * noteIndex / sampleRate

            // Envolvente suave tipo campana (ataque corto y decaimiento progresivo).
            val norm = noteIndex.toDouble() / noteLength.coerceAtLeast(1)
            val attack = (noteIndex / (sampleRate * 0.015)).coerceIn(0.0, 1.0)
            val decay = (1.0 - norm) * (1.0 - norm)
            val sample = sin(phase) * attack * decay * 0.18
            pcm[i] = (sample * Short.MAX_VALUE).toInt()
                .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
                .toShort()
        }

        var track: AudioTrack? = null
        try {
            val bufferBytes = pcm.size * 2
            track = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                AudioTrack.Builder()
                    .setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ASSISTANCE_SONIFICATION)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build(),
                    )
                    .setAudioFormat(
                        AudioFormat.Builder()
                            .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                            .setSampleRate(sampleRate)
                            .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                            .build(),
                    )
                    .setBufferSizeInBytes(bufferBytes)
                    .setTransferMode(AudioTrack.MODE_STATIC)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                AudioTrack(
                    AudioManager.STREAM_NOTIFICATION,
                    sampleRate,
                    AudioFormat.CHANNEL_OUT_MONO,
                    AudioFormat.ENCODING_PCM_16BIT,
                    bufferBytes,
                    AudioTrack.MODE_STATIC,
                )
            }

            track.write(pcm, 0, pcm.size)
            track.play()
            Thread.sleep(460L)
        } catch (_: Throwable) {
            // Si el sistema bloquea la salida de audio, solo prevalece la vibración.
        } finally {
            try {
                track?.stop()
                track?.release()
            } catch (_: Throwable) {
            }
        }
    }
}
