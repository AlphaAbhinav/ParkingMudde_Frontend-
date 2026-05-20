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

  // ================= WRONG PARKING REPORT =================
  static Future<Map<String, dynamic>> createWrongParkingReport({
    required String vehicleNumber,
    required List<XFile> images,
    XFile? videoFile,
    required String capturedAt,
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
      request.fields['captured_at'] = capturedAt;

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
        };
      }
      if (response.statusCode == 402) {
        return {
          "success": false,
          "message": "Not enough coins to report vehicle",
        };
      }

      if (response.statusCode == 409) {
        return {"success": false, "message": "Duplicate report detected"};
      }

      return {
        "success": false,
        "message": "Server error: ${response.statusCode}",
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
    required String firstName,
    required String lastName,
    required String vehicleType,
    required String registrationNumber,
    required String registeredMobile,
    String? ownerRole,
    String? vehicleNumber,
    String? purchaseYear,
    String? insuranceExpiryDate,
    String? ownerRelationship,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/vehicle/add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": int.parse(userId),
          "owner_first_name": firstName,
          "owner_last_name": lastName,
          "owner_role": ownerRole,
          "vehicle_number": vehicleNumber,
          "brand_name": firstName,
          "model_name": lastName,
          "purchase_year": purchaseYear,
          "vehicle_type": vehicleType,
          "fuel_type": vehicleType,
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
    required String firstName,
    required String lastName,
    required String vehicleType,
    required String registrationNumber,
    required String registeredMobile,
    String? ownerRole,
    String? vehicleNumber,
    String? purchaseYear,
    String? insuranceExpiryDate,
    String? ownerRelationship,
  }) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/v1/vehicle/$vehicleId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": int.parse(userId),
          "owner_first_name": firstName,
          "owner_last_name": lastName,
          "owner_role": ownerRole,
          "vehicle_number": vehicleNumber,
          "brand_name": firstName,
          "model_name": lastName,
          "purchase_year": purchaseYear,
          "vehicle_type": vehicleType,
          "fuel_type": vehicleType,
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
        return data['vehicles'];
      } else {
        return [];
      }
    } catch (e) {
      print("Get Vehicles Exception: $e");
      return [];
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
    String? location,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/v1/notifications/helped-vehicle"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": int.parse(userId),
          "vehicle_number": vehicleNumber,
          "location": location,
        }),
      );

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      return {"success": false, "message": "Failed to submit help activity"};
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // ================= CREATE PARKING BOOKING REQUEST =================
  static Future<Map<String, dynamic>> createParkingBookingRequest({
    required String userId,
    int? parkingSpotId,
    required String parkingName,
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
}
