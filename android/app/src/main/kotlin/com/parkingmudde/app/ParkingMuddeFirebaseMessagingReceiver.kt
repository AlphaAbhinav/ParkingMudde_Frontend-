package com.parkingmudde.app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.RemoteMessage
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingReceiver

class ParkingMuddeFirebaseMessagingReceiver : FlutterFirebaseMessagingReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val extras = intent.extras
        if (extras != null) {
            val message = RemoteMessage(extras)
            val data = message.data
            val overlayAllowed =
                Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)

            if (overlayAllowed &&
                !isAppInForeground(context) &&
                UrgentAlertOverlayService.isUrgent(data)
            ) {
                val serviceIntent = UrgentAlertOverlayService.intentFor(context, data)
                try {
                    ContextCompat.startForegroundService(context, serviceIntent)
                } catch (_: Exception) {
                    // Flutter's full-screen notification remains the fallback.
                }
            }
        }

        // Preserve FlutterFire delivery for foreground listeners and the Dart
        // background handler that creates the lock-screen notification.
        super.onReceive(context, intent)
    }

    private fun isAppInForeground(context: Context): Boolean {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return manager.runningAppProcesses?.any { process ->
            process.processName == context.packageName &&
                process.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        } == true
    }
}
