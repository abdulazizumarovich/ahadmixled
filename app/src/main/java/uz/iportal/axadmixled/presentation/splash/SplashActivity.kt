package uz.iportal.axadmixled.presentation.splash

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import timber.log.Timber
import uz.iportal.axadmixled.databinding.ActivitySplashBinding
import uz.iportal.axadmixled.presentation.auth.AuthActivity
import uz.iportal.axadmixled.presentation.player.PlayerActivity

@AndroidEntryPoint
class SplashActivity : AppCompatActivity() {

    private lateinit var binding: ActivitySplashBinding
    private val viewModel: SplashViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Timber.d("SplashActivity onCreate")

        // Setup ViewBinding
        binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Setup full screen UI
        setupFullScreenUI()

        // Initialize app
        initializeApp()

//        throw RuntimeException("Test Crash") // Force a crash

    }

    private fun setupFullScreenUI() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Android 11 and above
                window.setDecorFitsSystemWindows(false)
                window.insetsController?.apply {
                    hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                    systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                }
            } else {
                // Android 10 and below
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                )
            }

            // Keep screen on during splash
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

            Timber.d("Full screen UI configured")
        } catch (e: Exception) {
            Timber.e(e, "Failed to setup full screen UI")
        }
    }

    private fun initializeApp() {
        lifecycleScope.launch {
            try {
                Timber.d("Starting app initialization")
                binding.tvStatus.text = "Initializing..."

                viewModel.initializeApp().collectLatest { state ->
                    when (state) {
                        is AppState.NeedsAuth -> {
                            Timber.d("App needs authentication")
                            binding.tvStatus.text = "Authentication required"
                            navigateToAuth()
                        }
                        is AppState.Ready -> {
                            Timber.d("App ready, navigating to player")
                            binding.tvStatus.text = "Ready"
                            navigateToPlayer()
                        }
                        is AppState.Error -> {
                            Timber.e("App initialization failed: ${state.message}")
                            binding.tvStatus.text = "Error: ${state.message}"
                            // Wait a moment then navigate to auth
                            kotlinx.coroutines.delay(2000)
                            navigateToAuth()
                        }
                    }
                }
            } catch (e: Exception) {
                Timber.e(e, "Exception during initialization")
                binding.tvStatus.text = "Error: ${e.message}"
                kotlinx.coroutines.delay(2000)
                navigateToAuth()
            }
        }
    }

    private fun navigateToAuth() {
        Timber.d("Navigating to AuthActivity")
        val intent = Intent(this, AuthActivity::class.java)
        startActivity(intent)
        finish()
    }

    private fun navigateToPlayer() {
        Timber.d("Navigating to PlayerActivity")
        val intent = Intent(this, PlayerActivity::class.java)
        startActivity(intent)
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        Timber.d("SplashActivity onDestroy")
    }
}
