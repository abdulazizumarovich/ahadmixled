# ✅ DEBUG LOGGING - TAYYOR KOD

Import'lar allaqachon qo'shilgan! Endi faqat logging call'larni qo'shing:

## 1. lib/features/presentation/blocs/video/video_bloc.dart

### A) _onSelectPlaylist metodida (line ~366 atrofida):

**TOPISH:** Bu qatorni toping:
```dart
emit(currentState.copyWith(
  currentPlaylist: selectedPlaylist,
  currentMediaIndex: 0,
  isPlaying: true,
));
```

**KEYIN QUYIDAGINI QO'SHING:**
```dart
// CRITICAL DEBUG: Log state emit
DownloadDebugLogger.logStateEmit(
  eventName: 'SelectPlaylist',
  isWebSocketReload: false,
  playlistName: selectedPlaylist.name,
  playlistId: selectedPlaylist.id,
);
```

### B) _onLoadDeviceScreens metodida (line ~175 atrofida):

**TOPISH:** Bu qatorni toping:
```dart
emit(VideoLoaded(
  deviceScreens: deviceScreens,
  playlists: playlists,
  currentPlaylist: currentPlaylist,
  currentMediaIndex: mediaIndex,
  isPlaying: wasPlaying,
  textOverlayConfig: textOverlayConfig,
  brightness: brightness,
  volume: volume,
  isWebSocketReload: true,
));
```

**KEYIN QUYIDAGINI QO'SHING:**
```dart
// CRITICAL DEBUG: Log state emit
DownloadDebugLogger.logStateEmit(
  eventName: 'LoadDeviceScreens',
  isWebSocketReload: true,
  playlistName: currentPlaylist?.name,
  playlistId: currentPlaylist?.id,
);
```

---

## 2. lib/features/presentation/screens/home_screen.dart

### Listener ichida (line ~147 atrofida):

**TOPISH:** Bu kodning o'rniga:
```dart
if (videoState.isWebSocketReload) {
  AppLogger.info('🔄 [APP] WebSocket reload detected via flag - checking for downloads');
  _handleWebSocketReload(videoState);
} else {
  AppLogger.info('🔄 [APP] Local state change - NO download check');
}
```

**ALMASHTIRING:**
```dart
if (videoState.isWebSocketReload) {
  // CRITICAL DEBUG: Log download trigger
  DownloadDebugLogger.logHomeScreenReceive(
    isWebSocketReload: true,
    playlistName: videoState.currentPlaylist?.name,
    willTriggerDownload: true,
  );

  AppLogger.info('🔄 [APP] WebSocket reload detected via flag - checking for downloads');
  _handleWebSocketReload(videoState);
} else {
  // CRITICAL DEBUG: Log NO download
  DownloadDebugLogger.logHomeScreenReceive(
    isWebSocketReload: false,
    playlistName: videoState.currentPlaylist?.name,
    willTriggerDownload: false,
  );

  AppLogger.info('🔄 [APP] Local state change - NO download check');
}
```

---

## 3. YUQORIDAGI KODLARNI QO'SHGANDAN KEYIN:

Flutter'ni qayta ishga tushiring:
```bash
flutter run
```

## 4. SWITCH PLAYLIST QILING VA LOGNI KO'RING:

Console'da quyidagi formatda loglar ko'rinadi:

### ✅ TO'G'RI LOG (DOWNLOAD YO'Q):
```
╔═══════════════════════════════════════════════════════════════════════════
║ [📤 VIDEO_BLOC_EMIT] Event: SelectPlaylist
║ Playlist: My Video Playlist (ID: 102)
║ isWebSocketReload: ✅ FALSE (NO DOWNLOAD)
╚═══════════════════════════════════════════════════════════════════════════

╔═══════════════════════════════════════════════════════════════════════════
║ [✅ HOME_SCREEN_LISTENER] State received
║ Playlist: My Video Playlist
║ isWebSocketReload: false
║ Action: NO DOWNLOAD CHECK
╚═══════════════════════════════════════════════════════════════════════════
```

### ❌ NOTO'G'RI LOG (DOWNLOAD KETYAPTI):
```
╔═══════════════════════════════════════════════════════════════════════════
║ [📤 VIDEO_BLOC_EMIT] Event: SelectPlaylist
║ Playlist: My Video Playlist (ID: 102)
║ isWebSocketReload: 🚨 TRUE (WILL TRIGGER DOWNLOAD!)  <-- BU NOTO'G'RI!
╚═══════════════════════════════════════════════════════════════════════════
```

## 5. LOGLARNI MENGA YUBORINg:

Agar download ketyapti bo'lsa, quyidagi loglarni to'liq copy-paste qilib yuboring:
1. Barcha `╔═══` bilan boshlanadigan loglar
2. Switch qilayotganingizda qanday ketma-ketlikda chiqayotgani

Men aniq sababni topaman va tuzataman!

---

## QISQACHA:

1. ✅ Import'lar allaqachon qo'shilgan
2. ➕ 3 ta joyga logging call qo'shing (yuqoridagi kod)
3. ▶️ Flutter'ni qayta ishga tushiring
4. 🔀 Switch playlist qiling
5. 📋 Console logni ko'ring va menga yuboring

SHUNDA MEN 100% ANIQ SABABNI TOPAMAN! 🎯
