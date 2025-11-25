package uz.iportal.axadmixled.presentation.auth

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.activity.viewModels
import androidx.core.widget.doOnTextChanged
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch
import timber.log.Timber
import uz.iportal.axadmixled.BuildConfig
import uz.iportal.axadmixled.databinding.ActivityAuthBinding
import uz.iportal.axadmixled.presentation.player.PlayerActivity
import uz.iportal.axadmixled.util.KioskActivity

@AndroidEntryPoint
class AuthActivity : KioskActivity() {

    private lateinit var binding: ActivityAuthBinding
    private val viewModel: AuthViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Timber.tag(TAG).d("AuthActivity onCreate")

        // Setup ViewBinding
        binding = ActivityAuthBinding.inflate(layoutInflater)
        setContentView(binding.root)

        @Suppress("KotlinConstantConditions")
        if (BuildConfig.FLAVOR == "production") {
            binding.tilIp.visibility = View.GONE
        }

        // Setup UI listeners
        setupListeners()

        // Observe ViewModel
        observeViewModel()
    }

    private fun setupListeners() {
        // Login button click
        binding.btnLogin.setOnClickListener {
            val username = binding.etUsername.text?.toString() ?: ""
            val password = binding.etPassword.text?.toString() ?: ""
            val ip = binding.etIp.text?.toString() ?: ""

            Timber.tag(TAG).d("Login button clicked")
            viewModel.login(ip, username, password)
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
                Timber.tag(TAG).d("Login state: Idle")
                binding.progressBar.visibility = View.GONE
                binding.btnLogin.isEnabled = true
                binding.etUsername.isEnabled = true
                binding.etPassword.isEnabled = true
            }
            is LoginState.Loading -> {
                Timber.tag(TAG).d("Login state: Loading")
                binding.progressBar.visibility = View.VISIBLE
                binding.btnLogin.isEnabled = false
                binding.etUsername.isEnabled = false
                binding.etPassword.isEnabled = false
                binding.tilUsername.error = null
                binding.tilPassword.error = null
            }
            is LoginState.Success -> {
                Timber.tag(TAG).d("Login state: Success")
                binding.progressBar.visibility = View.GONE
                Toast.makeText(this, "Login successful", Toast.LENGTH_SHORT).show()
            }
            is LoginState.Error -> {
                Timber.tag(TAG).e("Login state: Error - ${state.message}")
                binding.progressBar.visibility = View.GONE
                binding.btnLogin.isEnabled = true
                binding.etUsername.isEnabled = true
                binding.etPassword.isEnabled = true

                // Show error message
                Toast.makeText(this, state.message, Toast.LENGTH_LONG).show()
                if (state.ipError) {
                    binding.tilIp.error = state.message
                    binding.tilPassword.error = null
                } else {
                    binding.tilPassword.error = state.message
                    binding.tilIp.error = null
                }
            }
        }
    }

    private fun handleNavigationEvent(event: NavigationEvent) {
        when (event) {
            is NavigationEvent.NavigateToPlayer -> {
                Timber.tag(TAG).d("Navigating to PlayerActivity")
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
        Timber.tag(TAG).d("AuthActivity onResume")

        // Reset state when resuming
        viewModel.resetState()
    }

    override fun onPause() {
        super.onPause()
        Timber.tag(TAG).d("AuthActivity onPause")
    }

    override fun onDestroy() {
        super.onDestroy()
        Timber.tag(TAG).d("AuthActivity onDestroy")
    }
    
    companion object {
        private const val TAG = "AuthActivity"
    }
}
