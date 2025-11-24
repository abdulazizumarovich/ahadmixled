package uz.iportal.axadmixled.presentation.splash

import android.content.Intent
import android.os.Bundle
import androidx.activity.viewModels
import androidx.lifecycle.lifecycleScope
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import timber.log.Timber
import uz.iportal.axadmixled.databinding.ActivitySplashBinding
import uz.iportal.axadmixled.presentation.auth.AuthActivity
import uz.iportal.axadmixled.presentation.player.PlayerActivity
import uz.iportal.axadmixled.util.KioskActivity


@AndroidEntryPoint
class SplashActivity : KioskActivity() {

    private lateinit var binding: ActivitySplashBinding
    private val viewModel: SplashViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Timber.d("SplashActivity onCreate")

        // Setup ViewBinding
        binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Initialize app
        initializeApp()
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
        intent.addFlags(Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT or Intent.FLAG_ACTIVITY_NO_ANIMATION)
        startActivity(intent)

        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        Timber.d("SplashActivity onDestroy")
    }
}
