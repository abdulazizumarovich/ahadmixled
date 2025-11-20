package uz.iportal.axadmixled.presentation.auth

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.widget.Toast
import androidx.activity.viewModels
import androidx.annotation.RequiresApi
import androidx.appcompat.app.AppCompatActivity
import androidx.core.widget.doOnTextChanged
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import timber.log.Timber
import uz.iportal.axadmixled.databinding.ActivityAuthBinding
import uz.iportal.axadmixled.presentation.player.PlayerActivity

@AndroidEntryPoint
class AuthActivity : AppCompatActivity() {

    private lateinit var binding: ActivityAuthBinding
    private val viewModel: AuthViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Timber.d("AuthActivity onCreate")

        // Setup ViewBinding
        binding = ActivityAuthBinding.inflate(layoutInflater)
        setContentView(binding.root)

        // Setup full screen UI
        setupFullScreenUI()

        // Setup UI listeners
        setupListeners()

        // Observe ViewModel
        observeViewModel()
    }

    @RequiresApi(Build.VERSION_CODES.HONEYCOMB)
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

            Timber.d("Full screen UI configured")
        } catch (e: Exception) {
            Timber.e(e, "Failed to setup full screen UI")
        }
    }

    private fun setupListeners() {
        // Login button click
        binding.btnLogin.setOnClickListener {
            val username = binding.etUsername.text?.toString() ?: ""
            val password = binding.etPassword.text?.toString() ?: ""

            Timber.d("Login button clicked")
            viewModel.login(username, password)
        }

        // Clear error on text change
        binding.etUsername.doOnTextChanged { _, _, _, _ ->
            binding.tilUsername.error = null
            viewModel.clearError()
        }

        binding.etPassword.doOnTextChanged { _, _, _, _ ->
            binding.tilPassword.error = null
            viewModel.clearError()
        }
    }

    private fun observeViewModel() {
        // Observe login state
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.loginState.collect { state ->
                    handleLoginState(state)
                }
            }
        }

        // Observe navigation events
        lifecycleScope.launch {
            repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.navigationEvent.collect { event ->
                    handleNavigationEvent(event)
                }
            }
        }
    }

    private fun handleLoginState(state: LoginState) {
        when (state) {
            is LoginState.Idle -> {
                Timber.d("Login state: Idle")
                binding.progressBar.visibility = View.GONE
                binding.btnLogin.isEnabled = true
                binding.etUsername.isEnabled = true
                binding.etPassword.isEnabled = true
            }
            is LoginState.Loading -> {
                Timber.d("Login state: Loading")
                binding.progressBar.visibility = View.VISIBLE
                binding.btnLogin.isEnabled = false
                binding.etUsername.isEnabled = false
                binding.etPassword.isEnabled = false
                binding.tilUsername.error = null
                binding.tilPassword.error = null
            }
            is LoginState.Success -> {
                Timber.d("Login state: Success")
                binding.progressBar.visibility = View.GONE
                Toast.makeText(this, "Login successful", Toast.LENGTH_SHORT).show()
            }
            is LoginState.Error -> {
                Timber.tag("TAGDF").e("Login state: Error - ${state.message}")
                binding.progressBar.visibility = View.GONE
                binding.btnLogin.isEnabled = true
                binding.etUsername.isEnabled = true
                binding.etPassword.isEnabled = true

                // Show error message
                Toast.makeText(this, state.message, Toast.LENGTH_LONG).show()
                binding.tilPassword.error = state.message
            }
        }
    }

    private fun handleNavigationEvent(event: NavigationEvent) {
        when (event) {
            is NavigationEvent.NavigateToPlayer -> {
                Timber.d("Navigating to PlayerActivity")
                navigateToPlayer()
            }
        }
    }

    private fun navigateToPlayer() {
        val intent = Intent(this, PlayerActivity::class.java)
        startActivity(intent)
        finish()
    }

    override fun onResume() {
        super.onResume()
        Timber.d("AuthActivity onResume")

        // Reset state when resuming
        viewModel.resetState()
    }

    override fun onPause() {
        super.onPause()
        Timber.d("AuthActivity onPause")
    }

    override fun onDestroy() {
        super.onDestroy()
        Timber.d("AuthActivity onDestroy")
    }
}
