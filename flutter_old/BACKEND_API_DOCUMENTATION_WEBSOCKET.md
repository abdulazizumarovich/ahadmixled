
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
