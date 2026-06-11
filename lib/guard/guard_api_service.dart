import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GuardApiService {
  static final String baseUrl =
      dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';

  static Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('guard_access_token');
  }

  static Future<Map<String, String>> get _headers async {
    final accessToken = await token;
    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  static Future<Map<String, dynamic>> login({
    required String mobileNumber,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/guard/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile_number': mobileNumber,
        'password': password,
        'app_version': '1.0.0',
      }),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guard_access_token', body['access_token']);
      await prefs.setString('guard_name', body['guard']['full_name']);
      return {'success': true, 'data': body};
    }
    return {'success': false, 'message': body['detail'] ?? 'Login failed'};
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('guard_access_token');
    await prefs.remove('guard_name');
  }

  static Future<Map<String, dynamic>> verifyVehicle(String vehicleNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/guard/verify-vehicle'),
      headers: await _headers,
      body: jsonEncode({'vehicle_number': vehicleNumber}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return {'success': true, 'data': body};
    return {'success': false, 'message': body['detail'] ?? 'Verification failed'};
  }

  static Future<Map<String, dynamic>> logEntryExit({
    required String vehicleNumber,
    required String direction,
    String? visitorId,
    String? parkingSpaceId,
    String? photoUrl,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/guard/entry-exit'),
      headers: await _headers,
      body: jsonEncode({
        'vehicle_number': vehicleNumber,
        'direction': direction,
        'visitor_id': visitorId,
        'parking_space_id': parkingSpaceId,
        'photo_url': photoUrl,
        'notes': notes,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return {'success': true, 'data': body};
    return {'success': false, 'message': body['detail'] ?? 'Log failed'};
  }

  static Future<Map<String, dynamic>> shiftCheckIn() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/guard/shift/check-in'),
      headers: await _headers,
    );
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode == 200) return {'success': true, 'data': body};
    return {'success': false, 'message': body?['detail'] ?? 'Check-in failed'};
  }

  static Future<Map<String, dynamic>> shiftCheckOut() async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/guard/shift/check-out'),
      headers: await _headers,
    );
    final body = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode == 200) return {'success': true, 'data': body};
    return {'success': false, 'message': body?['detail'] ?? 'Check-out failed'};
  }

  static Future<Map<String, dynamic>> createAlert({
    required String title,
    required String body,
    String eventType = 'GUARD_ALERT',
    String severity = 'HIGH',
    String? vehicleNumber,
    double? latitude,
    double? longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/guard/alerts'),
      headers: await _headers,
      body: jsonEncode({
        'title': title,
        'body': body,
        'event_type': eventType,
        'severity': severity,
        'vehicle_number': vehicleNumber,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) return {'success': true, 'data': decoded};
    return {'success': false, 'message': decoded['detail'] ?? 'Alert failed'};
  }

  static Future<Map<String, dynamic>> performance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/guard/performance'),
      headers: await _headers,
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return {'success': true, 'data': body};
    return {'success': false, 'message': body['detail'] ?? 'Failed to load performance'};
  }
}
