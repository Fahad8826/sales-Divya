package com.techfifo.sales

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "custom.dialer/launch"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchDialer") {
                val number = call.argument<String>("number")
                val intent = Intent(Intent.ACTION_CALL)
                intent.data = Uri.parse("tel:$number")

                // Check permission
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
                    result.error("PERMISSION_DENIED", "CALL_PHONE permission not granted", null)
                    return@setMethodCallHandler
                }

                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    result.success(true)
                } else {
                    result.error("UNAVAILABLE", "No dialer found", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
