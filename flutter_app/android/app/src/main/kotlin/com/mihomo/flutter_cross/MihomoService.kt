// Android后台服务实现
// 用于保持Mihomo代理在后台运行

package com.mihomo.flutter_cross

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class MihomoService : Service() {

    private val binder = LocalBinder()
    private var isRunning = false
    private val CHANNEL_ID = "mihomo_service_channel"
    private val NOTIFICATION_ID = 1

    inner class LocalBinder : Binder() {
        fun getService(): MihomoService = this@MihomoService
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = createNotification()
        startForeground(NOTIFICATION_ID, notification)

        isRunning = true
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
    }

    fun isServiceRunning(): Boolean = isRunning

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Mihomo Service Channel",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Mihomo代理服务后台运行"
            }

            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun createNotification(): android.app.Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Mihomo代理运行中")
            .setContentText("后台服务正在运行，代理流量正常")
            .setSmallIcon(android.R.drawable.ic_menu_manage)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    companion object {
        fun startService(context: Context) {
            val serviceIntent = Intent(context, MihomoService::class.java)
            context.startForegroundService(serviceIntent)
        }

        fun stopService(context: Context) {
            val serviceIntent = Intent(context, MihomoService::class.java)
            context.stopService(serviceIntent)
        }
    }
}