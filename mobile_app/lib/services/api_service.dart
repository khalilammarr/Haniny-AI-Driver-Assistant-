import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Backend server URL - auto-configured
  static const String baseUrl = 'http://192.168.1.159:8000';

  Future<String?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token'),
        body: {
          'username': email,
          'password': password,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'];

        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('email', email);

        return null; // Success
      } else if (response.statusCode == 401) {
        return 'Incorrect username or password';
      } else {
        return 'Login failed: ${response.statusCode}';
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return 'Connection error: Server timeout';
      }
      return 'Connection error: $e';
    }
  }

  /// Check if backend server is reachable
  Future<bool> checkServerHealth() async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/health'),
      )
          .timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'ok';
      }
      return false;
    } catch (e) {
      print('❌ Server health check failed: $e');
      return false;
    }
  }

  Future<String?> register(
      String email, String password, String fullName, String carModel) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'car_model': carModel,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        return data['detail'] ?? 'Email already registered';
      } else {
        return 'Registration failed: ${response.statusCode}';
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        return 'Connection error: Server timeout';
      }
      return 'Connection error: $e';
    }
  }

  Future<String?> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify?email=$email&code=$code'),
      );

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        final data = json.decode(response.body);
        return data['detail'] ?? 'Verification failed';
      }
    } catch (e) {
      return 'Connection error: $e';
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching stats: $e');
      return null;
    }
  }

  Future<bool> unpairDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/unpair'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Unpair failed: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error unpairing device: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDailyStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/stats/daily'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching daily stats: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWeeklyStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/stats/weekly'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching weekly stats: $e');
      return null;
    }
  }

  Future<bool> pairDevice(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/pair?device_id=$deviceId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error pairing device: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getDeviceUser(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/device/$deviceId/user'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting device user: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> startTrip(String deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trips/start?device_id=$deviceId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error starting trip: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> endTrip(int tripId,
      {int? finalScore, double? distance}) async {
    try {
      final params = <String, String>{};
      if (finalScore != null) params['final_score'] = finalScore.toString();
      if (distance != null) params['distance'] = distance.toString();

      final uri = Uri.parse('$baseUrl/trips/$tripId/end')
          .replace(queryParameters: params);
      final response = await http.put(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error ending trip: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('email');
  }
}
