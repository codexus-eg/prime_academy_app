package com.primeacademy.app

import android.os.Build
import android.os.Bundle
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Honor LaunchTheme splash attrs (solid bg, no launcher icon).
            installSplashScreen()
        }
        super.onCreate(savedInstanceState)
    }
}
