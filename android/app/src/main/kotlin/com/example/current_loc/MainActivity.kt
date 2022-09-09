package com.example.current_loc

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.IBinder
import java.security.Provider.Service
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors


class testservice : Service() {
    var es: ExecutorService = Executors.newSingleThreadExecutor()
    @Override
    fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
            val channel = NotificationChannel("101", "foreground", NotificationManager.IMPORTANCE_DEFAULT)
            val manager: NotificationManager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
        val notifcationIntent = Intent(this, MainActivity::class.java)
        val pi: PendingIntent = PendingIntent.getActivity(this, 0, notifcationIntent, 0)
        val notification: Notification = Builder(this, "101").setContentTitle("foreground service").setContentText("This is content").setSmallIcon(R.drawable.launch_background).setContentIntent(pi).build()
        startForeground(1, notification)
        es.execute(object : Runnable() {
            @Override
            fun run() {
                for (i in 0..14) {
                    System.out.println("Response from Thread " + String.valueOf(i))
                    try {
                        Thread.sleep(2000)
                    } catch (e: InterruptedException) {
                        e.printStackTrace()
                    }
                }
                stopSelf()
            }
        })
        return android.app.Service.START_STICKY
    }

    @Override
    fun onBind(intent: Intent?): IBinder {
        // TODO: Return the communication channel to the service.
        throw UnsupportedOperationException("Not yet implemented")
    }
}