package uz.iportal.axadmixled.core.constants

/**
 * API Constants
 * All backend endpoints and configuration (matching Flutter implementation)
 */
object ApiConstants {

    // Base URL Configuration
    private const val DOMAIN_NAME = "admin-led.ohayo.uz"
    const val DOMAIN = "https://$DOMAIN_NAME"
    const val BASE_URL = "$DOMAIN/api/v1"

    // WebSocket Configuration
    fun wsUrl(deviceId: String, token: String): String {
        return "ws://admin-led.ohayo.uz/ws/cloud/tb_device/?token=$token&sn_number=$deviceId"
    }

    // Auth Endpoints
    const val LOGIN = "api/v1/auth/token/"
    const val REFRESH_TOKEN = "/auth/token/refresh/"

    // Device Endpoints
    const val DEVICE_REGISTER = "api/v1/admin/cloud/device/register/"
    const val DEVICE_INFO = "api/v1/admin/cloud/device/{sn_number}/"

    // Video/Playlist Endpoints
    fun playlist(deviceId: String) = "api/v1/admin/cloud/playlists?sn_number=$deviceId"
    const val SCREENSHOT = "api/v1/screenshot"

    // HTTP Headers
    const val CONTENT_TYPE = "application/json"
    const val AUTHORIZATION = "Authorization"
    fun bearerToken(token: String) = "Bearer $token"

    // Timeouts (milliseconds)
    const val CONNECTION_TIMEOUT = 30_000L // 30 seconds
    const val READ_TIMEOUT = 30_000L // 30 seconds
    const val WRITE_TIMEOUT = 30_000L // 30 seconds
}
