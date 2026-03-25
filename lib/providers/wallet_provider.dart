import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {

int balance = 0;
int earned = 0;
int spent = 0;

List transactions = [];

Future<void> fetchWallet() async {


final prefs = await SharedPreferences.getInstance();
String? userId = prefs.getString("user_id");

if (userId == null) {
  print("User not logged in");
  return;
}

final response = await ApiService.getWalletBalance(userId);

if (response != null) {

  balance = response["balance"] ?? 0;
  earned = response["earned"] ?? 0;
  spent = response["spent"] ?? 0;

  transactions = response["transactions"] ?? [];

  notifyListeners();
}


}
}
