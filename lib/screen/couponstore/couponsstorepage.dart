import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CouponStoreScreen extends StatefulWidget {
  final int userCoins;

  const CouponStoreScreen({super.key, required this.userCoins});

  @override
  State<CouponStoreScreen> createState() => _CouponStoreScreenState();
}

class _CouponStoreScreenState extends State<CouponStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<CouponModel> coupons = [];
  List<CouponModel> myCoupons = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    fetchCoupons();
    fetchMyCoupons(); // ✅ load purchased coupons
  }

  // ================= FETCH STORE COUPONS =================
  Future<void> fetchCoupons() async {
    try {
      final data = await ApiService.getCoupons();

      List<CouponModel> loadedCoupons = data.map<CouponModel>((c) {
        return CouponModel(
          id: c["id"].toString(),
          brand: c["brand"],
          title: c["title"],
          offerType: c["coupon_type"],
          coinCost: c["cost"],
          description: c["description"],
        );
      }).toList();

      setState(() {
        coupons = loadedCoupons;
        isLoading = false;
      });
    } catch (e) {
      print("Coupon fetch error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // ================= FETCH PURCHASED COUPONS =================
  Future<void> fetchMyCoupons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("user_id");

      if (userId == null) return;

      final data = await ApiService.getMyCoupons(userId);

      List<CouponModel> loadedCoupons = data.map<CouponModel>((c) {
        return CouponModel(
          id: c["id"].toString(),
          brand: c["brand"],
          title: c["title"],
          offerType: c["coupon_type"],
          coinCost: c["cost"],
          description: c["description"],
          purchased: true,
        );
      }).toList();

      setState(() {
        myCoupons = loadedCoupons;
      });
    } catch (e) {
      print("My Coupons fetch error: $e");
    }
  }

  // ================= BUY COUPON =================
  void buyCoupon(CouponModel coupon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString("user_id");

      if (userId == null) {
        Get.snackbar("Error", "User not logged in");
        return;
      }

      final result = await ApiService.buyCoupon(coupon.id, userId);

      if (result["success"] == false) {
        Get.snackbar("Error", result["message"]);
        return;
      }

      setState(() {
        myCoupons.add(coupon);
      });

      Get.snackbar("Success", "Coupon purchased successfully");
    } catch (e) {
      Get.snackbar("Error", "Something went wrong");
    }
  }

  bool isPurchased(String couponId) {
    return myCoupons.any((c) => c.id == couponId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon:
              const Icon(Icons.chevron_left, color: Color(0XFFfdd708), size: 40),
          onPressed: () {
            Get.back();
          },
        ),
        toolbarHeight: 60,
        elevation: 0.2,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "Coupon Store",
          style: TextStyle(
              color: Color(0XFFfdd708),
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Store"),
            Tab(text: "My Coupons"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_storeTab(), _myCouponsTab()],
      ),
    );
  }

  // ================= STORE TAB =================
  Widget _storeTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (coupons.isEmpty) {
      return const Center(child: Text("No coupons available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: coupons.length,
      itemBuilder: (_, index) {
        final coupon = coupons[index];
        final purchased = isPurchased(coupon.id);
        final canBuy = widget.userCoins >= coupon.coinCost && !purchased;

        return Card(
          elevation: 3,
          color: Colors.white30,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0XFF184b8c),
              child: Text(
                coupon.brand[0],
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon.brand,
                  style: const TextStyle(color: Colors.green),
                ),
                Text(
                  coupon.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(coupon.description),
                const SizedBox(height: 4),
                _offerBadge(coupon.offerType),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: canBuy ? () => buyCoupon(coupon) : null,
              child: Text(purchased
                  ? "Purchased"
                  : "${coupon.coinCost} 🪙"),
            ),
          ),
        );
      },
    );
  }

  // ================= MY COUPONS TAB =================
  Widget _myCouponsTab() {
    if (myCoupons.isEmpty) {
      return const Center(child: Text("No coupons purchased yet"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: myCoupons.length,
      itemBuilder: (_, index) {
        final coupon = myCoupons[index];

        return Card(
          child: ListTile(
            title: Text(
              coupon.title,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(coupon.brand),
            trailing: const Icon(Icons.qr_code),
          ),
        );
      },
    );
  }

  // ================= OFFER BADGE =================
  Widget _offerBadge(String type) {
    Color color;
    String text;

    switch (type) {
      case "FLAT":
        color = Colors.green;
        text = "FLAT OFF";
        break;
      case "PERCENT":
        color = Colors.blue;
        text = "% OFF";
        break;
      default:
        color = Colors.orange;
        text = "BOGO";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}

// ================= COUPON MODEL =================
class CouponModel {
  final String id;
  final String brand;
  final String title;
  final String offerType;
  final int coinCost;
  final String description;
  final bool purchased;

  CouponModel({
    required this.id,
    required this.brand,
    required this.title,
    required this.offerType,
    required this.coinCost,
    required this.description,
    this.purchased = false,
  });
}