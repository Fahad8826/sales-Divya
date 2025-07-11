package com.techfifo.sales

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log


class RestartMicStreamReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        Log.d("RestartReceiver", "🔄 RestartMicStreamReceiver triggered")
        context.startForegroundService(Intent(context, MicStreamService::class.java))
    }
}