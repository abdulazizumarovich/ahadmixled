package uz.iportal.axadmixled.util

object Constants {
    const val BASE_URL = "https://admin-led.ohayo.uz/"
    const val WEBSOCKET_URL = "wss://admin-led.ohayo.uz/ws/cloud/tb_device/"

    // SharedPreferences
    const val PREFS_NAME = "led_player_prefs"
    const val KEY_ACCESS_TOKEN = "access_token"
    const val KEY_REFRESH_TOKEN = "refresh_token"
    const val KEY_TOKEN_EXPIRES_AT = "token_expires_at"
    const val KEY_DEVICE_SN = "device_sn"

    // Token refresh interval (23 hours)
    const val TOKEN_REFRESH_INTERVAL = 23 * 60 * 60 * 1000L

    // Storage monitoring interval (30 seconds)
    const val STORAGE_CHECK_INTERVAL = 30_000L

    // WebSocket reconnect settings
    const val WS_INITIAL_RETRY_DELAY = 1000L
    const val WS_MAX_RETRY_DELAY = 60000L
    const val WS_MAX_RETRY_ATTEMPTS = 10

    // Download settings
    const val DOWNLOAD_BUFFER_SIZE = 8192
    const val DOWNLOAD_TIMEOUT = 300_000L // 5 minutes
}
