import 'dart:io';

/// AppConfig — konfigurasi environment untuk Flutter App
///
/// Cara penggunaan:
///   Development : flutter run
///   Production  : flutter run --dart-define=PRODUCTION=true
///                 flutter build apk --dart-define=PRODUCTION=true
///
class AppConfig {
  // Env di-inject via --dart-define saat build/run
  static const bool _isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: false);

  // ─── API URLs ───────────────────────────────────────────────────────────────

  /// Base URL untuk API backend
  static String get baseUrl {
    if (_isProduction) {
      return 'https://gostar.id/api'; // Production: melalui Cloudflare → Nginx → Backend
    }
    // Jika berjalan di emulator Android, gunakan 10.0.2.2 untuk mengakses localhost host machine
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:8080/api'; // Development: langsung ke backend lokal
  }

  /// Base URL untuk gambar dari MinIO via Nginx
  static String get imageBaseUrl {
    if (_isProduction) {
      return 'https://gostar.id/storage'; // Production: melalui Nginx proxy ke MinIO
    }
    // Jika berjalan di emulator Android, gunakan 10.0.2.2 untuk mengakses localhost host machine
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host/storage'; // Development: Nginx lokal (docker-compose.dev.yml)
  }

  // ─── Info ───────────────────────────────────────────────────────────────────

  static bool get isProduction => _isProduction;
  static String get environmentName => _isProduction ? 'PRODUCTION' : 'DEVELOPMENT';

  static void printInfo() {
    // ignore: avoid_print
    print('╔══════════════════════════════════════╗');
    // ignore: avoid_print
    print('║  GostarID App — $environmentName  ');
    // ignore: avoid_print
    print('║  API: $baseUrl');
    // ignore: avoid_print
    print('╚══════════════════════════════════════╝');
  }
}
