# TV Monitor Backend API Documentation

**Version:** 1.0
**Base URL:** `https://admin-led.ohayo.uz/api/v1`
**WebSocket URL:** `wss://admin-led.ohayo.uz/ws/cloud/tb_device/`

---

## Table of Contents

1. [Authentication](#authentication)
2. [Device Management](#device-management)
3. [Playlist & Media](#playlist--media)
4. [WebSocket Communication](#websocket-communication)
   - [Server → Client Messages](#websocket-messages-server--client)
   - [Client → Server Messages](#websocket-messages-client--server)
5. [Data Models](#data-models)
6. [Error Handling](#error-handling)
7. [Implementation Guidelines](#implementation-guidelines)
8. [Best Practices](#best-practices)
9. [API Flow Examples](#api-flow-examples)

---

## Quick Reference

### Client → Server Messages

**Ready Playlists Notification (via WebSocket):**

```json
// All ready playlists
{"type": "ready_playlists", "playlist_ids": [101, 102, 103]}
```

**Playlist Status Updates (via WebSocket):**

```json
// Playlist Ready
{"type": "playlist_status", "playlist_id": 101, "status": "ready", "total_items": 7, "downloaded_items": 7}

// Downloading
{"type": "playlist_status", "playlist_id": 101, "status": "downloading", "total_items": 7, "downloaded_items": 3}

// Partial Success
{"type": "playlist_status", "playlist_id": 101, "status": "partial", "total_items": 7, "downloaded_items": 5, "missing_files": ["file1.mp4"]}

// Failed
{"type": "playlist_status", "playlist_id": 101, "status": "failed", "total_items": 7, "downloaded_items": 0, "error": "Network error"}
```

### Server → Client Messages

**Playback Control (via WebSocket):**

```json
{"action": "play"}
{"action": "pause"}
{"action": "next"}
{"action": "previous"}
{"action": "reload_playlist"}
{"action": "switch_playlist", "playlist_id": 102}
{"action": "set_brightness", "brightness": 75}
{"action": "set_volume", "volume": 60}
```

---

## Authentication

### 1. Login

**Endpoint:** `POST /auth/token/`

**Description:** Authenticate user and receive access/refresh tokens.

**Request Body:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Response:** `200 OK`
```json
{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600
}
```

**Response Fields:**
- `access` (string): JWT access token for API requests
- `refresh` (string): JWT refresh token to obtain new access token
- `expires_in` (int): Token expiration time in seconds

**Error Responses:**
- `400 Bad Request`: Invalid credentials
- `500 Internal Server Error`: Server error

---

### 2. Refresh Token

**Endpoint:** `POST /auth/token/refresh/`

**Description:** Obtain a new access token using refresh token.

**Request Body:**
```json
{
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:** `200 OK`
```json
{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600
}
```

**Error Responses:**
- `401 Unauthorized`: Invalid or expired refresh token

---

## Device Management

### 1. Register Device

**Endpoint:** `POST /admin/cloud/device/register/`

**Description:** Register a new Android TV device or update existing device info.

**Headers:**
```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "sn_number": "DEVICE-SN-12345",
  "brand": "Samsung",
  "model": "Galaxy TV",
  "manufacturer": "Samsung Electronics",
  "os_version": "Android 11",
  "screen_resolution": "1920x1080",
  "total_storage": "32GB",
  "free_storage": "20GB",
  "mac_address": "00:1A:2B:3C:4D:5E",
  "app_version": "1.0.0",
  "ip_address": "192.168.1.100",
  "brightness": 50,
  "volume": 50
}
```

**Request Fields:**
- `sn_number` (string, required): Unique device serial number
- `brand` (string, required): Device brand name
- `model` (string, required): Device model name
- `manufacturer` (string, required): Device manufacturer
- `os_version` (string, required): Android OS version
- `screen_resolution` (string, required): Screen resolution (e.g., "1920x1080")
- `total_storage` (string, required): Total storage capacity
- `free_storage` (string, required): Available storage
- `mac_address` (string, optional): Device MAC address
- `app_version` (string, required): App version
- `ip_address` (string, optional): Device IP address
- `brightness` (int, optional): Screen brightness (0-100), default: 50
- `volume` (int, optional): Audio volume (0-100), default: 50

**Response:** `200 OK` or `201 Created`
```json
{
  "data": {
    "sn_number": "DEVICE-SN-12345"
  }
}
```

**Error Responses:**
- `400 Bad Request`: Invalid device data
- `401 Unauthorized`: Missing or invalid token

---

## Playlist & Media

### 1. Get Device Screens and Playlists

**Endpoint:** `GET /admin/cloud/playlists?sn_number={device_id}`

**Description:** Retrieve all screens and their playlists assigned to a device.

**Headers:**
```
Authorization: Bearer {access_token}
```

**Query Parameters:**
- `sn_number` (string, required): Device serial number

**Response:** `200 OK`
```json
{
  "sn_number": "DEVICE-SN-12345",
  "front_screen": {
    "screen_id": 1,
    "screen_name": "Front Display",
    "resolution": "1920x1080",
    "current_playlist": 101,
    "playlists": [
      {
        "id": 101,
        "name": "Morning Ads",
        "width": 1920,
        "height": 1080,
        "duration": 120,
        "media_items": [
          {
            "media_id": 1001,
            "order": 1,
            "media_name": "logo1.jpg",
            "media_type": "image",
            "mimetype": "image/jpeg",
            "media_url": "/media/images/logo1.jpg",
            "file_size": 524288,
            "checksum": "5d41402abc4b2a76b9719d911017c592",
            "layout": {
              "x": 0,
              "y": 0,
              "width": 1920,
              "height": 1080,
              "z_index": 1
            },
            "timing": {
              "start_time": 0,
              "duration": 10,
              "loop": false
            },
            "effects": {
              "fade_in": true,
              "fade_out": true,
              "transition": "slide"
            },
            "n_time_play": 1
          },
          {
            "media_id": 1002,
            "order": 2,
            "media_name": "ad_video.mp4",
            "media_type": "video",
            "mimetype": "video/mp4",
            "media_url": "/media/videos/ad_video.mp4",
            "file_size": 10485760,
            "checksum": "098f6bcd4621d373cade4e832627b4f6",
            "layout": {
              "x": 0,
              "y": 0,
              "width": 1920,
              "height": 1080,
              "z_index": 1
            },
            "timing": {
              "start_time": 0,
              "duration": 30,
              "loop": false
            },
            "effects": {
              "fade_in": false,
              "fade_out": false,
              "transition": "none"
            },
            "n_time_play": 2
          }
        ],
        "playback_config": {
          "repeat": true,
          "repeat_count": -1,
          "background_color": "#000000"
        },
        "status": {
          "is_ready": true,
          "all_downloaded": false,
          "missing_files": [],
          "last_verified": "2025-01-15T10:30:00Z"
        }
      }
    ]
  },
  "back_screen": null,
  "right_screen": null,
  "left_screen": null
}
```

**Response Fields:**

**DeviceScreens:**
- `sn_number` (string): Device serial number
- `front_screen` (ScreenConfig, optional): Front screen configuration
- `back_screen` (ScreenConfig, optional): Back screen configuration
- `right_screen` (ScreenConfig, optional): Right screen configuration
- `left_screen` (ScreenConfig, optional): Left screen configuration

**ScreenConfig:**
- `screen_id` (int): Unique screen identifier
- `screen_name` (string): Screen display name
- `resolution` (string): Screen resolution
- `current_playlist` (int, optional): Currently active playlist ID
- `playlists` (array): List of playlists for this screen

**Playlist:**
- `id` (int): Playlist unique identifier
- `name` (string): Playlist name
- `width` (int): Playlist canvas width in pixels
- `height` (int): Playlist canvas height in pixels
- `duration` (int): Total playlist duration in seconds
- `media_items` (array): List of media items
- `playback_config` (object): Playback configuration
- `status` (object): Playlist download/ready status

**MediaItem:**
- `media_id` (int): Media unique identifier
- `order` (int): Playback order in playlist
- `media_name` (string): Media file name
- `media_type` (string): Media type ("image" or "video")
- `mimetype` (string): MIME type (e.g., "image/jpeg", "video/mp4")
- `media_url` (string): Media file URL (relative or absolute)
- `file_size` (int): File size in bytes
- `checksum` (string): MD5 checksum for integrity verification
- `layout` (MediaLayout): Position and size configuration
- `timing` (MediaTiming): Timing and duration settings
- `effects` (MediaEffects): Visual effects configuration
- `n_time_play` (int): Number of times to play this media

**MediaLayout:**
- `x` (int): X position in pixels
- `y` (int): Y position in pixels
- `width` (int): Width in pixels
- `height` (int): Height in pixels
- `z_index` (int): Layer order (higher = on top)

**MediaTiming:**
- `start_time` (int): Start time offset in seconds
- `duration` (int): Display/play duration in seconds
- `loop` (bool): Whether to loop this media

**MediaEffects:**
- `fade_in` (bool): Enable fade-in effect
- `fade_out` (bool): Enable fade-out effect
- `transition` (string): Transition type ("none", "slide", "fade", etc.)

**PlaybackConfig:**
- `repeat` (bool): Repeat playlist when finished
- `repeat_count` (int): Number of repeats (-1 for infinite)
- `background_color` (string): Background color hex code

**PlaylistStatus:**
- `is_ready` (bool): Playlist ready for playback
- `all_downloaded` (bool): All media files downloaded
- `missing_files` (array): List of missing file names
- `last_verified` (string): Last verification timestamp (ISO 8601)

**Error Responses:**
- `401 Unauthorized`: Missing or invalid token
- `404 Not Found`: Device not found

---

### 2. Download Media File

**Endpoint:** `GET {media_url}`

**Description:** Download a media file (video or image).

**Headers:**
```
Authorization: Bearer {access_token}
```

**Example:**
```
GET https://admin-led.ohayo.uz/media/images/logo1.jpg
```

**Response:** Binary file data with appropriate content-type header.

**Notes:**
- Media URLs can be relative (e.g., `/media/images/logo1.jpg`) or absolute
- Files are downloaded and cached locally in `/data/data/com.example.tv_monitor/files/vnnox_media/`
- File naming: `{media_id}_{media_name}` (e.g., `38_logo1.jpg`)
- Checksum verification recommended after download

---

### 3. Upload Screenshot

**Endpoint:** `POST /screenshot`

**Description:** Upload a screenshot of currently playing media.

**Headers:**
```
Authorization: Bearer {access_token}
Content-Type: multipart/form-data
```

**Request Body (multipart/form-data):**
```
device_id: "DEVICE-SN-12345"
media_id: 1001
image_file: [binary image data]
```

**Form Fields:**
- `device_id` (string): Device serial number
- `media_id` (int): Currently playing media ID
- `image_file` (file): Screenshot image file (JPEG format)

**Response:** `200 OK`
```json
{
  "message": "Screenshot uploaded successfully"
}
```

**Error Responses:**
- `400 Bad Request`: Invalid file or missing parameters
- `401 Unauthorized`: Missing or invalid token

---

## WebSocket Communication

### Connection

**WebSocket URL:** `wss://admin-led.ohayo.uz/ws/cloud/tb_device/?token={access_token}&sn_number={device_id}`

**Description:** Real-time bidirectional communication for remote device control.

**Connection Parameters:**
- `token` (string): Access token (JWT)
- `sn_number` (string): Device serial number

**Example:**
```
wss://admin-led.ohayo.uz/ws/cloud/tb_device/?token=eyJhbGci...&sn_number=DEVICE-SN-12345
```

---

### WebSocket Messages (Server → Client)

The server sends JSON messages to control device playback and settings.

#### 1. Play

```json
{
  "action": "play"
}
```

**Description:** Resume or start playback.

---

#### 2. Pause

```json
{
  "action": "pause"
}
```

**Description:** Pause current playback.

---

#### 3. Next

```json
{
  "action": "next"
}
```

**Description:** Skip to next media item in playlist.

---

#### 4. Previous

```json
{
  "action": "previous"
}
```

**Description:** Go back to previous media item in playlist.

---

#### 5. Reload Playlist

```json
{
  "action": "reload_playlist"
}
```

**Description:** Reload current playlist from server (fetch latest updates).

---

#### 6. Switch Playlist

```json
{
  "action": "switch_playlist",
  "playlist_id": 102
}
```

**Description:** Switch to a different playlist.

**Fields:**
- `playlist_id` (int, required): Target playlist ID

---

#### 7. Play Specific Media

```json
{
  "action": "play_media",
  "media_id": 1005,
  "media_index": 3
}
```

**Description:** Jump to specific media item.

**Fields:**
- `media_id` (int, optional): Media ID to play
- `media_index` (int, optional): Media index in playlist (0-based)

---

#### 8. Show Text Overlay

```json
{
  "action": "show_text_overlay",
  "text_overlay": {
    "text": "Special Promotion Today!",
    "position": "bottom",
    "animation": "scroll",
    "speed": 50.0,
    "font_size": 24,
    "background_color": "#000000",
    "text_color": "#FFFFFF"
  }
}
```

**Description:** Display scrolling or static text overlay on video.

**TextOverlay Fields:**
- `text` (string, required): Text to display
- `position` (string): Position ("top", "bottom", "left", "right")
- `animation` (string): Animation type ("scroll", "static")
- `speed` (float): Scroll speed (pixels per second)
- `font_size` (int, optional): Font size in pixels
- `background_color` (string, optional): Background color hex code
- `text_color` (string, optional): Text color hex code

---

#### 9. Hide Text Overlay

```json
{
  "action": "hide_text_overlay"
}
```

**Description:** Hide text overlay.

---

#### 10. Set Brightness

```json
{
  "action": "set_brightness",
  "brightness": 75
}
```

**Description:** Adjust screen brightness.

**Fields:**
- `brightness` (int, required): Brightness level (0-100)

---

#### 11. Set Volume

```json
{
  "action": "set_volume",
  "volume": 60
}
```

**Description:** Adjust audio volume.

**Fields:**
- `volume` (int, required): Volume level (0-100)

---

### WebSocket Messages (Client → Server)

The client sends status updates to inform the server about playlist download progress and readiness.

---

#### 1. Ready Playlists Notification

```json
{
  "type": "ready_playlists",
  "playlist_ids": [101, 102, 103]
}
```

**Description:** Notify server about all playlists that are fully downloaded and ready for playback.

**Fields:**
- `type` (string, required): Always "ready_playlists"
- `playlist_ids` (array, required): Array of playlist IDs that are fully ready

**When to Send:**
- After `reload_playlist` WebSocket command completes downloading
- After `switch_playlist` WebSocket command completes downloading
- When all playlists in a batch download finish
- On app startup after verifying all downloaded playlists

**Example Flow:**
```javascript
// 1. Backend sends reload_playlist command
{"action": "reload_playlist"}

// 2. Device downloads new/missing playlists
// ... downloading ...

// 3. Device sends ready playlist IDs back
{
  "type": "ready_playlists",
  "playlist_ids": [101, 102, 103]
}
```

---

#### 2. Playlist Status - Ready

```json
{
  "type": "playlist_status",
  "playlist_id": 101,
  "status": "ready",
  "total_items": 7,
  "downloaded_items": 7
}
```

**Description:** Notify server that playlist is fully downloaded and ready for playback.

**Fields:**
- `type` (string, required): Always "playlist_status"
- `playlist_id` (int, required): Playlist ID
- `status` (string, required): Status value "ready"
- `total_items` (int, optional): Total number of media items
- `downloaded_items` (int, optional): Number of successfully downloaded items

**When to Send:**
- After all media files in playlist are successfully downloaded
- All checksums verified
- Playlist is ready for playback

---

#### 2. Playlist Status - Downloading

```json
{
  "type": "playlist_status",
  "playlist_id": 101,
  "status": "downloading",
  "total_items": 7,
  "downloaded_items": 3
}
```

**Description:** Report ongoing download progress.

**Fields:**
- `type` (string, required): Always "playlist_status"
- `playlist_id` (int, required): Playlist ID
- `status` (string, required): Status value "downloading"
- `total_items` (int, required): Total number of media items
- `downloaded_items` (int, required): Number of downloaded items so far

**When to Send:**
- Periodically during download process
- When a media item finishes downloading
- Recommended: Send every time downloaded_items count changes

---

#### 3. Playlist Status - Partial

```json
{
  "type": "playlist_status",
  "playlist_id": 101,
  "status": "partial",
  "total_items": 7,
  "downloaded_items": 5,
  "missing_files": [
    "video_ad_1.mp4",
    "banner_image.jpg"
  ]
}
```

**Description:** Some media files failed to download, but playlist is partially usable.

**Fields:**
- `type` (string, required): Always "playlist_status"
- `playlist_id` (int, required): Playlist ID
- `status` (string, required): Status value "partial"
- `total_items` (int, required): Total number of media items
- `downloaded_items` (int, required): Number of successfully downloaded items
- `missing_files` (array, required): List of file names that failed to download

**When to Send:**
- After download process completes but some files are missing
- Device can still play downloaded media items

---

#### 4. Playlist Status - Failed

```json
{
  "type": "playlist_status",
  "playlist_id": 101,
  "status": "failed",
  "total_items": 7,
  "downloaded_items": 0,
  "error": "Network connection lost during download"
}
```

**Description:** Playlist download completely failed.

**Fields:**
- `type` (string, required): Always "playlist_status"
- `playlist_id` (int, required): Playlist ID
- `status` (string, required): Status value "failed"
- `total_items` (int, optional): Total number of media items
- `downloaded_items` (int, optional): Number of downloaded items (usually 0)
- `error` (string, optional): Error message describing the failure

**When to Send:**
- No media files could be downloaded
- Critical error occurred (network failure, storage full, etc.)
- Playlist cannot be played

---

### Playlist Status Types Summary

| Status | Description | Playable |
|--------|-------------|----------|
| `ready` | All media downloaded successfully | ✅ Yes |
| `downloading` | Download in progress | ❌ No |
| `partial` | Some media downloaded | ⚠️ Partial |
| `failed` | Download failed completely | ❌ No |

---

### Example Status Update Flow

**Scenario:** Downloading a playlist with 5 media items

```javascript
// 1. Start download
{
  "type": "playlist_status",
  "playlist_id": 101,
  "status": "downloading",
  "total_items": 5,
  "downloaded_items": 0
}

// 2. First item downloaded
{
  "type": "playlist_status",
  "playlist_id": 101,
  "status": "downloading",
  "total_items": 5,
  "downloaded_items": 1
}

// 3. Second item downloaded
{
  "type": "playlist_status",
  "playlist_id": 101,
  "status": "downloading",
  "total_items": 5,
  "downloaded_items": 2
}

// 4. Third item failed, continue with others
{
  "type": "playlist_status",
  "playlist_id": 101,
  "status": "downloading",
  "total_items": 5,
  "downloaded_items": 2
}

// 5. Fourth and fifth items downloaded
{
  "type": "playlist_status",
  "playlist_id": 101,
  "status": "downloading",
  "total_items": 5,
  "downloaded_items": 4
}

// 6. Download complete but one file missing
{
  "type": "playlist_status",
  "playlist_id": 101,
  "status": "partial",
  "total_items": 5,
  "downloaded_items": 4,
  "missing_files": ["video_3.mp4"]
}
```

**Scenario:** Successful download of all items

```javascript
// 1. Start download
{
  "type": "playlist_status",
  "playlist_id": 102,
  "status": "downloading",
  "total_items": 3,
  "downloaded_items": 0
}

// 2. Progress updates...
{
  "type": "playlist_status",
  "playlist_id": 102,
  "status": "downloading",
  "total_items": 3,
  "downloaded_items": 1
}

{
  "type": "playlist_status",
  "playlist_id": 102,
  "status": "downloading",
  "total_items": 3,
  "downloaded_items": 2
}

// 3. All items downloaded successfully
{
  "type": "playlist_status",
  "playlist_id": 102,
  "status": "ready",
  "total_items": 3,
  "downloaded_items": 3
}
```

---

## Data Models

### AuthModel

```typescript
{
  access: string;          // JWT access token
  refresh: string;         // JWT refresh token
  expires_in: number;      // Expiration time in seconds
}
```

---

### DeviceModel

```typescript
{
  sn_number: string;       // Serial number (unique)
  brand: string;           // Brand name
  model: string;           // Model name
  manufacturer: string;    // Manufacturer
  os_version: string;      // Android OS version
  screen_resolution: string; // Resolution (e.g., "1920x1080")
  total_storage: string;   // Total storage
  free_storage: string;    // Free storage
  mac_address?: string;    // MAC address (optional)
  app_version: string;     // App version
  ip_address?: string;     // IP address (optional)
  brightness: number;      // Brightness (0-100), default: 50
  volume: number;          // Volume (0-100), default: 50
}
```

---

### PlaylistModel

```typescript
{
  id: number;              // Playlist ID
  name: string;            // Playlist name
  width: number;           // Canvas width
  height: number;          // Canvas height
  duration: number;        // Total duration (seconds)
  media_items: MediaItem[]; // Media items list
  playback_config: PlaybackConfig;
  status: PlaylistStatus;
}
```

---

### MediaItemModel

```typescript
{
  media_id: number;        // Media ID
  order: number;           // Playback order
  media_name: string;      // File name
  media_type: string;      // "image" or "video"
  mimetype: string;        // MIME type
  media_url: string;       // Download URL
  local_path?: string;     // Local file path (after download)
  file_size: number;       // File size (bytes)
  downloaded: boolean;     // Download status
  download_date?: string;  // Download timestamp (ISO 8601)
  checksum: string;        // MD5 checksum
  layout: MediaLayout;
  timing: MediaTiming;
  effects: MediaEffects;
  n_time_play: number;     // Number of plays
}
```

---

### WebSocketMessageModel (Server → Client)

```typescript
{
  action: string;          // Action type (see WebSocket section)
  playlist_id?: number;    // Target playlist ID (optional)
  media_id?: number;       // Target media ID (optional)
  media_index?: number;    // Target media index (optional)
  text_overlay?: TextOverlayConfig; // Text overlay config (optional)
  brightness?: number;     // Brightness value (optional)
  volume?: number;         // Volume value (optional)
}
```

**Supported Actions:**
- `play`, `pause`, `next`, `previous`
- `reload_playlist`, `switch_playlist`, `play_media`
- `show_text_overlay`, `hide_text_overlay`
- `set_brightness`, `set_volume`

---

### PlaylistStatusMessageModel (Client → Server)

```typescript
{
  type: "playlist_status"; // Always "playlist_status"
  playlist_id: number;     // Playlist ID
  status: string;          // Status type
  total_items?: number;    // Total media items (optional)
  downloaded_items?: number; // Downloaded count (optional)
  missing_files?: string[]; // Failed file names (optional)
  error?: string;          // Error message (optional)
}
```

**Supported Status Values:**
- `ready` - All media downloaded, playlist ready to play
- `downloading` - Download in progress
- `partial` - Some media downloaded, some failed
- `failed` - Download completely failed

**Status-Specific Fields:**

| Status | Required Fields | Optional Fields |
|--------|----------------|-----------------|
| `ready` | `type`, `playlist_id`, `status` | `total_items`, `downloaded_items` |
| `downloading` | `type`, `playlist_id`, `status`, `total_items`, `downloaded_items` | - |
| `partial` | `type`, `playlist_id`, `status`, `total_items`, `downloaded_items`, `missing_files` | - |
| `failed` | `type`, `playlist_id`, `status` | `total_items`, `downloaded_items`, `error` |

---

## Error Handling

### Standard Error Response

```json
{
  "message": "Error description",
  "status_code": 400
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200  | OK - Request successful |
| 201  | Created - Resource created |
| 400  | Bad Request - Invalid parameters |
| 401  | Unauthorized - Invalid or missing token |
| 404  | Not Found - Resource not found |
| 500  | Internal Server Error - Server error |

### Common Error Scenarios

**1. Token Expired**
```json
{
  "message": "Token has expired",
  "status_code": 401
}
```
**Solution:** Use refresh token to get new access token.

**2. Invalid Credentials**
```json
{
  "message": "Invalid username or password",
  "status_code": 400
}
```

**3. Network Error**
```json
{
  "message": "Network error - please check internet connection",
  "status_code": null
}
```

**4. Download Failure**
```json
{
  "message": "Failed to download media: Connection timeout",
  "status_code": null
}
```

---

## Implementation Guidelines

### Sending Playlist Status Updates

**When to send status updates:**

1. **On Download Start:**
   - Status: `downloading`
   - Send immediately when download begins
   - Include `total_items` and `downloaded_items: 0`

2. **During Download:**
   - Status: `downloading`
   - Send after each media file completes downloading
   - Update `downloaded_items` count
   - Optional: Can throttle to avoid too many updates (e.g., max 1 update per second)

3. **On Successful Completion:**
   - Status: `ready`
   - Send when ALL media files downloaded successfully
   - All checksums verified
   - `downloaded_items` equals `total_items`

4. **On Partial Success:**
   - Status: `partial`
   - Send when download completes but some files failed
   - Include `missing_files` array with failed file names
   - Still playable with downloaded items

5. **On Complete Failure:**
   - Status: `failed`
   - Send when no files could be downloaded
   - Include `error` message describing the issue
   - Examples: "Network timeout", "Storage full", "All downloads failed"

**Implementation Example (Pseudocode):**

```dart
// Start download
sendPlaylistStatus(
  playlistId: 101,
  status: 'downloading',
  totalItems: 7,
  downloadedItems: 0
);

// After each media item downloads
for (mediaItem in playlist.mediaItems) {
  try {
    await downloadMedia(mediaItem);
    downloadedCount++;

    // Update progress
    sendPlaylistStatus(
      playlistId: 101,
      status: 'downloading',
      totalItems: 7,
      downloadedItems: downloadedCount
    );
  } catch (error) {
    missingFiles.add(mediaItem.mediaName);
  }
}

// After download completes
if (missingFiles.isEmpty) {
  // All files downloaded successfully
  sendPlaylistStatus(
    playlistId: 101,
    status: 'ready',
    totalItems: 7,
    downloadedItems: 7
  );
} else if (downloadedCount > 0) {
  // Some files downloaded
  sendPlaylistStatus(
    playlistId: 101,
    status: 'partial',
    totalItems: 7,
    downloadedItems: downloadedCount,
    missingFiles: missingFiles
  );
} else {
  // No files downloaded
  sendPlaylistStatus(
    playlistId: 101,
    status: 'failed',
    totalItems: 7,
    downloadedItems: 0,
    error: 'All downloads failed'
  );
}
```

---

## Best Practices

### 1. Token Management
- Store tokens securely in SharedPreferences
- Refresh access token before expiry (5 min buffer recommended)
- Handle 401 errors by refreshing token automatically

### 2. Media Download
- Verify checksums after download
- Use smart caching (check file existence and checksum before re-download)
- Download in background to avoid blocking UI
- Report progress to user

### 3. Offline Mode
- Cache playlists and media locally using Isar database
- Fall back to local data when network unavailable
- Sync with server when connection restored

### 4. WebSocket
- Reconnect automatically on disconnection
- Handle connection errors gracefully
- Send periodic heartbeat/ping to keep connection alive

### 5. Error Handling
- Use `try-catch` for all network operations
- Log errors for debugging
- Show user-friendly error messages
- Implement retry logic for failed requests

---

## API Flow Examples

### Complete Startup Flow

```
1. App Launch
   ├─> Check stored access token
   ├─> If expired: Refresh token
   └─> If no token: Show login screen

2. Login
   ├─> POST /auth/token/
   └─> Store access & refresh tokens

3. Device Registration
   ├─> Collect device info
   ├─> POST /admin/cloud/device/register/
   └─> Store device SN

4. Fetch Playlists
   ├─> GET /admin/cloud/playlists?sn_number={sn}
   └─> Save playlists to Isar DB

5. Download Media
   ├─> For each media_item:
   │   ├─> Check if file exists locally
   │   ├─> Verify checksum
   │   └─> Download if missing/corrupt
   └─> Update download status in DB

6. WebSocket Connection
   ├─> Connect to wss://.../?token={token}&sn_number={sn}
   ├─> Listen for control messages
   └─> Send status updates

7. Start Playback
   ├─> Load playlist from local DB
   ├─> Play media items in order
   └─> Capture screenshots periodically
```

---

## Changelog

### Version 1.2 (2025-01-15)
- ✅ Added `ready_playlists` notification message
- ✅ Device now sends all ready playlist IDs after reload/switch
- ✅ Enhanced reload_playlist and switch_playlist flow documentation

### Version 1.1 (2025-01-15)
- ✅ Added comprehensive Client → Server WebSocket messages
- ✅ Added 4 playlist status types: `ready`, `downloading`, `partial`, `failed`
- ✅ Added detailed status update flow examples
- ✅ Added implementation guidelines for playlist status reporting
- ✅ Added PlaylistStatusMessageModel to data models
- ✅ Enhanced documentation with real-world scenarios

### Version 1.0 (2025-01-15)
- Initial API documentation
- Authentication endpoints
- Device registration
- Playlist and media management
- WebSocket real-time control (Server → Client)
- Complete data models

---

## Support

For backend API issues or questions, contact the backend development team.

**API Endpoint:** `https://admin-led.ohayo.uz/api/v1`
**Documentation Date:** 2025-01-15
