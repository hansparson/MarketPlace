import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Konversi object_key MinIO menjadi URL gambar yang bisa diakses
  static String getImageUrl(String? objectKey) => AppConfig.getImageUrl(objectKey);

  // Auth: Sync Google Login
  Future<Map<String, dynamic>> loginGoogle(String googleId, String email) async {
    try {
      final response = await _dio.post('/mart-client/login/google', data: {
        'google_id': googleId,
        'email': email,
      });
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error'] ?? 'Gagal login via Google');
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Auth: Complete Profile
  Future<Map<String, dynamic>> completeProfile(
      String id, String name, String phone, String referralCode) async {
    try {
      final response = await _dio.put('/mart-client/profile', data: {
        'id': id,
        'name': name,
        'phone': phone,
        'referral_code': referralCode,
      });
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error'] ?? 'Gagal melengkapi profil');
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Categories: Get List
  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _dio.get('/categories');
      return response.data['message_data'] ?? [];
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error'] ?? 'Gagal memuat kategori');
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Products: Get List
  Future<List<dynamic>> getProducts({String? query, String? categoryId, int limit = 20, int offset = 0}) async {
    try {
      final Map<String, dynamic> queryParams = {
        'limit': limit,
        'offset': offset,
      };
      if (query != null && query.isNotEmpty) {
        queryParams['q'] = query;
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['cat'] = categoryId;
      }

      final response = await _dio.get('/products', queryParameters: queryParams);
      return response.data['message_data'] ?? [];
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error'] ?? 'Gagal memuat produk');
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Products: Get Detail
  Future<Map<String, dynamic>> getProductDetail(String id) async {
    try {
      final response = await _dio.get('/products/$id');
      return response.data['message_data'] ?? {};
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error'] ?? 'Gagal memuat detail produk');
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Public: Get System Configurations (admin_whatsapp_number, fees, etc.)
  Future<Map<String, String>> getPublicConfigs() async {
    try {
      final response = await _dio.get('/public/configs');
      final data = response.data['message_data'];
      if (data is Map) {
        return Map<String, String>.fromEntries(
          data.entries.map((e) => MapEntry(e.key.toString(), e.value.toString())),
        );
      }
      return {};
    } catch (e) {
      // Return empty map on failure so the app doesn't crash
      return {};
    }
  }

  // Favorites: Toggle Favorite
  Future<bool> toggleFavorite(String clientId, String productId) async {
    try {
      final response = await _dio.post('/mart-client/favorites/toggle', data: {
        'client_id': clientId,
        'product_id': productId,
      });
      return response.data['is_favorite'] ?? false;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error'] ?? 'Gagal mengubah status favorit');
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Favorites: Get List of Favorited Products
  Future<List<dynamic>> getFavorites(String clientId) async {
    try {
      final response = await _dio.get('/mart-client/favorites', queryParameters: {
        'client_id': clientId,
      });
      return response.data['message_data'] ?? [];
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data?['error'] ?? 'Gagal memuat produk favorit');
      }
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // FCM: Register/Update Device Token
  Future<void> updateDeviceToken(String clientId, String token) async {
    try {
      final deviceType = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
      await _dio.post('/mart-client/device-token', data: {
        'client_id': clientId,
        'token': token,
        'device_type': deviceType,
      });
    } catch (e) {
      print('Failed to update FCM device token: $e');
    }
  }

  // FCM: Delete Device Token
  Future<void> deleteDeviceToken(String token) async {
    try {
      await _dio.delete('/mart-client/device-token', data: {
        'token': token,
      });
    } catch (e) {
      print('Failed to delete FCM device token: $e');
    }
  }
}
