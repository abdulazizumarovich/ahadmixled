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
        return "wss://$DOMAIN_NAME/ws/cloud/tb_device/?token=$token&sn_number=$deviceId"
    }

    // Auth Endpoints
    const val LOGIN = "/auth/token/"
    const val REFRESH_TOKEN = "/auth/token/refresh/"

    // Device Endpoints
    const val DEVICE_REGISTER = "/admin/cloud/device/register/"

    // Video/Playlist Endpoints
    fun playlist(deviceId: String) = "/admin/cloud/playlists?sn_number=$deviceId"
    const val SCREENSHOT = "/screenshot"

    // HTTP Headers
    const val CONTENT_TYPE = "application/json"
    const val AUTHORIZATION = "Authorization"
    fun bearerToken(token: String) = "Bearer $token"

    // Timeouts (milliseconds)
    const val CONNECTION_TIMEOUT = 30_000L // 30 seconds
    const val READ_TIMEOUT = 30_000L // 30 seconds
    const val WRITE_TIMEOUT = 30_000L // 30 seconds
}
