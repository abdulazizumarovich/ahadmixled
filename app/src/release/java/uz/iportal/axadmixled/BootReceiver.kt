package uz.iportal.axadmixled

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import uz.iportal.axadmixled.presentation.splash.SplashActivity

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED) return

        val myIntent = Intent(context, SplashActivity::class.java)
        myIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(myIntent)
    }
}
