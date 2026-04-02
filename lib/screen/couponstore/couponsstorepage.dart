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
  late int currentCoins;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    currentCoins =
        widget.userCoins; // Track dynamic balance deduction optimally

    fetchCoupons();
    fetchMyCoupons();
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
        Get.snackbar(
          "Auth Error",
          "User session not located.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
        );
        return;
      }

      final result = await ApiService.buyCoupon(coupon.id, userId);

      if (result["success"] == false) {
        Get.snackbar(
          "Transaction Failed",
          result["message"],
          backgroundColor: Colors.orange.shade800,
          colorText: Colors.white,
        );
        return;
      }

      setState(() {
        myCoupons.add(coupon);
        currentCoins -=
            coupon.coinCost; // Dynamic immediate UI subtraction sync!
      });

      Get.snackbar(
        "Coupon Secured!",
        "It's successfully parked in your wallet.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade800,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );
    } catch (e) {
      Get.snackbar(
        "Connection Interrupted",
        "Something went securely wrong",
        backgroundColor: Colors.red.shade800,
        colorText: Colors.white,
      );
    }
  }

  bool isPurchased(String couponId) {
    return myCoupons.any((c) => c.id == couponId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0XFF184B8C),
            size: 22,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Rewards Store",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          /// Integrated Balance indicator directly bridging purchasing capabilities!
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$currentCoins 🪙",
                  style: TextStyle(
                    color: Colors.amber.shade900,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0XFF184B8C),
          unselectedLabelColor: Colors.blueGrey.shade400,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          indicatorColor: const Color(0XFF184B8C),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.grey.shade200,
          tabs: const [
            Tab(text: "Explore Store"),
            Tab(text: "My Coupons"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [_storeTab(), _myCouponsTab()],
      ),
    );
  }

  // ================= STORE TAB =================
  Widget _storeTab() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                color: Color(0XFF184b8c),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Syncing available inventory...",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (coupons.isEmpty) {
      return _buildEmptyState(
        "Store Empty",
        "No active discounts exist on the board at the moment. Keep parking safely, we'll reload soon.",
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 16, bottom: 40, left: 16, right: 16),
      itemCount: coupons.length,
      itemBuilder: (_, index) {
        final coupon = coupons[index];
        final purchased = isPurchased(coupon.id);
        final canBuy = currentCoins >= coupon.coinCost && !purchased;

        return _buildModernVoucherCard(
          coupon: coupon,
          isPurchased: purchased,
          canBuy: canBuy,
          onPurchase: () => buyCoupon(coupon),
        );
      },
    );
  }

  // ================= MY COUPONS TAB =================
  Widget _myCouponsTab() {
    if (myCoupons.isEmpty) {
      return _buildEmptyState(
        "Nothing Claimed",
        "Your coupon storage is currently blank.\nNavigate to 'Explore Store' and claim brand rewards.",
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 16, bottom: 40, left: 16, right: 16),
      itemCount: myCoupons.length,
      itemBuilder: (_, index) {
        final coupon = myCoupons[index];

        return _buildModernOwnedCard(coupon);
      },
    );
  }

  // ================= MODERN VOUCHER UI GENERATOR =================
  Widget _buildModernVoucherCard({
    required CouponModel coupon,
    required bool isPurchased,
    required bool canBuy,
    required VoidCallback onPurchase,
  }) {
    // Identify visual cues distinctly depending on availability
    Color buttonColor = isPurchased
        ? Colors.green.shade600
        : (canBuy ? const Color(0XFF184B8C) : Colors.grey.shade300);
    Color buttonTextColor = (isPurchased || canBuy)
        ? Colors.white
        : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            /// Stylish Brand Initial Indicator
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0XFF184b8c).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  coupon.brand.isNotEmpty ? coupon.brand[0].toUpperCase() : "?",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0XFF184B8C),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            /// Information Middle Segment
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        coupon.brand.toUpperCase(),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      _offerBadge(
                        coupon.offerType,
                      ), // Retained logic perfectly mapped!
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coupon.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coupon.description,
                    style: TextStyle(
                      color: Colors.blueGrey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            /// Integrated Smart Transaction Side button!
            ElevatedButton(
              onPressed: canBuy ? onPurchase : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                disabledBackgroundColor:
                    buttonColor, // forces retaining visually blocked aesthetic smoothly
                elevation: canBuy ? 4 : 0,
                shadowColor: canBuy
                    ? const Color(0XFF184B8C).withOpacity(0.4)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isPurchased
                    ? "Owned"
                    : (canBuy
                          ? "Unlock\n${coupon.coinCost} 🪙"
                          : "Locked\n${coupon.coinCost} 🪙"),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: buttonTextColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= MODERN OWNED COUPON =================
  Widget _buildModernOwnedCard(CouponModel coupon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Card Base content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0XFF184B8C), Color(0XFF12325E)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0XFF184B8C).withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.brand.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.blueGrey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        coupon.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 40,
                  color: Colors.grey.shade400,
                ), // Preserving your exact core UX!
              ],
            ),
          ),

          /// Visually beautiful physical perforated tearing edge imitation separator
          Row(
            children: List.generate(
              35,
              (index) => Expanded(
                child: Container(
                  color: index.isEven
                      ? Colors.grey.shade300
                      : Colors.transparent,
                  height: 2,
                ),
              ),
            ),
          ),

          /// Context Footer Data block
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.green,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Active & Ready",
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Text(
                  "Redeem In-Store/Online",
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= ELEGANT FALLBACK =================
  Widget _buildEmptyState(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 40,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blueGrey.shade400,
              fontWeight: FontWeight.w500,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ================= PREMIUM OFFER BADGE =================
  Widget _offerBadge(String type) {
    Color color;
    Color bTint;
    String text;

    switch (type.toUpperCase()) {
      case "FLAT":
        color = Colors.green.shade800;
        bTint = Colors.green.shade100;
        text = "FLAT OFF";
        break;
      case "PERCENT":
        color = Colors.blue.shade800;
        bTint = Colors.blue.shade100;
        text = "% OFF";
        break;
      default:
        color = Colors.orange.shade800;
        bTint = Colors.orange.shade100;
        text = "BOGO DEAL";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bTint,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ================= COUPON MODEL =================
// (Absolutely untouched structural mapping preservation)
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
