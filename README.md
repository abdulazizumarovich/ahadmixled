# Android LED Player 📺

Professional Android application for LED screens to display advertisements (video and images) with remote control capabilities via WebSocket.

![Build Status](https://github.com/Jaloliddin-Fozilov/ahadmixled/workflows/Android%20Build%20and%20Release/badge.svg)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![API](https://img.shields.io/badge/API-21%2B-brightgreen.svg?style=flat)](https://android-arsenal.com/api?level=21)

## 🌟 Features

### Core Functionality
- ✅ **Video & Image Playback** - Seamless playback with ExoPlayer and Coil
- ✅ **WebSocket Control** - Real-time remote control from admin panel
- ✅ **Offline-First** - Works indefinitely without internet after setup
- ✅ **Auto-Sync** - Automatic playlist synchronization when online
- ✅ **Text Overlays** - Scrolling and static text with customization
- ✅ **Screenshot Capture** - Automatic screenshot upload for monitoring

### Advanced Features
- 🔄 **Auto-Reconnect** - Automatic WebSocket and network reconnection
- 🔐 **Secure Auth** - Token-based authentication with auto-refresh
- 💾 **Local Storage** - Room database with efficient caching
- 📊 **Storage Monitoring** - Real-time storage tracking and reporting
- 🎯 **Checksum Verification** - MD5 verification for downloaded media
- 🌐 **Network Awareness** - Smart sync based on network availability

## 🏗️ Architecture

This project follows **Clean Architecture** principles with clear separation of concerns:

```
app/
├── data/              # Data layer (repositories, database, network)
│   ├── local/        # Room database, SharedPreferences
│   ├── remote/       # Retrofit APIs, WebSocket
│   └── repository/   # Repository implementations
├── domain/           # Business logic layer
│   ├── model/       # Domain models
│   ├── repository/  # Repository interfaces
│   └── usecase/     # Use cases (coming soon)
├── presentation/     # UI layer (Activities, ViewModels)
│   ├── splash/
│   ├── auth/
│   └── player/
├── di/              # Dependency injection (Hilt)
└── util/            # Utilities and helpers
```

### Design Patterns
- **MVVM** - Model-View-ViewModel pattern
- **Repository Pattern** - Data abstraction layer
- **Singleton** - Single instances for managers
- **Observer** - Flow-based reactive programming
- **Dependency Injection** - Hilt for DI

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| Language | Kotlin |
| Architecture | Clean Architecture + MVVM |
| DI | Hilt |
| Database | Room |
| Networking | Retrofit + OkHttp |
| WebSocket | OkHttp WebSocket |
| Media Player | ExoPlayer (Media3) |
| Image Loading | Coil |
| Async | Coroutines + Flow |
| Security | EncryptedSharedPreferences |
| Logging | Timber |
| UI | ViewBinding + Material Design |

## 📱 Screenshots

_Coming soon..._

## 🚀 Getting Started

### Prerequisites
- Android Studio Hedgehog (2023.1.1) or newer
- JDK 17
- Android SDK 21+
- Gradle 8.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Jaloliddin-Fozilov/ahadmixled.git
   cd ahadmixled
   ```

2. **Open in Android Studio**
   - File → Open → Select project directory
   - Wait for Gradle sync to complete

3. **Configure backend URL** (Optional)
   - Open `app/src/main/java/uz/iportal/axadmixled/util/Constants.kt`
   - Update `BASE_URL` if using different backend

4. **Build and Run**
   ```bash
   ./gradlew assembleDebug
   ```
   Or click ▶️ Run in Android Studio

## 🔧 Configuration

### Backend URLs
Default configuration:
```kotlin
const val BASE_URL = "https://admin-led.ohayo.uz/"
const val WEBSOCKET_URL = "wss://admin-led.ohayo.uz/ws/cloud/tb_device/"
```

### Permissions Required
- `INTERNET` - Network communication
- `ACCESS_NETWORK_STATE` - Network monitoring
- `READ_EXTERNAL_STORAGE` - Media file access
- `WRITE_EXTERNAL_STORAGE` - Media file storage
- `WAKE_LOCK` - Keep screen on during playback
- `FOREGROUND_SERVICE` - Background operations

## 📖 API Documentation

### Authentication
```
POST /api/v1/auth/token/
POST /api/v1/auth/token/refresh/
```

### Device Management
```
POST /api/v1/admin/cloud/device/register/
GET  /api/v1/admin/cloud/device/{sn_number}/
```

### Playlist Management
```
GET  /api/v1/admin/cloud/playlists?sn_number={sn_number}
GET  /api/v1/admin/cloud/playlists/{id}/
```

### WebSocket Commands
Connect to: `wss://admin-led.ohayo.uz/ws/cloud/tb_device/?token={token}&sn_number={sn}`

Supported commands:
- `play`, `pause`, `next`, `previous`
- `switch_playlist`, `reload_playlist`
- `show_text_overlay`, `hide_text_overlay`
- `set_brightness`, `set_volume`
- `cleanup_old_playlists`

## 🧪 Testing

Run unit tests:
```bash
./gradlew testDebugUnitTest
```

Run instrumented tests:
```bash
./gradlew connectedAndroidTest
```

Run lint checks:
```bash
./gradlew lintDebug
```

## 📦 Building

### Debug Build
```bash
./gradlew assembleDebug
```
Output: `app/build/outputs/apk/debug/app-debug.apk`

### Release Build
```bash
./gradlew assembleRelease
```
Output: `app/build/outputs/apk/release/app-release-unsigned.apk`

### Signing Configuration
Create `keystore.properties` in project root:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/keystore.jks
```

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow [Kotlin Coding Conventions](https://kotlinlang.org/docs/coding-conventions.html)
- Use meaningful variable and function names
- Add comments for complex logic
- Write unit tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Jaloliddin Fozilov** - *Initial work* - [@Jaloliddin-Fozilov](https://github.com/Jaloliddin-Fozilov)

## 🙏 Acknowledgments

- [Anthropic Claude](https://www.anthropic.com) - AI assistance for development
- [ExoPlayer](https://exoplayer.dev/) - Media playback
- [Square](https://square.github.io/) - Retrofit, OkHttp
- [Google](https://developer.android.com/) - Android, Hilt, Room

## 📞 Support

For issues and feature requests, please use [GitHub Issues](https://github.com/Jaloliddin-Fozilov/ahadmixled/issues).

For questions and discussions, contact: [your-email@example.com](mailto:your-email@example.com)

## 🗺️ Roadmap

- [ ] Add unit tests coverage (80%+)
- [ ] Implement WorkManager for background sync
- [ ] Add analytics integration
- [ ] Support for Android TV
- [ ] Multi-language support (Uzbek, Russian, English)
- [ ] Dark theme support
- [ ] Video streaming support
- [ ] Advanced playlist scheduling

---

**Made with ❤️ in Uzbekistan**
