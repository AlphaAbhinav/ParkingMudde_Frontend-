import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkingmudde/services/api_service.dart';

class ReferralScreen extends StatefulWidget {
const ReferralScreen({super.key});

@override
State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {

String referralCode = "";
int totalEarnedCoins = 0;
List referralHistory = [];

bool isLoading = true;

@override
void initState() {
super.initState();
loadReferralData();
}

Future<void> loadReferralData() async {


final prefs = await SharedPreferences.getInstance();
String? userId = prefs.getString("user_id");

if (userId == null) {
  setState(() {
    isLoading = false;
  });
  Get.snackbar("Error", "User not logged in");
  return;
}

final data = await ApiService.getReferrals(userId);

setState(() {
  referralCode = data["referral_code"] ?? "";
  totalEarnedCoins = data["total_earned"] ?? 0;
  referralHistory = data["referrals"] ?? [];
  isLoading = false;
});


}

void shareReferral() {
Share.share(
"Join ParkingMudde & earn coins 🪙\n\n"
"Use my referral code: $referralCode\n"
"Download now 👉 https://parkingmudde.app",
);
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
leading: IconButton(
icon: const Icon(Icons.chevron_left,
color: Color(0XFFfdd708), size: 40),
onPressed: () {
Get.back();
},
),
toolbarHeight: 60,
elevation: 0.2,
centerTitle: true,
backgroundColor: Colors.white,
title: const Text(
"Refer & Earn",
style: TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
),
),


  body: isLoading
      ? const Center(child: CircularProgressIndicator())
      : Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [

              /// Referral Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0XFF184b8c),
                      const Color(0XFF184b8c).withOpacity(.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Your Referral Code",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          referralCode,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Colors.white),
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: referralCode));
                            Get.snackbar(
                              "Copied",
                              "Referral code copied!",
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: shareReferral,
                            icon: const Icon(Icons.share),
                            label: const Text("Share"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0XFF184b8c),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Total Earned
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Earned",
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "$totalEarnedCoins 🪙",
                    style: const TextStyle(
                        color: Colors.green, fontSize: 16),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// Referral History
              Expanded(
                child: ListView.builder(
                  itemCount: referralHistory.length,
                  itemBuilder: (context, index) {

                    final item = referralHistory[index];
                    final isJoined = item['status'] == "joined";

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isJoined
                              ? Colors.green
                              : Colors.orange,
                          child: Icon(
                            isJoined
                                ? Icons.check
                                : Icons.hourglass_empty,
                            color: Colors.white,
                          ),
                        ),

                        title: Text(
                          item['mobile_number'] ?? "",
                        ),

                        subtitle: Text(
                          item['date'] ?? "",
                        ),

                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['status'] ?? "",
                              style: TextStyle(
                                color: isJoined
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            if (isJoined)
                              Text(
                                "+${item['reward']} 🪙",
                                style: const TextStyle(
                                    color: Colors.green),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
);


}
}
