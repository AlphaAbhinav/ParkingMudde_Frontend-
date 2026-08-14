package com.parkingmudde.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import io.flutter.app.FlutterApplication

class ParkingMuddeApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val customPushChannelId = "parking_mudde_loop_alert_tone_v1"

        listOf(
            "parking_mudde_alerts",
            "parking_mudde_alerts_v2",
            "parking_mudde_alerts_v3",
            "parking_mudde_alerts_v4",
            "parking_mudde_contact_otp",
            "parking_mudde_loud_push_v1",
            "parking_mudde_alarm_push_v1",
            "parking_mudde_custom_push_v1",
            "parking_mudde_final_alert_tone_v1",
            "parking_mudde_full_screen_alerts_v3",
            "parking_mudde_full_screen_alerts_v4",
            "parking_mudde_full_screen_alerts_v5",
            "parking_mudde_full_screen_alerts_v6",
            "parking_mudde_full_screen_alerts_v7",
            "parking_mudde_full_screen_alerts_v8",
            "parking_mudde_full_screen_alerts_v9",
            "parking_mudde_full_screen_alerts_v10",
            "parking_mudde_full_screen_alerts_v11"
        ).forEach { manager.deleteNotificationChannel(it) }

        NotificationSoundProvider.prepareSoundFile(this)
        val alertSoundUri = NotificationSoundProvider.soundUri(this)
        val alertAudioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val loudPushChannel = NotificationChannel(
            customPushChannelId,
            "Parking Mudde Loop Alert Tone",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "All Parking Mudde push notifications with a looping alert tone."
            enableVibration(true)
            vibrationPattern = longArrayOf(0, 650, 180, 650)
            setSound(alertSoundUri, alertAudioAttributes)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setShowBadge(true)
        }

        manager.createNotificationChannel(loudPushChannel)
    }
}
