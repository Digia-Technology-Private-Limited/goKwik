package com.example.gokwik

import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class UpiAppCheckerPlugin : FlutterPlugin {
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "upi_app_checker")
        channel.setMethodCallHandler { call, result ->
            if (call.method == "isAppInstalled") {
                val packageName = call.argument<String>("packageName")
                if (packageName == null) {
                    result.error("INVALID_ARGUMENT", "packageName is required", null)
                    return@setMethodCallHandler
                }
                try {
                    val pm = binding.applicationContext.packageManager
                    pm.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
                    result.success(true)
                } catch (e: PackageManager.NameNotFoundException) {
                    result.success(false)
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
