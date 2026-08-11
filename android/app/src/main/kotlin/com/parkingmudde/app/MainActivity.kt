package com.parkingmudde.app

import android.os.Build
import android.os.Bundle
import com.razorpay.Checkout
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val installStateChannel = "com.parkingmudde.app/install_state"

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
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Checkout.preload(applicationContext)
    }
}
