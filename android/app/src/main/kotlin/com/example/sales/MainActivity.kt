// package com.techfifo.sales

// import android.Manifest
// import android.content.Intent
// import android.content.pm.PackageManager
// import android.net.Uri
// import android.os.Build
// import android.os.Bundle
// import androidx.core.app.ActivityCompat
// import io.flutter.embedding.android.FlutterActivity
// import io.flutter.embedding.engine.FlutterEngine
// import io.flutter.plugin.common.MethodChannel

// class MainActivity : FlutterActivity() {
//     private val CHANNEL = "custom.dialer/launch"

//     override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//         super.configureFlutterEngine(flutterEngine)

//         MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
//             if (call.method == "launchDialer") {
//                 val number = call.argument<String>("number")
//                 val intent = Intent(Intent.ACTION_CALL)
//                 intent.data = Uri.parse("tel:$number")

//                 // Check permission
//                 if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
//                     result.error("PERMISSION_DENIED", "CALL_PHONE permission not granted", null)
//                     return@setMethodCallHandler
//                 }

//                 if (intent.resolveActivity(packageManager) != null) {
//                     startActivity(intent)
//                     result.success(true)
//                 } else {
//                     result.error("UNAVAILABLE", "No dialer found", null)
//                 }
//             } else {
//                 result.notImplemented()
//             }
//         }
//     }
// }
package com.techfifo.sales

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "mic_service_channel"
    private val RECORD_AUDIO_REQUEST_CODE = 100

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestRecordAudioPermission()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startMicStream" -> {
                        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) {
                            val intent = Intent(this, MicStreamService::class.java)
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(intent)
                            } else {
                                startService(intent)
                            }
                            result.success("Mic stream started")
                        } else {
                            result.error("PERMISSION_DENIED", "Record audio permission not granted", null)
                        }
                    }

                    "stopMicStream" -> {
                        val intent = Intent(this, MicStreamService::class.java)
                        stopService(intent)
                        result.success("Mic stream stopped")
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun requestRecordAudioPermission() {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.RECORD_AUDIO),
                RECORD_AUDIO_REQUEST_CODE
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == RECORD_AUDIO_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Optional: Notify Flutter side if needed
            }
        }
    }
}