package com.parkingmudde.app

import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.content.Intent
import android.net.Uri
import android.view.WindowManager
import com.razorpay.Checkout
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val installStateChannel = "com.parkingmudde.app/install_state"
    private val urgentOverlayChannel = "com.parkingmudde.app/urgent_overlay"
    private var overlayChannel: MethodChannel? = null
    private var pendingLaunchCall: Map<String, String>? = null

    private fun consumeLaunchCall(): Map<String, String>? {
        val source = intent ?: return null
        val data = consumeOverlayAlert(consume = false)?.toMutableMap()
            ?: source.getStringExtra("payload")?.let { payload ->
                try {
                    val json = JSONObject(payload)
                    json.keys().asSequence().associateWith { json.optString(it) }.toMutableMap()
                } catch (_: Exception) { null }
            }
            ?: source.extras?.keySet()?.mapNotNull { key ->
                (source.extras?.get(key) as? String)?.let { key to it }
            }?.toMap()?.toMutableMap()
            ?: return null
        if (data["type"]?.uppercase() != "IN_APP_CALL" || !UrgentAlertOverlayService.isUrgent(data)) return null
        val action = source.getStringExtra("actionId")
        if (action in setOf("answer", "decline")) data["call_action"] = action!!
        source.removeExtra("payload")
        source.removeExtra(UrgentAlertOverlayService.EXTRA_FROM_OVERLAY)
        source.removeExtra("type")
        return data
    }

    private fun consumeOverlayAlert(consume: Boolean = true): Map<String, String>? {
        val source = intent ?: return null
        if (!source.getBooleanExtra(UrgentAlertOverlayService.EXTRA_FROM_OVERLAY, false)) return null
        if (consume) source.removeExtra(UrgentAlertOverlayService.EXTRA_FROM_OVERLAY)
        return source.extras?.keySet()?.mapNotNull { key ->
            (source.extras?.get(key) as? String)?.let { key to it }
        }?.toMap()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingLaunchCall = consumeLaunchCall()
        (pendingLaunchCall ?: consumeOverlayAlert(consume = false))?.let {
            overlayChannel?.invokeMethod("openAlert", it)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, installStateChannel).setMethodCallHandler { call, result ->
            if (call.method == "getInstallState") {
                val markerDir = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    noBackupFilesDir
                } else {
                    filesDir
                }
                val markerFile = File(markerDir, "parkingmudde_install_marker")
                val hadMarker = markerFile.exists()
                if (!hadMarker) {
                    markerDir.mkdirs()
                    markerFile.writeText(System.currentTimeMillis().toString())
                }
                val packageInfo = packageManager.getPackageInfo(packageName, 0)
                result.success(
                    mapOf(
                        "had_marker" to hadMarker,
                        "is_fresh_package_install" to (packageInfo.firstInstallTime == packageInfo.lastUpdateTime)
                    )
                )
            } else if (call.method == "getAppVersion") {
                val packageInfo = packageManager.getPackageInfo(packageName, 0)
                val versionCode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    packageInfo.longVersionCode
                } else {
                    @Suppress("DEPRECATION")
                    val legacyVersionCode = packageInfo.versionCode.toLong()
                    legacyVersionCode
                }
                result.success(
                    mapOf(
                        "version" to (packageInfo.versionName ?: ""),
                        "build" to versionCode
                    )
                )
            } else {
                result.notImplemented()
            }
        }
        overlayChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, urgentOverlayChannel)
        overlayChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "dismissCallOverlay" -> {
                    UrgentAlertOverlayService.dismissCallOverlay(call.argument<String>("call_id").orEmpty())
                    result.success(null)
                }
                "getLaunchCall" -> {
                    result.success(pendingLaunchCall ?: consumeLaunchCall())
                    pendingLaunchCall = null
                }
                "configureCallBackend" -> {
                    val url = call.argument<String>("url").orEmpty()
                    if (Uri.parse(url).scheme == "https") {
                        getSharedPreferences("call_settings", MODE_PRIVATE).edit()
                            .putString("backend_url", url.trimEnd('/')).apply()
                    }
                    result.success(null)
                }
                "getPendingAlert" -> result.success(consumeOverlayAlert())
                "canDrawOverlays" -> {
                    result.success(
                        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                            Settings.canDrawOverlays(this)
                    )
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
                        !Settings.canDrawOverlays(this)
                    ) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
        val launchingCall = intent?.getStringExtra("type")?.uppercase() == "IN_APP_CALL" ||
            try {
                JSONObject(intent?.getStringExtra("payload").orEmpty())
                    .optString("type").uppercase() == "IN_APP_CALL"
            } catch (_: Exception) { false }
        if (!launchingCall) Checkout.preload(applicationContext)
    }
}
