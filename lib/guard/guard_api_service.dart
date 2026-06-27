import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  static Future<Map<String, String>> get _authOnlyHeaders async {
    final accessToken = await token;
    return {
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


  static Future<Map<String, dynamic>> submitGuardReportProof({
    required String issueTitle,
    required String issueCode,
    required List<XFile> images,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/v1/reports/wrong-parking'),
      );
      request.headers.addAll(await _authOnlyHeaders);
      request.fields.addAll({
        'lat': '0.0',
        'lng': '0.0',
        'captured_at': DateTime.now().toIso8601String(),
        'evidence_mode': 'PHOTOS',
        'vehicle_number': 'PENDING',
        'selected_reason': issueTitle,
        'selected_reason_code': issueCode,
      });

      final labels = ['front', 'back', 'left', 'right'];
      for (var i = 0; i < 4; i++) {
        final image = images[i];
        request.files.add(http.MultipartFile.fromBytes(
          labels[i],
          await image.readAsBytes(),
          filename: image.name,
        ));
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body};
      }
      return {'success': false, 'message': _messageFromBody(body, 'Report proof failed')};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitGuardHelpProof({
    required String issueTitle,
    required XFile image,
  }) async {
    return _submitGuardNotificationProof(
      path: '/api/guard/helped-vehicle',
      image: image,
      fields: {'parking_error': issueTitle},
      fallback: 'Help proof failed',
    );
  }

  static Future<Map<String, dynamic>> submitGuardEmergencyProof({
    required String issueTitle,
    required XFile image,
  }) async {
    return _submitGuardNotificationProof(
      path: '/api/guard/emergency-alert',
      image: image,
      fields: {'situation': issueTitle},
      fallback: 'Emergency proof failed',
    );
  }

  static Future<Map<String, dynamic>> _submitGuardNotificationProof({
    required String path,
    required XFile image,
    required Map<String, String> fields,
    required String fallback,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'));
      request.headers.addAll(await _authOnlyHeaders);
      request.fields.addAll(fields);
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        await image.readAsBytes(),
        filename: image.name,
      ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body};
      }
      return {'success': false, 'message': _messageFromBody(body, fallback)};
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> attachGuardReportPlate({
    required String reportId,
    required String vehicleNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/guard/reports/$reportId/attach-plate'),
      headers: await _headers,
      body: jsonEncode({'vehicle_number': vehicleNumber}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return {'success': true, 'data': body};
    return {'success': false, 'message': _messageFromBody(body, 'Plate attach failed')};
  }

  static Future<Map<String, dynamic>> attachGuardNotificationPlate({
    required String notificationId,
    required String vehicleNumber,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/guard/notifications/$notificationId/attach-plate'),
      headers: await _headers,
      body: jsonEncode({'vehicle_number': vehicleNumber}),
    );
    final body = jsonDecode(response.body);
    if (response.statusCode == 200) return {'success': true, 'data': body};
    return {'success': false, 'message': _messageFromBody(body, 'Plate attach failed')};
  }

  static String _messageFromBody(dynamic body, String fallback) {
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is Map && detail['message'] != null) return detail['message'].toString();
      final message = body['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return fallback;
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
