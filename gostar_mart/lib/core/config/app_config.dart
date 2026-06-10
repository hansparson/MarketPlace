/// AppConfig — konfigurasi environment untuk Gostar-Mart Flutter App
///
/// Cara penggunaan:
///   Development : flutter run
///   Production  : flutter run --dart-define=PRODUCTION=true
///
import 'dart:io';

class AppConfig {
  // Env di-inject via --dart-define saat build/run
  static const bool _isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: false);

  // ─── API URLs ───────────────────────────────────────────────────────────────

  /// Base URL untuk API backend
  static String get baseUrl {
    if (_isProduction) {
      return 'https://gostar.id/api'; // Production
    }
    // Development: Android emulator butuh 10.0.2.2, iOS/desktop pakai localhost
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:8080/api';
  }

  /// Base URL untuk gambar dari MinIO via Nginx proxy
  /// Nginx meneruskan /storage/* → minio:9000/marketplace/*
  static String get imageBaseUrl {
    if (_isProduction) {
      return 'https://gostar.id/storage'; // Production: Nginx proxy ke MinIO
    }
    // Development: gunakan IP LAN Mac agar emulator/simulator bisa mengakses
    // Nginx lokal pada port 80 yang sudah dikonfigurasi /storage/ → minio:9000
    // Jika tidak ada Nginx lokal, langsung ke MinIO API port 9000
    final host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    return 'http://$host:9000/marketplace';
  }

  /// Konversi object_key MinIO menjadi URL gambar penuh
  static String getImageUrl(String? objectKey) {
    if (objectKey == null || objectKey.isEmpty) return '';
    final clean = objectKey.startsWith('/') ? objectKey.substring(1) : objectKey;
    return '$imageBaseUrl/$clean';
  }

  // ─── Info ───────────────────────────────────────────────────────────────────

  static bool get isProduction => _isProduction;
}
