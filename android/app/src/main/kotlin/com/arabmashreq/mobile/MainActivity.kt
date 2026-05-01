package com.arabmashreq.mobile

import android.content.Intent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ensureBreakingNewsChannel()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SHARE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareText" -> {
                    val text = call.argument<String>("text").orEmpty()
                    val subject = call.argument<String>("subject").orEmpty()

                    if (text.isBlank()) {
                        result.error("INVALID_ARGUMENT", "text is required", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                            if (subject.isNotBlank()) {
                                putExtra(Intent.EXTRA_SUBJECT, subject)
                            }
                        }
                        startActivity(Intent.createChooser(shareIntent, null))
                        result.success(true)
                    } catch (error: Exception) {
                        result.error("SHARE_ERROR", error.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun ensureBreakingNewsChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return

        val channel = NotificationChannel(
            BREAKING_NEWS_CHANNEL_ID,
            BREAKING_NEWS_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = BREAKING_NEWS_CHANNEL_DESCRIPTION
            enableVibration(true)
            val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            val audioAttributes = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            setSound(soundUri, audioAttributes)
        }

        notificationManager.createNotificationChannel(channel)
    }

    companion object {
        private const val SHARE_CHANNEL = "com.arabmashreq.mobile/share"
        private const val BREAKING_NEWS_CHANNEL_ID = "arabmashreq_breaking_v2"
        private const val BREAKING_NEWS_CHANNEL_NAME = "Breaking News"
        private const val BREAKING_NEWS_CHANNEL_DESCRIPTION = "Urgent and breaking news alerts"
    }
}

