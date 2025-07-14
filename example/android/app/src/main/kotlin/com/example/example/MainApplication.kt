package com.example.example

import android.app.Application
import io.flutter.app.FlutterApplication;
import com.webengage.webengage_plugin.WebengageInitializer;
import com.webengage.sdk.android.WebEngageConfig;
import com.webengage.sdk.android.WebEngage;
import com.webengage.sdk.android.LocationTrackingStrategy;

import com.moengage.flutter.MoEInitializer
import com.moengage.core.DataCenter
import com.moengage.core.LogLevel
import com.moengage.core.MoEngage
import com.moengage.core.config.LogConfig
import com.moengage.core.config.MoEngageEnvironmentConfig
import com.moengage.core.model.environment.MoEngageEnvironment

class MainApplication : FlutterApplication() {

override fun onCreate() {
        super.onCreate()
        val webEngageConfig = WebEngageConfig.Builder()
            .setWebEngageKey("")
            .setAutoGCMRegistrationFlag(false)
            .setLocationTrackingStrategy(LocationTrackingStrategy.ACCURACY_BEST)
            .setDebugMode(true) // only in development mode
            .build()
        WebengageInitializer.initialize(this as Application?, webEngageConfig)

        val moEngage: MoEngage.Builder = MoEngage.Builder(this as Application, "MOE_ID", DataCenter.DATA_CENTER_3)
            .configureLogs(LogConfig(LogLevel.VERBOSE, true))
            .configureMoEngageEnvironment(MoEngageEnvironmentConfig(MoEngageEnvironment.LIVE))
        MoEInitializer.initialiseDefaultInstance(applicationContext, moEngage)
    }
}