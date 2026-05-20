import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class PlateScanResult {
  const PlateScanResult({
    required this.vehicleNumber,
    required this.rawText,
  });

  final String vehicleNumber;
  final String rawText;
}

class PlateScannerService {
  PlateScannerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  final RegExp _vehicleRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');
  static final String _aiBaseUrl =
      dotenv.env['AI_MODEL_URL'] ?? 'https://number-plate-reader.onrender.com';

  Future<PlateScanResult?> scanFromCamera() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (photo == null) {
      return null;
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_aiBaseUrl/read-number-plate'),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        await photo.readAsBytes(),
        filename: photo.name,
        contentType: _contentTypeFor(photo.name),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('AI scan failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rawText = (data['raw_text'] ?? '').toString();
    final apiVehicleNumber = data['vehicle_number']?.toString();
    final vehicleNumber = apiVehicleNumber == null || apiVehicleNumber.isEmpty
        ? extractVehicleNumber(rawText)
        : extractVehicleNumber(apiVehicleNumber) ?? apiVehicleNumber;

    return PlateScanResult(
      vehicleNumber: vehicleNumber ?? '',
      rawText: rawText,
    );
  }

  String? extractVehicleNumber(String rawText) {
    final compact = rawText.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (compact.isEmpty) {
      return null;
    }

    for (final length in const [10, 9]) {
      if (compact.length < length) {
        continue;
      }

      for (var start = 0; start <= compact.length - length; start++) {
        final candidate = compact.substring(start, start + length);
        final normalized = _normalizeCandidate(candidate);
        if (normalized != null && _vehicleRegex.hasMatch(normalized)) {
          return normalized;
        }
      }
    }

    return null;
  }

  String? _normalizeCandidate(String candidate) {
    for (final seriesLength in const [2, 1]) {
      final expectedLength = 2 + 2 + seriesLength + 4;
      if (candidate.length != expectedLength) {
        continue;
      }

      final state = _letters(candidate.substring(0, 2));
      final district = _digits(candidate.substring(2, 4));
      final series = _letters(candidate.substring(4, 4 + seriesLength));
      final number = _digits(candidate.substring(4 + seriesLength));
      final normalized = '$state$district$series$number';

      if (_vehicleRegex.hasMatch(normalized)) {
        return normalized;
      }
    }

    return null;
  }

  String _digits(String value) {
    return value
        .replaceAll('O', '0')
        .replaceAll('Q', '0')
        .replaceAll('D', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1')
        .replaceAll('S', '5')
        .replaceAll('Z', '2')
        .replaceAll('B', '8');
  }

  String _letters(String value) {
    return value
        .replaceAll('0', 'O')
        .replaceAll('1', 'I')
        .replaceAll('5', 'S')
        .replaceAll('2', 'Z')
        .replaceAll('8', 'B');
  }

  MediaType _contentTypeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }
}
