package com.parkingmudde.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

class UrgentAlertOverlayService : Service() {
    companion object {
        private const val SERVICE_CHANNEL_ID = "parking_mudde_overlay_service_v1"
        private const val SERVICE_NOTIFICATION_ID = 94121
        private const val OVERLAY_TIMEOUT_MS = 120_000L

        private const val EXTRA_TYPE = "type"
        private const val EXTRA_STATUS = "status"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_BODY = "body"
        private const val EXTRA_VEHICLE = "vehicle_number"
        private const val EXTRA_NOTIFICATION_ID = "notification_id"
        private const val EXTRA_REPORT_ID = "report_id"
        private const val EXTRA_CALL_ID = "call_id"
        const val EXTRA_FROM_OVERLAY = "parking_mudde_overlay"
        private var activeService: UrgentAlertOverlayService? = null

        fun dismissCallOverlay(callId: String) {
            val service = activeService ?: return
            if (callId.isNotBlank() && service.activeCallId == callId) service.dismissOverlay()
        }

        private fun callExpiry(data: Map<String, String>): Long? = try {
            java.time.Instant.parse(data["expires_at"]).toEpochMilli()
        } catch (_: Exception) { null }

        fun isUrgent(data: Map<String, String>): Boolean {
            val type = data[EXTRA_TYPE]?.uppercase().orEmpty()
            val status = data[EXTRA_STATUS]?.uppercase().orEmpty()
            if (type == "IN_APP_CALL") {
                return status == "RINGING" && !data[EXTRA_CALL_ID].isNullOrBlank() &&
                    !data["call_token"].isNullOrBlank() &&
                    (callExpiry(data) ?: Long.MAX_VALUE) > System.currentTimeMillis()
            }
            return (type == "VEHICLE_REPORTED_AGAINST_YOU" && status == "SUBMITTED") ||
                (type in setOf("HELP_ALERT", "HELP_VEHICLE") &&
                    status in setOf("", "IN_PROGRESS")) ||
                (type == "EMERGENCY_ALERT" && status == "SUBMITTED")
        }

        fun intentFor(context: Context, data: Map<String, String>): Intent =
            Intent(context, UrgentAlertOverlayService::class.java).apply {
                data.forEach { (key, value) -> putExtra(key, value) }
            }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var activeCallId: String? = null

    override fun onCreate() {
        super.onCreate()
        activeService = this
        createServiceChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(SERVICE_NOTIFICATION_ID, serviceNotification(intent))

        if (intent == null ||
            (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this))
        ) {
            stopSelf()
            return START_NOT_STICKY
        }

        activeCallId = intent.getStringExtra(EXTRA_CALL_ID)
        showOverlay(intent)
        handler.removeCallbacksAndMessages(null)
        val timeout = if (intent.getStringExtra(EXTRA_TYPE)?.uppercase() == "IN_APP_CALL") {
            val expiresAt = callExpiry(mapOf("expires_at" to intent.getStringExtra("expires_at").orEmpty()))
            ((expiresAt ?: (System.currentTimeMillis() + 90_000L)) - System.currentTimeMillis())
                .coerceIn(0L, 90_000L)
        } else OVERLAY_TIMEOUT_MS
        handler.postDelayed({ dismissOverlay() }, timeout)
        return START_NOT_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        removeOverlay()
        if (activeService === this) activeService = null
        super.onDestroy()
    }

