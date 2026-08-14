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
  double totalBalanceInr = 0;
  String? totalBalanceLabel;

  List transactions = [];
  List subscriptions = [];

  int _readInt(dynamic value) => int.tryParse(value?.toString() ?? "0") ?? 0;

  double _readDouble(dynamic value) =>
      double.tryParse(value?.toString() ?? "0") ?? 0;

  Future<void> fetchWallet() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("user_id");

    if (userId == null) {
      print("User not logged in");
      return;
    }

    final response = await ApiService.getWalletBalance(userId);

    if (response != null) {
      if (response["success"] == false) {
        print('Wallet fetch failed');
        return;
      }

      pmCoinsBalance = _readInt(response["pm_coins_balance"]);
      pmCoinsEarned = _readInt(response["pm_coins_earned"]);
      pmCoinsSpent = _readInt(response["pm_coins_spent"]);

      coinsbackBalance = _readInt(response["coinsback_balance"]);
      coinsbackEarned = _readInt(response["coinsback_earned"]);
      coinsbackSpent = _readInt(response["coinsback_spent"]);
      totalBalanceInr = _readDouble(response["total_balance_inr"]);
      totalBalanceLabel = response["total_balance_label"]?.toString();

      transactions = response["transactions"] ?? [];
      subscriptions = response["subscriptions"] ?? [];

      notifyListeners();
    }
  }

  bool hasActiveSubscription(String packageId) {
    return subscriptions.any(
      (sub) => sub['package_id'] == packageId && sub['status'] == 'ACTIVE',
    );
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
