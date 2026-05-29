package com.example.caller

import android.content.Intent
import android.net.Uri
import android.telecom.TelecomManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.caller/direct_call"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "callNumberWithSpeakerphone") {
                val phoneNumber = call.argument<String>("phoneNumber")
                if (phoneNumber != null) {
                    val success = makeDirectCall(phoneNumber)
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("CALL_FAILED", "Could not start phone call", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "Phone number is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun makeDirectCall(phoneNumber: String): Boolean {
        return try {
            val intent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$phoneNumber")
                putExtra(TelecomManager.EXTRA_START_CALL_WITH_SPEAKERPHONE, true)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
