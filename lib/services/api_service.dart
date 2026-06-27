import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // 🔥 IMPORTANT: Use localhost for Flutter Web
  static final String baseUrl =
      dotenv.env['BACKEND_URL'] ?? "http://localhost:8000";

  static String _messageFromResponse(http.Response response, String fallback) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) return detail;
        if (detail is List && detail.isNotEmpty) return detail.toString();
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } catch (_) {}
    return '$fallback (${response.statusCode})';
  }
  static Future<void> saveUserSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = (user["user_id"] ?? user["id"])?.toString();

    if (userId != null && userId.isNotEmpty) {
      await prefs.setString("user_id", userId);
    }

    Future<void> saveString(String prefKey, String apiKey) async {
      final value = user[apiKey];
      if (value != null && value.toString().isNotEmpty) {
        await prefs.setString(prefKey, value.toString());
      } else {
        await prefs.remove(prefKey);
      }
    }

    await saveString("full_name", "full_name");
    await saveString("mobile_number", "mobile_number");
    await saveString("email", "email");
    await saveString("profile_image", "profile_image");
    await saveString("gender", "gender");
    await saveString("date_of_birth", "date_of_birth");
    await saveString("location", "location");
    await saveString("referral_code", "referral_code");

    final latitude = user["latitude"];
    final longitude = user["longitude"];
    if (latitude is num) {
      await prefs.setDouble("latitude", latitude.toDouble());
    }
    if (longitude is num) {
      await prefs.setDouble("longitude", longitude.toDouble());
    }
  }

  static Future<Map<String, dynamic>?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    if (userId == null || userId.isEmpty) return null;

    return {
      "user_id": userId,
      "full_name": prefs.getString("full_name"),
      "mobile_number": prefs.getString("mobile_number"),
      "email": prefs.getString("email"),
      "profile_image": prefs.getString("profile_image"),
      "gender": prefs.getString("gender"),
      "date_of_birth": prefs.getString("date_of_birth"),
      "location": prefs.getString("location"),
      "referral_code": prefs.getString("referral_code"),
      "latitude": prefs.getDouble("latitude"),
      "longitude": prefs.getDouble("longitude"),
    };
  }

  static Future<Map<String, dynamic>?> refreshCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    if (userId == null || userId.isEmpty) return null;

    final result = await getUserProfile(userId);
    if (result["success"] == true) {
      await saveUserSession(result);
      return result;
    }

    return getStoredUser();
  }

  // ================= AI INTEGRATION =================
  static Future<Map<String, dynamic>> getAIVerdict({
    required List<XFile> images,
    required double lat,
    required double lng,
    String? selectedReasonCode,
  }) async {
    try {
      if (images.length < 4) {
        return {"success": false, "message": "4 photos required for AI"};
      }
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/v1/reports/detect-only"),
      );

      request.fields['lat'] = lat.toString();
      request.fields['lng'] = lng.toString();
      if (selectedReasonCode != null && selectedReasonCode.isNotEmpty) {
        request.fields['selected_reason_code'] = selectedReasonCode;
      }

      for (int i = 0; i < 4; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photos',
            await images[i].readAsBytes(),
            filename: images[i].name,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return {
          "success": true,
          "score": decoded["score"] ?? 0,
          "verdict": decoded["verdict"] ?? "UNKNOWN",
          "reasons": jsonEncode(decoded["reasons"] ?? []),
        };
      } else {
        return {"success": false, "message": "AI model returned ${response.statusCode}"};
      }
    } catch (e) {
      print("AI Error: $e");
      return {"success": false, "message": "Failed to connect to AI model"};
    }
  }

  static Future<Map<String, dynamic>> createWrongParkingReport({
    required String vehicleNumber,
    required List<XFile> images,
    XFile? videoFile,
    required String capturedAt,
    String? selectedIssue,
    String? selectedIssueCode,
    int? aiScore,
    String? aiVerdict,
    String? aiReasons,
    double? lat,
    double? lng,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
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

      // Use real GPS if provided, otherwise fall back to stored prefs
      final double reportLat = lat ?? prefs.getDouble("latitude") ?? 19.0760;
      final double reportLng = lng ?? prefs.getDouble("longitude") ?? 72.8777;

      request.fields['vehicle_number'] = vehicleNumber.trim().isEmpty ? 'PENDING' : vehicleNumber;
      request.fields['lat'] = reportLat.toString();
      request.fields['lng'] = reportLng.toString();
      request.fields['captured_at'] = capturedAt;
      if (selectedIssue != null && selectedIssue.isNotEmpty) {
        request.fields['selected_reason'] = selectedIssue;
      }
      if (selectedIssueCode != null && selectedIssueCode.isNotEmpty) {
        request.fields['selected_reason_code'] = selectedIssueCode;
      }
      
      if (aiScore != null) request.fields['ai_score'] = aiScore.toString();
      if (aiVerdict != null) request.fields['ai_verdict'] = aiVerdict;
      if (aiReasons != null) request.fields['ai_reasons'] = aiReasons;

      if (razorpayOrderId != null) request.fields['razorpay_order_id'] = razorpayOrderId;
      if (razorpayPaymentId != null) request.fields['razorpay_payment_id'] = razorpayPaymentId;
      if (razorpaySignature != null) request.fields['razorpay_signature'] = razorpaySignature;

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
          "data": data,
          "coins_charged": data["coins_charged"] ?? 0,
          "coinsback_on_confirm": data["coinsback_on_confirm"] ?? 0,
        };
      }
      if (response.statusCode == 402) {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "insufficient_coins": true,
          "message": body["detail"] ?? "Not enough PM Coins to file a report.",
        };
      }

      if (response.statusCode == 409) {
        return {"success": false, "message": "Duplicate report detected"};
      }

      String errorMessage = "Server error: ${response.statusCode}";
      try {
        final body = jsonDecode(response.body);
        final detail = body["detail"];
        if (detail is String && detail.isNotEmpty) {
          errorMessage = detail;
        } else if (detail != null) {
          errorMessage = detail.toString();
        }
      } catch (_) {}

      return {
        "success": false,
        "message": errorMessage,
      };
    } catch (e) {
      print("Report Exception: $e");
      return {"success": false, "message": "Network error. Please try again."};
    }
  }

  // ================= LOGIN WITH PASSWORD =================
  static Future<Map<String, dynamic>> loginWithPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("Login Status: ${response.statusCode}");
      print("Login Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body["detail"] ?? "Login failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= GET USER PROFILE =================
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/v1/auth/user/$userId"),
      );

      print("User Profile Status: ${response.statusCode}");
      print("User Profile Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body["detail"] ?? "Failed to fetch user profile",
        };
      }
    } catch (e) {
      print("User Profile Exception: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= UPDATE USER PROFILE =================
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required String fullName,
    required String mobileNumber,
    required String email,
    String? gender,
    String? dateOfBirth,
    String? location,
    String? alternateMobileNumber,
    String? emergencyContactOne,
    String? emergencyContactTwo,
    XFile? profileImage,
  }) async {
    try {
      String? profileImageData;
      if (profileImage != null) {
        final bytes = await profileImage.readAsBytes();
        final extension = profileImage.name.split('.').last.toLowerCase();
        final mimeSubtype = extension == 'png'
            ? 'png'
            : extension == 'webp'
                ? 'webp'
                : 'jpeg';
        profileImageData =
            "data:image/$mimeSubtype;base64,${base64Encode(bytes)}";
      }

      final body = {
        "full_name": fullName,
        "mobile_number": mobileNumber,
        "email": email,
        "gender": gender,
        "date_of_birth": dateOfBirth,
        "location": location?.isEmpty == true ? null : location,
        if (alternateMobileNumber != null && alternateMobileNumber.isNotEmpty)
          "alternate_mobile_number": alternateMobileNumber,
        if (emergencyContactOne != null && emergencyContactOne.isNotEmpty)
          "emergency_contact_one": emergencyContactOne,
        if (emergencyContactTwo != null && emergencyContactTwo.isNotEmpty)
          "emergency_contact_two": emergencyContactTwo,
      };

      if (profileImageData != null) {
        body["profile_image"] = profileImageData;
      }

      final response = await http.put(
        Uri.parse("$baseUrl/v1/auth/user/$userId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      print("Update User Status: ${response.statusCode}");
      print("Update User Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await saveUserSession(data);
        return data;
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body["detail"] ?? "Profile update failed",
        };
      }
    } catch (e) {
      print("Update User Exception: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= DELETE USER ACCOUNT =================
  static Future<Map<String, dynamic>> deleteAccount(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/v1/auth/user/$userId"),
      );

      print("Delete Account Status: ${response.statusCode}");
      print("Delete Account Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final body = jsonDecode(response.body);
      return {
        "success": false,
        "message": body["detail"] ?? "Account delete failed",
      };
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= GET SOCIETIES =================
  static Future<Map<String, dynamic>> getSocieties() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/v1/societies"));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        List<dynamic> societiesList = [];
        if (body is List) {
          societiesList = body;
        } else if (body is Map) {
          societiesList = body["items"] ?? body["societies"] ?? [];
        }
        return {"success": true, "societies": societiesList};
      } else {
        return {"success": false, "message": "Failed to fetch societies"};
      }
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= SUGGEST SOCIETY =================
  static Future<Map<String, dynamic>> suggestSociety({
    required int userId,
    required String societyName,
    required String addressPincode,
    required String contactDetails,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/societies/suggest"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "society_name": societyName,
          "address_pincode": addressPincode,
          "contact_details": contactDetails,
        }),
      );

      print("Suggest Society Status: ${response.statusCode}");
      print("Suggest Society Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body["detail"] ?? "Failed to suggest society",
        };
      }
    } catch (e) {
      print("Suggest Society Exception: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= REGISTER =================
  static Future<Map<String, dynamic>> register({
    required String name,
    required String mobile,
    required String email,
    required String password,
    String? gender,
    String? dateOfBirth,
    String? referralCode,
    String? location,
    String? drivingLicenseNumber,
    String? aadhaarNumber,
    String? societyName,
    String? tower,
    String? flatNumber,
    double? latitude,
    double? longitude,
    XFile? profileImage,
  }) async {
    try {
      String? profileImageData;
      if (profileImage != null) {
        final bytes = await profileImage.readAsBytes();
        final extension = profileImage.name.split('.').last.toLowerCase();
        final mimeSubtype = extension == 'png'
            ? 'png'
            : extension == 'webp'
                ? 'webp'
                : 'jpeg';
        profileImageData =
            "data:image/$mimeSubtype;base64,${base64Encode(bytes)}";
      }

      final response = await http.post(
        Uri.parse("$baseUrl/v1/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": name,
          "mobile_number": mobile,
          "email": email,
          "password": password,
          "gender": gender?.isEmpty == true ? null : gender,
          "date_of_birth": dateOfBirth?.isEmpty == true ? null : dateOfBirth,
          "referral_code": referralCode?.isEmpty == true ? null : referralCode,
          "location": location?.isEmpty == true ? null : location,
          "driving_license_number": drivingLicenseNumber?.isEmpty == true ? null : drivingLicenseNumber,
          "aadhaar_number": aadhaarNumber?.isEmpty == true ? null : aadhaarNumber,
          "society_name": societyName?.isEmpty == true ? null : societyName,
          "tower": tower?.isEmpty == true ? null : tower,
          "flat_number": flatNumber?.isEmpty == true ? null : flatNumber,
          "latitude": latitude,
          "longitude": longitude,
          "profile_image": profileImageData,
        }),
      );

      print("Register Status: ${response.statusCode}");
      print("Register Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body["detail"] ?? "Registration failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= FORGOT PASSWORD (send OTP to email) =================
  static Future<Map<String, dynamic>> sendResetCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/auth/forgot-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      print("Forgot PW Status: ${response.statusCode}");
      print("Forgot PW Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body["detail"] ?? "Failed to send OTP",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= RESET PASSWORD =================
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/auth/reset-password"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp_code": otpCode,
          "new_password": newPassword,
        }),
      );

      print("Reset PW Status: ${response.statusCode}");
      print("Reset PW Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body["detail"] ?? "Password reset failed",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= SEND OTP (legacy) =================
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
        return {"success": false, "message": "Failed to send OTP"};
      }
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }


  // ================= VERIFY OTP =================
  static Future<Map<String, dynamic>> verifyOtp(
    String mobile,
    String otp,
    String referralCode,
  ) async {
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
        return {"success": false, "message": "Invalid OTP"};
      }
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= ADD VEHICLE =================
  static Future<Map<String, dynamic>> addVehicle({
    required String userId,
    required String ownerFirstName,
    required String ownerLastName,
    required String vehicleType,
    required String registrationNumber,
    required String registeredMobile,
    String? ownerRole,
    String? vehicleNumber,
    String? brandName,
    String? modelName,
    String? purchaseYear,
    String? insuranceExpiryDate,
    String? pollutionExpiryDate,
    String? description,
    String? kmDriven,
    String? fuelType,
    String? ownerRelationship,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/vehicle/add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": int.parse(userId),
          "owner_first_name": ownerFirstName,
          "owner_last_name": ownerLastName,
          "owner_role": ownerRole,
          "vehicle_number": vehicleNumber,
          "brand_name": brandName,
          "model_name": modelName,
          "purchase_year": purchaseYear,
          "vehicle_type": vehicleType,
          "fuel_type": fuelType,
          "description": description,
          "km_driven": kmDriven,
          "pollution_expiry_date": pollutionExpiryDate,
          "registration_number": registrationNumber,
          "insurance_expiry_date": insuranceExpiryDate,
          "registered_mobile": registeredMobile,
          "owner_relationship": ownerRelationship,
        }),
      );

      print("Add Vehicle Status: ${response.statusCode}");
      print("Add Vehicle Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body["detail"] ?? "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      print("Add Vehicle Exception: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= UPDATE VEHICLE =================
  static Future<Map<String, dynamic>> updateVehicle({
    required String vehicleId,
    required String userId,
    required String ownerFirstName,
    required String ownerLastName,
    required String vehicleType,
    required String registrationNumber,
    required String registeredMobile,
    String? ownerRole,
    String? vehicleNumber,
    String? brandName,
    String? modelName,
    String? purchaseYear,
    String? insuranceExpiryDate,
    String? pollutionExpiryDate,
    String? description,
    String? kmDriven,
    String? fuelType,
    String? ownerRelationship,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/v1/vehicle/$vehicleId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": int.parse(userId),
          "owner_first_name": ownerFirstName,
          "owner_last_name": ownerLastName,
          "owner_role": ownerRole,
          "vehicle_number": vehicleNumber,
          "brand_name": brandName,
          "model_name": modelName,
          "purchase_year": purchaseYear,
          "vehicle_type": vehicleType,
          "fuel_type": fuelType,
          "description": description,
          "km_driven": kmDriven,
          "pollution_expiry_date": pollutionExpiryDate,
          "registration_number": registrationNumber,
          "insurance_expiry_date": insuranceExpiryDate,
          "registered_mobile": registeredMobile,
          "owner_relationship": ownerRelationship,
        }),
      );

      print("Update Vehicle Status: ${response.statusCode}");
      print("Update Vehicle Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body["detail"] ?? "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      print("Update Vehicle Exception: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= DELETE VEHICLE =================
  static Future<Map<String, dynamic>> deleteVehicle({
    required String vehicleId,
    required String userId,
    String? reason,
  }) async {
    try {
      final uri = Uri.parse("$baseUrl/v1/vehicle/$vehicleId").replace(
        queryParameters: {
          "user_id": userId,
          if (reason != null && reason.isNotEmpty) "reason": reason,
        },
      );
      final response = await http.delete(uri);

      print("Delete Vehicle Status: ${response.statusCode}");
      print("Delete Vehicle Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {
          "success": false,
          "message": body["detail"] ?? "Server error: ${response.statusCode}",
        };
      }
    } catch (e) {
      print("Delete Vehicle Exception: $e");
      return {"success": false, "message": "Network error"};
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
        List<dynamic> vehicles = data['vehicles'] ?? [];
        if (vehicles.isNotEmpty) {
          vehicles[0]['transfer_status'] = 'pending';
        }
        return vehicles;
      } else {
        return [];
      }
    } catch (e) {
      print("Get Vehicles Exception: $e");
      return [];
    }
  }

  // ================= LOOKUP VEHICLE BY NUMBER =================
  static Future<Map<String, dynamic>> lookupVehicleByNumber(String vehicleNumber) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/v1/vehicle/lookup/$vehicleNumber"),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "registered": data["registered"] ?? false,
          "data": {
            "vehicle_number": data["vehicle"]["vehicle_number"],
            "owner_name": data["owner_name"] ?? data["app_user_name"] ?? "Unknown Owner",
            "city": data["vehicle"]["rto_code"] ?? "Unknown",
            "mobile_number": data["owner_mobile"] ?? data["app_user_mobile"] ?? ""
          }
        };
      } else if (response.statusCode == 404) {
        return {
          "success": true,
          "registered": false,
          "message": "Vehicle not found"
        };
      } else {
        return {"success": false, "message": "Failed to lookup vehicle"};
      }
    } catch (e) {
      print("Lookup Vehicle Exception: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= GET LINKED COMMUNITY + ASSIGNED PARKING =================
  static Future<Map<String, dynamic>> getMyCommunity(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/v1/auth/user/$userId/community"),
      );

      print("Community Status: ${response.statusCode}");
      print("Community Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final body = jsonDecode(response.body);
      return {
        "linked": false,
        "message": body["detail"] ?? "Failed to fetch community",
      };
    } catch (e) {
      print("Community Exception: $e");
      return {"linked": false, "message": "Network error"};
    }
  }

  // ================= GET IN-APP NOTIFICATIONS =================
  static Future<List<dynamic>> getNotifications(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/v1/notifications/user/$userId"),
      );

      print("Notifications Status: ${response.statusCode}");
      print("Notifications Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['notifications'] ?? [];
      } else {
        return [];
      }
    } catch (e) {
      print("Notifications Exception: $e");
      return [];
    }
  }

  // ================= GET NOTIFICATIONS FOR CURRENT USER =================
  static Future<List<dynamic>> getNotificationsForCurrentUser() async {
    final user = await getStoredUser();
    final userId = user?["user_id"]?.toString();
    if (userId == null || userId.isEmpty) return [];
    return getNotifications(userId);
  }

  // ================= CLEAR IN-APP NOTIFICATIONS =================
  static Future<Map<String, dynamic>> clearNotifications(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/v1/notifications/$userId"),
      );

      print("Clear Notifications Status: ${response.statusCode}");
      print("Clear Notifications Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"success": false, "message": "Failed to clear notifications"};
      }
    } catch (e) {
      print("Clear Notifications Exception: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= CREATE HELPED VEHICLE ACTIVITY =================
  static Future<Map<String, dynamic>> createHelpedVehicleActivity({
    required String userId,
    required String vehicleNumber,
    XFile? image,
    String? parkingError,
    String? location,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/v1/notifications/helped-vehicle"),
      );

      request.fields['user_id'] = userId;
      request.fields['vehicle_number'] = vehicleNumber;
      if (parkingError != null) request.fields['parking_error'] = parkingError;
      if (location != null) request.fields['location'] = location;

      if (image != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            await image.readAsBytes(),
            filename: image.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      return {
        "success": false,
        "message": _messageFromResponse(response, "Failed to submit help activity"),
      };
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= CREATE PARKING BOOKING REQUEST =================
  static Future<Map<String, dynamic>> createParkingBookingRequest({
    required String userId,
    int? parkingSpotId,
    required String parkingName,
    String? vehicleNumber,
    double? latitude,
    double? longitude,
    int? durationHours,
    int? amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/parking/bookings"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": int.parse(userId),
          "parking_spot_id": parkingSpotId,
          "parking_name": parkingName,
          "vehicle_number": vehicleNumber,
          "latitude": latitude,
          "longitude": longitude,
          "duration_hours": durationHours,
          "amount": amount,
        }),
      );

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      return {"success": false, "message": "Failed to create booking"};
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= GET PARKING ALERTS =================
  static Future<Map<String, dynamic>> getParkingAlerts(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/v1/notifications/alerts/$userId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Parking Alerts Exception: $e");
    }

    return {
      "raised_by_you": [],
      "against_you": [],
      "counts": {"raised_by_you": 0, "against_you": 0},
    };
  }

  // ================= GET LEADERBOARD =================
  static Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/v1/leaderboard/"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Leaderboard Exception: $e");
    }
    return {"weekly_heroes": [], "parking_warriors": [], "city_champions": []};
  }

  // ================= GET GAMIFICATION PROGRESS =================
  static Future<Map<String, dynamic>?> getMyGamificationProgress(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/v1/leaderboard/me/$userId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Gamification Progress Exception: $e");
    }
    return null;
  }

  // ================= GET USER DOCUMENTS =================
  static Future<List<dynamic>> getUserDocuments(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/v1/documents/user/$userId"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Get User Documents Exception: $e");
    }
    return [];
  }

  // ================= UPLOAD USER DOCUMENT =================
  static Future<Map<String, dynamic>> uploadUserDocument({
    required String userId,
    required String documentType,
    required String documentLabel,
    required XFile file,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/v1/documents/upload"),
      );
      request.fields['user_id'] = userId;
      request.fields['document_type'] = documentType;
      request.fields['document_label'] = documentLabel;
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          await file.readAsBytes(),
          filename: file.name,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Upload Document Exception: $e");
    }
    return {"success": false, "message": "Document upload failed"};
  }

  // ================= DELETE USER DOCUMENT =================
  static Future<Map<String, dynamic>> deleteUserDocument({
    required String userId,
    required String documentId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/v1/documents/$documentId?user_id=$userId"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Delete Document Exception: $e");
    }
    return {"success": false, "message": "Document delete failed"};
  }

  // ================= PURCHASE WALLET PACKAGE (Request-type only) =================
  static Future<Map<String, dynamic>> purchaseWalletPackage({
    required String packageId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";
      final response = await http.post(
        Uri.parse("$baseUrl/v1/wallet/packages/purchase"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": int.parse(userId), "package_id": packageId}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final body = jsonDecode(response.body);
      return {"success": false, "message": body["detail"] ?? "Request failed"};
    } catch (e) {
      print("Purchase Wallet Package Exception: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= RAZORPAY: CREATE REPORT ORDER =================
  static Future<Map<String, dynamic>> createReportRazorpayOrder({
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      
      final response = await http.post(
        Uri.parse("$baseUrl/v1/reports/razorpay/create-order"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token ?? ""}',
        },
        body: jsonEncode({
          "user_id": int.tryParse(userId) ?? 0,
          "package_id": "report_fee"
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"success": false, "message": "Failed to create report payment order."};
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // ================= RAZORPAY: CREATE ORDER =================



  static Future<Map<String, dynamic>> attachWrongParkingPlate({
    required String reportId,
    required String vehicleNumber,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/reports/$reportId/attach-plate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "vehicle_number": vehicleNumber,
          if (razorpayOrderId != null) "razorpay_order_id": razorpayOrderId,
          if (razorpayPaymentId != null) "razorpay_payment_id": razorpayPaymentId,
          if (razorpaySignature != null) "razorpay_signature": razorpaySignature,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      final body = jsonDecode(response.body);
      String errorMessage = "Failed to attach plate";
      if (body["detail"] is Map) {
        errorMessage = body["detail"]["message"] ?? errorMessage;
      } else if (body["detail"] != null) {
        errorMessage = body["detail"].toString();
      }
      return {"success": false, "message": errorMessage};
    } catch (e) {
      print("Attach Plate Exception: $e");
      String errorMsg = e.toString();
      if (errorMsg.contains("TimeoutException") || 
          errorMsg.contains("Failed to fetch") || 
          errorMsg.contains("SocketException") || 
          errorMsg.contains("ClientException")) {
        errorMsg = "Network error. Please check your connection or try again.";
      }
      return {"success": false, "message": errorMsg};
    }
  }

  static Future<Map<String, dynamic>> createRazorpayOrder({
    required String packageId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString("user_id") ?? "";
      final userId = int.tryParse(userIdStr) ?? 0;

      final response = await http.post(
        Uri.parse("$baseUrl/v1/wallet/razorpay/create-order"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId, "package_id": packageId}),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final body = jsonDecode(response.body);
      return {"success": false, "message": body["detail"] ?? "Could not create order"};
    } catch (e) {
      print("Create Razorpay Order Exception: $e");
      return {"success": false, "message": "Error connecting to server: $e"};
    }
  }

  // ================= RAZORPAY: VERIFY PAYMENT =================
  static Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String packageId,
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userIdStr = prefs.getString("user_id") ?? "";
      final userId = int.tryParse(userIdStr) ?? 0;

      final response = await http.post(
        Uri.parse("$baseUrl/v1/wallet/razorpay/verify"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "package_id": packageId,
          "razorpay_payment_id": razorpayPaymentId,
          "razorpay_order_id": razorpayOrderId,
          "razorpay_signature": razorpaySignature,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final body = jsonDecode(response.body);
      return {"success": false, "message": body["detail"] ?? "Verification failed"};
    } catch (e) {
      print("Verify Razorpay Payment Exception: $e");
      return {"success": false, "message": "Error connecting to server: $e"};
    }
  }

  // ================= GET VISITORS =================
  static Future<Map<String, dynamic>> getMyVisitors(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/v1/visitors/user/$userId"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Get My Visitors Exception: $e");
    }
    return {"linked": false, "message": "Unable to fetch visitors", "visitors": []};
  }

  // ================= CREATE VISITOR PASS =================
  static Future<Map<String, dynamic>> createVisitorPass({
    required String userId,
    required String name,
    required String mobileNumber,
    required String purpose,
    String? vehicleNumber,
    String? expectedAt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/visitors/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": int.tryParse(userId) ?? 0,
          "name": name,
          "mobile_number": mobileNumber,
          "purpose": purpose,
          "vehicle_number": vehicleNumber,
          "expected_at": expectedAt,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {"success": true, ...data};
      }
      final err = jsonDecode(response.body);
      return {"success": false, "message": err["detail"] ?? "Failed to create pass"};
    } catch (e) {
      print("Create Visitor Pass Exception: $e");
    }
    return {"success": false, "message": "Unable to create visitor pass"};
  }

  // ================= CANCEL VISITOR PASS =================
  static Future<Map<String, dynamic>> cancelVisitorPass({
    required String visitorId,
    required String userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/v1/visitors/$visitorId/cancel?user_id=$userId"),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      final err = jsonDecode(response.body);
      return {"success": false, "message": err["detail"] ?? "Failed to cancel"};
    } catch (e) {
      print("Cancel Visitor Pass Exception: $e");
    }
    return {"success": false, "message": "Unable to cancel visitor pass"};
  }

  // ================= EMERGENCY ALERT ACTIVITY =================
  static Future<Map<String, dynamic>> createEmergencyAlertActivity({
    required String userId,
    required String vehicleNumber,
    required String situation,
    String? location,
    XFile? image,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/v1/notifications/emergency-alert"),
      );

      request.fields['user_id'] = userId;
      request.fields['vehicle_number'] = vehicleNumber;
      request.fields['situation'] = situation;
      if (location != null && location.isNotEmpty) {
        request.fields['location'] = location;
      }

      if (image != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            await image.readAsBytes(),
            filename: image.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      return {
        "success": false,
        "message": _messageFromResponse(response, "Unable to submit emergency alert"),
      };
    } catch (e) {
      print("Emergency Alert Exception: $e");
    }
    return {"success": false, "message": "Unable to submit emergency alert"};
  }

  static Future<Map<String, dynamic>> attachGuardReportPlate({
    required String reportId,
    required String vehicleNumber,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('guard_access_token');
      final response = await http.post(
        Uri.parse("$baseUrl/api/guard/reports/$reportId/attach-plate"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({"vehicle_number": vehicleNumber}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      return {
        "success": false,
        "message": _messageFromResponse(response, "Failed to attach plate"),
      };
    } catch (e) {
      return {"success": false, "message": "Network error. Please try again."};
    }
  }
  static Future<Map<String, dynamic>> attachNotificationPlate({
    required String notificationId,
    required String vehicleNumber,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/notifications/$notificationId/attach-plate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"vehicle_number": vehicleNumber}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      return {
        "success": false,
        "message": _messageFromResponse(response, "Failed to attach plate"),
      };
    } catch (e) {
      print("Attach Notification Plate Exception: $e");
      return {"success": false, "message": "Network error. Please try again."};
    }
  }
  // ================= TRIGGER REPORT ACTION =================
  static Future<Map<String, dynamic>> triggerReportAction({
    required String reportId,
    required String action,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/reports/$reportId/actions/$action"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Trigger Report Action Exception: $e");
    }
    return {"success": false, "message": "Action request failed"};
  }

  // ================= ON THE WAY (Offender) =================
  static Future<Map<String, dynamic>> triggerOnTheWay({
    required String reportId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/reports/$reportId/on-the-way"),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"success": false, "message": "Request failed: ${response.statusCode}"};
    } catch (e) {
      print("OnTheWay Exception: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= GET MY PARKING BOOKINGS =================
  static Future<List<dynamic>> getMyBookings(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/v1/parking/bookings/my/$userId"),
      );

      print("My Bookings Status: ${response.statusCode}");
      print("My Bookings Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      print("My Bookings Exception: $e");
      return [];
    }
  }

  // ================= GET WALLET BALANCE =================
  static Future<Map<String, dynamic>> getWalletBalance(String userId) async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/v1/wallet/$userId"));

      print("Wallet Status: ${response.statusCode}");
      print("Wallet Response: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"success": false, "message": "Failed to fetch wallet"};
      }
    } catch (e) {
      print("Wallet Exception: $e");
      return {"success": false, "message": "Network error"};
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
        return {"success": false, "message": "Failed to fetch referrals"};
      }
    } catch (e) {
      print("Referral Exception: $e");
      return {"success": false, "message": "Network error"};
    }
  }

  static Future<List<dynamic>> getCoupons() async {
    final response = await http.get(Uri.parse("$baseUrl/v1/coupons/"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load coupons");
    }
  }

  static Future<Map<String, dynamic>> buyCoupon(
    String couponId,
    String userId,
  ) async {
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
          "message": jsonDecode(response.body)["detail"],
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error"};
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

  // ================= TRANSFER VEHICLE =================
  static Future<Map<String, dynamic>> transferVehicle({
    required String vehicleId,
    required String currentUserId,
    required String recipientMobile,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      return {
        "success": true,
        "message": "Vehicle transferred successfully to $recipientMobile",
      };
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= GET PENDING TRANSFERS =================
  static Future<List<dynamic>> getPendingTransfers(String userId) async {
    try {
      // await Future.delayed(const Duration(milliseconds: 500));
      // return [
      //   {
      //     "id": "mock_transfer_1",
      //     "vehicle_id": "v_101",
      //     "registration_number": "KA05DC9999",
      //     "brand_name": "Honda",
      //     "model_name": "City",
      //     "sender_name": "Rajesh Kumar",
      //     "sender_mobile": "98XXXXXX89",
      //     "status": "pending",
      //   }
      // ];
      return [];
    } catch (e) {
      return [];
    }
  }

  // ================= RESPOND TO TRANSFER =================
  static Future<Map<String, dynamic>> respondToTransfer({
    required String transferId,
    required String action, // "accept" or "decline"
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      return {
        "success": true,
        "message": "Transfer request ${action}ed successfully.",
      };
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  static Future<bool> submitSupportTicket(String userId, String name, String mobile, String question) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/support/tickets"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": int.parse(userId),
          "name": name,
          "mobile_number": mobile,
          "question": question,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      print("Error submitting support ticket: $e");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> checkAppUpdate() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/v1/system/app-config"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print("Error checking app update: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>> updateNotificationStatus(String notificationId, String status) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/v1/notifications/$notificationId/status"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"status": status}),
      );
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");
      if (userId == null) return {"success": false, "message": "No user ID"};

      final response = await http.post(
        Uri.parse("$baseUrl/v1/auth/fcm-token"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"user_id": int.parse(userId), "fcm_token": token}),
      );
      
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false};
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
