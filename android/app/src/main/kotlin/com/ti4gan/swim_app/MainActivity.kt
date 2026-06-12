package com.ti4gan.swim_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "coach_workouts",
                "Тренировки",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Уведомления о тренировках от тренера"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
        super.onCreate(savedInstanceState)
    }
}
