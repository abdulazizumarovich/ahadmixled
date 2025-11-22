package uz.iportal.axadmixled.core.constants

import uz.iportal.axadmixled.BuildConfig

/**
 * API Constants
 * All backend endpoints and configuration (matching Flutter implementation)
 */
object ApiConstants {

    // Base URL Configuration
    const val DOMAIN_NAME = BuildConfig.DOMAIN
    private const val PROTOCOL = BuildConfig.PROTOCOL
    private const val PORT = BuildConfig.PORT

//    const val BASE_URL = "$PROTOCOL://$DOMAIN_NAME:$PORT/"

    fun baseUrl(domain: String): String {
        return "$PROTOCOL://$domain$PORT/"
    }

    // WebSocket Configuration
    fun wsUrl(domain: String, deviceId: String, token: String): String {
        return "ws://$domain$PORT/ws/cloud/tb_device/?token=$token&sn_number=$deviceId"
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