    private fun showOverlay(intent: Intent) {
        removeOverlay()

        val type = intent.getStringExtra(EXTRA_TYPE)?.uppercase().orEmpty()
        val isHelp = type == "HELP_ALERT" || type == "HELP_VEHICLE"
        val isEmergency = type == "EMERGENCY_ALERT"
        val isCall = type == "IN_APP_CALL"
        val background = when {
            isCall -> Color.rgb(24, 75, 140)
            isHelp -> Color.rgb(32, 196, 117)
            isEmergency -> Color.rgb(185, 28, 28)
            else -> Color.rgb(229, 62, 62)
        }
        val title = intent.getStringExtra(EXTRA_TITLE).takeUnless { it.isNullOrBlank() }
            ?: when {
                isCall -> "Incoming Private Call"
                isHelp -> "Someone Is Helping!"
                isEmergency -> "Emergency Alert"
                else -> "Your Car Is Being Reported"
            }
        val body = intent.getStringExtra(EXTRA_BODY).takeUnless { it.isNullOrBlank() }
            ?: "Open Parking Mudde for details."
        val vehicle = intent.getStringExtra(EXTRA_VEHICLE).orEmpty()

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(48), dp(24), dp(32))
            setBackgroundColor(background)
            systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                    View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                )
        }

        root.addView(textView(if (isCall) "☎" else if (isHelp) "♥" else "!", 76f, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
        }, LinearLayout.LayoutParams(-1, 0, 1f))
        root.addView(textView(title, 32f, Typeface.BOLD).apply {
            gravity = Gravity.CENTER
        }, marginParams(top = 12))

        if (vehicle.isNotBlank()) {
            root.addView(textView(vehicle, 24f, Typeface.BOLD).apply {
                gravity = Gravity.CENTER
                letterSpacing = 0.12f
                setPadding(dp(16), dp(12), dp(16), dp(12))
                setBackgroundColor(Color.argb(45, 255, 255, 255))
            }, marginParams(top = 24))
        }

        root.addView(textView(body, 20f, Typeface.NORMAL).apply {
            gravity = Gravity.CENTER
        }, marginParams(top = 28, weight = 1f))

        root.addView(Button(this).apply {
            text = if (isCall) "ANSWER" else "OPEN PARKING MUDDE"
            textSize = 18f
            setTextColor(background)
            setBackgroundColor(Color.WHITE)
            setTypeface(typeface, Typeface.BOLD)
            setOnClickListener {
                if (isCall) {
                    intent.putExtra("call_action", "answer")
                    text = "CONNECTING…"
                    for (index in 0 until root.childCount) {
                        (root.getChildAt(index) as? Button)?.isEnabled = false
                    }
                }
                openApp(intent)
            }
        }, LinearLayout.LayoutParams(-1, dp(60)).apply { topMargin = dp(24) })

        root.addView(Button(this).apply {
            text = if (isCall) "DECLINE" else "DISMISS"
            textSize = 15f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.TRANSPARENT)
            setOnClickListener {
                if (isCall) {
                    isEnabled = false
                    text = "DECLINING…"
                    declineCall(intent) { success ->
                        if (success) dismissOverlay() else {
                            isEnabled = true
                            text = "RETRY DECLINE"
                        }
                    }
                } else dismissOverlay()
            }
        }, LinearLayout.LayoutParams(-1, dp(52)).apply { topMargin = dp(8) })

        val windowType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            windowType,
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            PixelFormat.TRANSLUCENT,
        ).apply { gravity = Gravity.TOP or Gravity.START }

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        overlayView = root
        windowManager?.addView(root, params)
    }

    private fun openApp(source: Intent) {
        val launch = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            source.extras?.let { putExtras(it) }
            putExtra(EXTRA_FROM_OVERLAY, true)
        }
        if (launch != null) startActivity(launch)
        // Keep the native call UI visible across engine startup. Flutter
        // dismisses this exact call's overlay as its call screen is created.
        val answering = source.getStringExtra(EXTRA_TYPE)?.uppercase() == "IN_APP_CALL" &&
            source.getStringExtra("call_action") == "answer"
        if (!answering || launch == null) dismissOverlay()
    }

    private fun declineCall(source: Intent, complete: (Boolean) -> Unit) {
        val backend = getSharedPreferences("call_settings", MODE_PRIVATE)
            .getString("backend_url", null)
        if (backend == null) {
            source.putExtra("call_action", "decline")
            openApp(source)
            return
        }
        val callId = source.getStringExtra(EXTRA_CALL_ID).orEmpty()
        val token = source.getStringExtra("call_token").orEmpty()
        Thread {
            var connection: HttpURLConnection? = null
            val success = try {
                val encodedId = URLEncoder.encode(callId, "UTF-8")
                connection = URL("$backend/v1/calls/$encodedId/reject").openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.connectTimeout = 8_000
                connection.readTimeout = 8_000
                connection.instanceFollowRedirects = false
                connection.setRequestProperty("x-call-token", token)
                connection.setRequestProperty("Content-Type", "application/json")
                connection.doOutput = true
                connection.outputStream.use { it.write("{\"reason\":\"declined\"}".toByteArray()) }
                connection.responseCode in 200..299 || connection.responseCode == 409
            } catch (_: Exception) { false }
            finally { connection?.disconnect() }
            handler.post {
                if (success) {
                    source.getStringExtra(EXTRA_NOTIFICATION_ID)?.toIntOrNull()?.let {
                        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancel(it)
                    }
                }
                complete(success)
            }
        }.start()
    }

    private fun dismissOverlay() {
        removeOverlay()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    private fun removeOverlay() {
        val view = overlayView ?: return
        try {
            windowManager?.removeView(view)
        } catch (_: Exception) {
            // The system may already have removed the window.
        }
        overlayView = null
    }

    private fun serviceNotification(intent: Intent?): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, SERVICE_CHANNEL_ID)
            .setSmallIcon(applicationInfo.icon)
            .setContentTitle(intent?.getStringExtra(EXTRA_TITLE) ?: "Parking Mudde urgent alert")
            .setContentText("An urgent vehicle alert is displayed on screen.")
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createServiceChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(
            NotificationChannel(
                SERVICE_CHANNEL_ID,
                "Urgent alert overlay service",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Keeps a requested urgent safety alert visible over other apps."
                setSound(null, null)
                enableVibration(false)
            }
        )
    }

    private fun textView(value: String, size: Float, style: Int) = TextView(this).apply {
        text = value
        textSize = size
        setTextColor(Color.WHITE)
        setTypeface(typeface, style)
    }

    private fun marginParams(top: Int = 0, weight: Float = 0f) =
        LinearLayout.LayoutParams(-1, if (weight > 0f) 0 else -2, weight).apply {
            topMargin = dp(top)
        }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
