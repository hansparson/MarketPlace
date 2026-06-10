import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static String get _baseUrl => AppConfig.baseUrl;
  static String get _imageBaseUrl => AppConfig.imageBaseUrl;

  /// Converts a MinIO object_key to a full image URL via Nginx proxy
  static String getImageUrl(String? objectKey) {
    if (objectKey == null || objectKey.isEmpty) return '';
    final clean = objectKey.startsWith('/') ? objectKey.substring(1) : objectKey;
    return '$_imageBaseUrl/$clean';
  }


  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// GET /client/stats — returns stats + referral_code + recent_activities
  static Future<Map<String, dynamic>?> getStats() async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/client/stats'),
        headers: _authHeaders(token),
      );
        if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final messageData = data['message_data'];
        
        // Save referral_code if present
        if (messageData != null && messageData['referral_code'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('referral_code', messageData['referral_code'].toString());
        }
        
        return messageData;
      }
    } catch (_) {}
    return null;
  }

  /// GET /api/products — public product list
  static Future<List<dynamic>> getProducts({int limit = 20, int offset = 0}) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/products?limit=$limit&offset=$offset'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['message_data'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/leaderboard — get top 10 commissions leaderboard
  static Future<List<dynamic>> getLeaderboard() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/leaderboard'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['message_data'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  /// GET /api/products/:id — get full product details with assets
  static Future<Map<String, dynamic>?> getProductDetail(String id) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/products/$id'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['message_data'];
      }
    } catch (e) {
      print('Error fetching product detail: $e');
    }
    return null;
  }

  /// GET /client/payouts — payout history
  static Future<List<dynamic>> getMyPayouts() async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/client/payouts'),
        headers: _authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['message_data'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  /// GET /client/commissions — commission history
  static Future<List<dynamic>> getMyCommissions() async {
    final token = await _getToken();
    if (token == null) return [];
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/client/commissions'),
        headers: _authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['message_data'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  /// POST /leads — Submit buyer data
  static Future<Map<String, dynamic>?> submitLead(String productId, String refCode, String name, String phone) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/leads'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'product_id': productId,
          'ref_code': refCode,
          'name': name,
          'phone': phone,
        }),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error submitting lead: $e');
    }
    return null;
  }

  /// POST /client/track-share — Record that the user shared a product
  static Future<void> trackShare(String productId) async {
    final token = await _getToken();
    if (token == null) return;
    try {
      await http.post(
        Uri.parse('$_baseUrl/client/track-share?product_id=$productId'),
        headers: _authHeaders(token),
      );
    } catch (e) {
      print('Error tracking share: $e');
    }
  }

  /// GET /client/profile — load full profile data
  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/client/profile'),
        headers: _authHeaders(token),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['message_data'];
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
    return null;
  }

  /// PUT /client/profile — update name, email, bio
  static Future<bool> updateProfile({
    required String name,
    required String email,
    required String bio,
  }) async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final res = await http.put(
        Uri.parse('$_baseUrl/client/profile'),
        headers: _authHeaders(token),
        body: jsonEncode({'name': name, 'email': email, 'bio': bio}),
      );
      if (res.statusCode == 200) {
        // Update cached name in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('name', name);
        return true;
      }
    } catch (e) {
      print('Error updating profile: $e');
    }
    return false;
  }

  /// POST /client/verify-phone — mark phone as verified
  static Future<bool> verifyPhone() async {
    final token = await _getToken();
    if (token == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/client/verify-phone'),
        headers: _authHeaders(token),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error verifying phone: $e');
    }
    return false;
  }

  /// GET /api/auth/verify-dana-phone/:phone
  static Future<Map<String, dynamic>?> verifyDanaPhone(String phone) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/verify-dana-phone/$phone'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['message_data'];
      }
    } catch (e) {
      print('Error verifying DANA phone: $e');
    }
    return null;
  }

  /// GET /api/auth/registration-status/:userId
  static Future<Map<String, dynamic>?> checkRegistrationStatus(String userId) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/auth/registration-status/$userId'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['message_data'];
      }
    } catch (e) {
      print('Error checking registration status: $e');
    }
    return null;
  }

  /// POST /client/withdraw
  static Future<Map<String, dynamic>?> requestWithdrawal(int amount, String notes) async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/client/withdraw'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'amount': amount,
          'notes': notes,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      print('Error requesting withdrawal: $e');
    }
    return null;
  }

  /// POST /api/public/simulate-payment/:invoiceNumber
  static Future<bool> simulatePayment(String invoiceNumber) async {
    try {
      final res = await http.post(Uri.parse('$_baseUrl/public/simulate-payment/$invoiceNumber'));
      if (res.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('Error simulating payment: $e');
    }
    return false;
  }

  /// GET /api/public/configs - system configurations (no auth needed)
  static Future<Map<String, String>> getPublicConfigs() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/public/configs'));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['message_data'];
        if (data is Map) {
          return Map<String, String>.fromEntries(
            data.entries.map((e) => MapEntry(e.key.toString(), e.value.toString())),
          );
        }
      }
    } catch (e) {
      print('Error fetching public configs: $e');
    }
    return {};
  }

  /// POST /api/client/device-token - update device token
  static Future<bool> updateDeviceToken(String token) async {
    final authVal = await _getToken();
    if (authVal == null) return false;
    try {
      final deviceType = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown');
      final res = await http.post(
        Uri.parse('$_baseUrl/client/device-token'),
        headers: _authHeaders(authVal),
        body: jsonEncode({
          'token': token,
          'device_type': deviceType,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error updating device token: $e');
    }
    return false;
  }

  /// DELETE /api/client/device-token - delete device token
  static Future<bool> deleteDeviceToken(String token) async {
    final authVal = await _getToken();
    if (authVal == null) return false;
    try {
      final res = await http.delete(
        Uri.parse('$_baseUrl/client/device-token'),
        headers: _authHeaders(authVal),
        body: jsonEncode({
          'token': token,
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('Error deleting device token: $e');
    }
    return false;
  }
}
