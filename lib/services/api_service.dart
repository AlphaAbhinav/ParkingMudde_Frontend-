import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

  // 🔥 IMPORTANT: Use localhost for Flutter Web
  static const String baseUrl = "http://localhost:8000";

  // ================= WRONG PARKING REPORT =================
  static Future<Map<String, dynamic>> createWrongParkingReport({
    required String vehicleNumber,
    required List<XFile> images,
    XFile? videoFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/v1/reports/wrong-parking"),
      );

      // 🔴 TEMP USER ID (replace after full auth integration)
      final prefs = await SharedPreferences.getInstance();
        String? userId = prefs.getString("user_id");

request.headers['x-user-id'] = userId ?? "";

      request.fields['vehicle_number'] = vehicleNumber;
      request.fields['lat'] = "19.0760";
      request.fields['lng'] = "72.8777";
      request.fields['captured_at'] =
          DateTime.now().toIso8601String();

      if (videoFile != null) {
        request.fields['evidence_mode'] = "VIDEO";

        request.files.add(
          http.MultipartFile.fromBytes(
            'video',
            await videoFile.readAsBytes(),
            filename: videoFile.name,
            contentType: MediaType('video', 'mp4'),
          ),
        );
      } else {
        request.fields['evidence_mode'] = "PHOTOS";

        if (images.length < 4) {
          return {"success": false, "message": "4 photos required"};
        }

        List<String> fieldNames = ['front', 'back', 'left', 'right'];

        for (int i = 0; i < 4; i++) {
          request.files.add(
            http.MultipartFile.fromBytes(
              fieldNames[i],
              await images[i].readAsBytes(),
              filename: images[i].name,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Report Status Code: ${response.statusCode}");
      print("Report Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {

        final data = jsonDecode(response.body);

        return {
          "success": true,
          "message": "Report submitted successfully",
          "data": data
        };
      }
      if (response.statusCode == 402) {
        return {
          "success": false,
          "message": "Not enough coins to report vehicle"
        };
      }

      if (response.statusCode == 409) {
        return {
          "success": false,
          "message": "Duplicate report detected"
        };
      }

      return {
        "success": false,
        "message": "Server error: ${response.statusCode}"
      };
    } catch (e) {
      print("Report Exception: $e");
      return {
        "success": false,
        "message": "Network error. Please try again."
      };
    }
  }

  // ================= SEND OTP =================
  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/auth/send-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"mobile_number": mobile}),
      );

      print("Send OTP Status: ${response.statusCode}");
      print("Send OTP Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Failed to send OTP"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Network error"
      };
    }
  }

  // ================= VERIFY OTP =================
  static Future<Map<String, dynamic>> verifyOtp(
    String mobile, String otp, String referralCode) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/auth/verify-otp"),
        headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "mobile_number": mobile,
      "otp_code": otp,
      "referral_code": referralCode.isEmpty ? null : referralCode,
    }),
      );

      print("Verify OTP Status: ${response.statusCode}");
      print("Verify OTP Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          "success": false,
          "message": "Invalid OTP"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Network error"
      };
    }
  }

// ================= ADD VEHICLE =================
static Future<Map<String, dynamic>> addVehicle({
  required String userId,
  required String firstName,
  required String lastName,
  required String vehicleType,
  required String registrationNumber,
  required String registeredMobile,
}) async {
  try {
    final response = await http.post(
      Uri.parse("$baseUrl/v1/vehicle/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": int.parse(userId),
        "owner_first_name": firstName,
        "owner_last_name": lastName,
        "vehicle_type": vehicleType,
        "registration_number": registrationNumber,
        "registered_mobile": registeredMobile,
      }),
    );

    print("Add Vehicle Status: ${response.statusCode}");
    print("Add Vehicle Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "success": false,
        "message": "Server error: ${response.statusCode}"
      };
    }
  } catch (e) {
    print("Add Vehicle Exception: $e");
    return {
      "success": false,
      "message": "Network error"
    };
  }
}

// ================= GET MY VEHICLES =================
static Future<List<dynamic>> getMyVehicles(String userId) async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/v1/vehicle/my-vehicles/$userId"),
    );

    print("Get Vehicles Status: ${response.statusCode}");
    print("Get Vehicles Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['vehicles'];
    } else {
      return [];
    }
  } catch (e) {
    print("Get Vehicles Exception: $e");
    return [];
  }
}

// ================= GET WALLET BALANCE =================
static Future<Map<String, dynamic>> getWalletBalance(String userId) async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/v1/wallet/$userId"),
    );

    print("Wallet Status: ${response.statusCode}");
    print("Wallet Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "success": false,
        "message": "Failed to fetch wallet"
      };
    }
  } catch (e) {
    print("Wallet Exception: $e");
    return {
      "success": false,
      "message": "Network error"
    };
  }
}

// ================= GET REFERRALS =================
static Future<Map<String, dynamic>> getReferrals(String userId) async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/v1/referrals/$userId"),
    );

    print("Referral Status: ${response.statusCode}");
    print("Referral Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "success": false,
        "message": "Failed to fetch referrals"
      };
    }
  } catch (e) {
    print("Referral Exception: $e");
    return {
      "success": false,
      "message": "Network error"
    };
  }
}

static Future<List<dynamic>> getCoupons() async {
  final response = await http.get(
    Uri.parse("$baseUrl/v1/coupons/"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load coupons");
  }
}

static Future<Map<String, dynamic>> buyCoupon(
    String couponId, String userId) async {
  try {
    final response = await http.post(
      Uri.parse("$baseUrl/v1/coupons/buy/$couponId?user_id=$userId"),
    );

    print("Buy Coupon Status: ${response.statusCode}");
    print("Buy Coupon Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {
        "success": false,
        "message": jsonDecode(response.body)["detail"]
      };
    }
  } catch (e) {
    return {
      "success": false,
      "message": "Network error"
    };
  }
}

static Future<List<dynamic>> getMyCoupons(String userId) async {
  try {
    final response = await http.get(
      Uri.parse("$baseUrl/v1/coupons/my/$userId"),
    );

    print("My Coupons Status: ${response.statusCode}");
    print("My Coupons Response: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  } catch (e) {
    print("My Coupons Exception: $e");
    return [];
  }
}

}