import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {

  int pmCoinsBalance = 0;
  int pmCoinsEarned = 0;
  int pmCoinsSpent = 0;

  int coinsbackBalance = 0;
  int coinsbackEarned = 0;
  int coinsbackSpent = 0;

  List transactions = [];
List subscriptions = [];

Future<void> fetchWallet() async {


final prefs = await SharedPreferences.getInstance();
String? userId = prefs.getString("user_id");

if (userId == null) {
  print("User not logged in");
  return;
}

final response = await ApiService.getWalletBalance(userId);

if (response != null) {

    pmCoinsBalance = response["pm_coins_balance"] ?? 0;
    pmCoinsEarned = response["pm_coins_earned"] ?? 0;
    pmCoinsSpent = response["pm_coins_spent"] ?? 0;

    coinsbackBalance = response["coinsback_balance"] ?? 0;
    coinsbackEarned = response["coinsback_earned"] ?? 0;
    coinsbackSpent = response["coinsback_spent"] ?? 0;

    transactions = response["transactions"] ?? [];
    subscriptions = response["subscriptions"] ?? [];

  notifyListeners();
}


}

bool hasActiveSubscription(String packageId) {
  return subscriptions.any((sub) =>
    sub['package_id'] == packageId && sub['status'] == 'ACTIVE');
}

String? subscriptionEndDate(String packageId) {
  final sub = subscriptions.cast<Map<String, dynamic>?>().firstWhere(
    (s) => s?['package_id'] == packageId && s?['status'] == 'ACTIVE',
    orElse: () => null,
  );
  if (sub == null) return null;
  final endDate = DateTime.tryParse(sub['end_date']?.toString() ?? '');
  if (endDate == null) return null;
  return "${endDate.day}/${endDate.month}/${endDate.year}";
}
}
