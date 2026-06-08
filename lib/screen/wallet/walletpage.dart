import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:parkingmudde/screen/couponstore/couponsstorepage.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/services/razorpay_web_checkout.dart';
import '../../providers/wallet_provider.dart';
import 'earncoinspage.dart';
import 'my_subscriptions_page.dart';

class WalletScreen extends StatefulWidget {
  final int totalCoins;

  const WalletScreen({super.key, required this.totalCoins});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color secondaryYellow = Color(0xFFFFB703);
  static const Color textBlack = Color(0xFF222222);
  static const Color subTextGrey = Color(0xFF888888);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color earnGreen = Color(0xFF20C475);

  late Razorpay _razorpay;
  String? _pendingPackageId; // tracks which package is being paid for
  bool _razorpayEventReceived = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) context.read<WalletProvider>().fetchWallet();
    });
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ─── Razorpay event handlers ───────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    _razorpayEventReceived = true;
    final packageId = _pendingPackageId;
    _pendingPackageId = null;
    if (packageId == null) return;

    final result = await ApiService.verifyRazorpayPayment(
      packageId: packageId,
      razorpayPaymentId: response.paymentId ?? '',
      razorpayOrderId: response.orderId ?? '',
      razorpaySignature: response.signature ?? '',
    );

    if (!mounted) return;
    if (result['success'] == true) {
      await context.read<WalletProvider>().fetchWallet();
      Get.snackbar(
        '🎉 Payment Successful',
        result['message']?.toString() ?? 'Coins added to your wallet!',
        backgroundColor: const Color(0xFF20C475),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } else {
      Get.snackbar(
        'Verification Failed',
        result['message']?.toString() ?? 'Payment received but verification failed. Contact support.',
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _razorpayEventReceived = true;
    _pendingPackageId = null;
    Get.defaultDialog(
      title: "Payment Failed",
      middleText: response.message ?? 'Payment was not completed or was cancelled.',
      textConfirm: "OK",
      onConfirm: () => Get.back(),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _razorpayEventReceived = true;
    _pendingPackageId = null;
    Get.defaultDialog(
      title: "External Wallet",
      middleText: 'Payment via ${response.walletName} selected.',
      textConfirm: "OK",
      onConfirm: () => Get.back(),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// Listen to wallet provider smoothly mapping layout forms mapping layouts
    final walletProvider = context.watch<WalletProvider>();
    final walletCoins = walletProvider.pmCoinsBalance;
    final coinsbackBalance = walletProvider.coinsbackBalance;
    final transactions = walletProvider.transactions;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white, // Stark clean background
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: primaryBlue,
              size: 20,
            ),
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
          title: const Text(
            "My Wallet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textBlack,
            ),
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Master Wallet Block bounded natively space layout standard limit forms maps standard mapping limits bound mapping map bounds limit boundaries limits layout mapping boundary
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 16,
                    bottom: 24,
                  ),
                  child: Column(
                    children: [
                      // 1. Beautiful Orange Card
                      _buildFigmaOrangeWalletCard(walletCoins.toString()),

                      const SizedBox(height: 24),

                      // 2. Exact Quick Actions Twin Buttons constraints mapping mappings
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.add_circle,
                              iconColor: primaryBlue,
                              label: "Earn Coins",
                              onTap: () => Get.to(() => const EarnCoinsPage()),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildActionButton(
                              icon: Icons.card_giftcard_rounded,
                              iconColor: secondaryYellow,
                              label: "Use Coins",
                              onTap: () => Get.to(() => CouponStoreScreen(coinsbackBalance: coinsbackBalance)),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildWalletSummary(
                        coinsbackBalance: coinsbackBalance,
                        spentCoins: walletProvider.coinsbackSpent,
                        rewardsCount: transactions
                            .where(
                              (txn) => txn['description']
                                  .toString()
                                  .toLowerCase()
                                  .contains("coupon"),
                            )
                            .length,
                      ),

                      const SizedBox(height: 24),

                      _buildRedeemRewardsPanel(coinsbackBalance),

                      const SizedBox(height: 12),

                      _buildMySubscriptionsPanel(walletProvider),

                      const SizedBox(height: 24),

                      _buildAdBanner(),

                      const SizedBox(height: 24),

                      _buildPackageSection(
                        title: "Coin Packages",
                        subtitle:
                            "Load your wallet with coins for alerts, calls and rewards.",
                        packages: const [
                          _WalletPackage("coins_starter", "Starter Top-up", "100 coins", "Starter PM Coins top-up", Icons.add_card_rounded),
                          _WalletPackage("coins_plus", "Plus Top-up", "250 coins", "Best value for regular alerts and rewards", Icons.account_balance_wallet_rounded),
                          _WalletPackage("coins_max", "Max Top-up", "500 coins", "High usage PM Coins wallet top-up", Icons.savings_rounded),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildPackageSection(
                        title: "Vehicle Document Renewal Alerts",
                        subtitle:
                            "Renewal reminder packages for insurance and pollution validity.",
                        packages: const [
                          _WalletPackage("renewal_1_year", "1 Year Renewal Alerts", "200 PM Coins", "Insurance and pollution renewal reminders", Icons.event_repeat_rounded),
                          _WalletPackage("renewal_3_years", "3 Years Renewal Alerts", "400 PM Coins", "Popular document reminder package", Icons.notifications_active_rounded),
                          _WalletPackage("renewal_5_years", "5 Years Renewal Alerts", "500 PM Coins", "Long-term insurance and PUC reminders", Icons.verified_rounded),
                        ],
                      ),

                      const SizedBox(height: 24),

                      _buildPackageSection(
                        title: "All-in-One Solutions",
                        subtitle:
                            "Individual Silver, Gold and Platinum parking support packages.",
                        packages: const [
                          _WalletPackage("solution_silver", "Silver Solution", "Request", "Essential individual parking support", Icons.workspace_premium_rounded),
                          _WalletPackage("solution_gold", "Gold Solution", "Request", "Priority individual parking support", Icons.military_tech_rounded),
                          _WalletPackage("solution_platinum", "Platinum Solution", "Request", "Complete individual parking support", Icons.diamond_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Activity Log Start layouts maps map bounds boundaries map bound mapping limits mapping constraints mapping form mappings
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 12,
                  ),
                  child: Text(
                    "Activity Status",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textBlack,
                    ),
                  ),
                ),
              ),

              // THE DYNAMIC RENDER OF YOUR EXISTING TRANSACTIONS ARRAY LOGIC constraints boundaries mapping spaces layouts boundaries spaces standard boundary mapping maps limits maps mapped bounds boundary
              if (transactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyTransactionsState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 40,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final txn = transactions[index];
                      // Inherited Logic checks standard mapping layout boundary limit
                      final isCredit =
                          txn['type'] == "earn" || txn['type'] == "refund";

                      return _buildFigmaTransactionTile(txn, isCredit);
                    }, childCount: transactions.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // THE PERFECT FIGMA MAIN ORANGE GRADIENT WALLET BOX limits mappings spaces mapping forms boundary bounds layout boundary layouts map constraint bound map limits mapping bounds boundary constraint maps limits limits space
  // ──────────────────────────────────────────────────────────
  Widget _buildFigmaOrangeWalletCard(String totalValue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFAD1D),
            Color(0xFFFF7B00),
          ], // Striking precise Figma extract orange mappings limits mappings boundary standard bound limits mapped
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF9000).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Colors.white,
              size: 28,
            ), // Abstract replacement native rendering mapping bounds spaces layout standard mapped
          ),
          const SizedBox(height: 12),
          const Text(
            "PM Coins",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            totalValue,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 44,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Earn coins by helping others and parking\nresponsibly",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Double Generic Outlined Border Flat buttons boundary spaces standard
  // ──────────────────────────────────────────────────────────
  Widget _buildActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: borderGrey, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: textBlack,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSummary({
    required int coinsbackBalance,
    required int spentCoins,
    required int rewardsCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _summaryTile(
            title: "Coinsback",
            value: coinsbackBalance.toString(),
            icon: Icons.trending_up_rounded,
            color: earnGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryTile(
            title: "Rewards",
            value: rewardsCount.toString(),
            icon: Icons.card_giftcard_rounded,
            color: secondaryYellow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryTile(
            title: "Spent",
            value: spentCoins.toString(),
            icon: Icons.receipt_long_rounded,
            color: primaryBlue,
          ),
        ),
      ],
    );
  }

  Widget _summaryTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: textBlack,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: subTextGrey,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemRewardsPanel(int coinsbackBalance) {
    return InkWell(
      onTap: () => Get.to(() => CouponStoreScreen(coinsbackBalance: coinsbackBalance)),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF5),
          border: Border.all(color: const Color(0xFFFEF2CE), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0CA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.stars_rounded,
                color: Color(0xFFFEB416),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Redeem Rewards",
                    style: TextStyle(
                      color: textBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Use coinsback for brand coupons and offers",
                    style: TextStyle(
                      color: subTextGrey.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              "View",
              style: TextStyle(
                color: Color(0xFFF9662C),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMySubscriptionsPanel(WalletProvider wallet) {
    final activeCount = wallet.subscriptions.where(
      (s) => s['status'] == 'ACTIVE',
    ).length;

    return InkWell(
      onTap: () => Get.to(() => const MySubscriptionsPage()),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          border: Border.all(color: const Color(0xFFD0DCFF), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFDDE5FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "My Subscriptions",
                    style: TextStyle(
                      color: textBlack,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeCount > 0
                      ? "$activeCount active plan${activeCount > 1 ? 's' : ''} · View details & documents"
                      : "No active plans · Purchase a renewal package",
                    style: TextStyle(
                      color: subTextGrey.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              activeCount > 0 ? "View" : "Get",
              style: const TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageSection({
    required String title,
    required String subtitle,
    required List<_WalletPackage> packages,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textBlack,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: subTextGrey,
            fontSize: 12,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...packages.map(_packageTile),
      ],
    );
  }

  Widget _packageTile(_WalletPackage package) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderGrey),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              package.icon,
              color: primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  package.name,
                  style: const TextStyle(
                    color: textBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  package.description,
                  style: const TextStyle(
                    color: subTextGrey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => _purchasePackage(package),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              package.value,
              style: const TextStyle(
                color: primaryBlue,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchasePackage(_WalletPackage package) async {
    // Coin packages → go through Razorpay payment sheet
    if (package.id.startsWith('coins_')) {
      await _startRazorpayPayment(package);
      return;
    }

    // Renewal packages → confirm with PM Coins
    if (package.id.startsWith('renewal_')) {
      _showRenewalPurchaseSheet(package);
      return;
    }

    // Request-type packages (solutions) → backend request only
    final result = await ApiService.purchaseWalletPackage(packageId: package.id);
    if (!mounted) return;

    if (result['success'] == true) {
      Get.snackbar(
        'Request Submitted',
        result['message']?.toString() ?? '${package.name} request submitted.',
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } else {
      Get.snackbar(
        'Request Failed',
        result['message']?.toString() ?? 'Could not process request.',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  void _showRenewalPurchaseSheet(_WalletPackage package) {
    final wallet = context.read<WalletProvider>();
    final costText = package.value; // e.g. "200 PM Coins"
    final cost = int.tryParse(costText.split(' ')[0]) ?? 0;
    final hasEnough = wallet.pmCoinsBalance >= cost;
    final alreadyActive = wallet.hasActiveSubscription(package.id);
    final endDate = wallet.subscriptionEndDate(package.id);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40, height: 5,
              decoration: BoxDecoration(
                color: borderGrey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),

            // Package icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(package.icon, color: primaryBlue, size: 32),
            ),
            const SizedBox(height: 16),

            // Package name
            Text(
              package.name,
              style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: textBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              package.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: subTextGrey, fontSize: 13, fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Covers all your registered vehicles",
              style: TextStyle(
                color: primaryBlue.withOpacity(0.8), fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (alreadyActive) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: earnGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded, color: earnGreen, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "Active until $endDate",
                      style: const TextStyle(
                        color: earnGreen, fontWeight: FontWeight.bold, fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Price box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: backgroundLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderGrey),
              ),
              child: Column(
                children: [
                  Text(
                    "$cost",
                    style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w900, color: textBlack,
                    ),
                  ),
                  const Text(
                    "PM Coins",
                    style: TextStyle(
                      color: subTextGrey, fontWeight: FontWeight.bold, fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your balance: ${wallet.pmCoinsBalance} coins",
                    style: TextStyle(
                      color: hasEnough ? earnGreen : Colors.red.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Buy button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: hasEnough ? () async {
                  Get.back(); // close sheet
                  await _executeRenewalPurchase(package);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasEnough ? primaryBlue : Colors.grey.shade300,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: hasEnough ? 4 : 0,
                ),
                child: Text(
                  hasEnough
                    ? (alreadyActive ? "Extend Subscription" : "Buy with PM Coins")
                    : "Insufficient Coins",
                  style: TextStyle(
                    color: hasEnough ? Colors.white : Colors.grey.shade600,
                    fontSize: 16, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (!hasEnough) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Get.back();
                  Get.to(() => const EarnCoinsPage());
                },
                child: const Text(
                  "Earn more coins →",
                  style: TextStyle(
                    color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _executeRenewalPurchase(_WalletPackage package) async {
    // Show loading
    Get.defaultDialog(
      title: '',
      content: Column(
        children: [
          const CircularProgressIndicator(color: primaryBlue),
          const SizedBox(height: 16),
          const Text("Processing purchase...",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    final result = await ApiService.purchaseWalletPackage(packageId: package.id);
    Get.back(); // close loading

    if (!mounted) return;

    if (result['success'] == true) {
      await context.read<WalletProvider>().fetchWallet();
      Get.snackbar(
        '🎉 Purchase Successful',
        result['message']?.toString() ?? '${package.name} activated!',
        backgroundColor: earnGreen,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
    } else {
      Get.snackbar(
        'Purchase Failed',
        result['message']?.toString() ?? 'Could not process purchase.',
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _startRazorpayPayment(_WalletPackage package) async {
    Get.defaultDialog(
      title: "Processing",
      content: const CircularProgressIndicator(),
      barrierDismissible: false,
    );

    // Step 1: Ask the backend to create a Razorpay order
    final orderResult = await ApiService.createRazorpayOrder(packageId: package.id);
    
    // Close the loading dialog
    if (Get.isDialogOpen == true) {
      Get.back();
      await Future.delayed(const Duration(milliseconds: 300));
    }
    
    if (!mounted) return;

    final razorpayOrderId = orderResult['razorpay_order_id']?.toString();
    final razorpayKeyId = orderResult['razorpay_key_id']?.toString();

    if (razorpayOrderId == null ||
        razorpayOrderId.isEmpty ||
        razorpayKeyId == null ||
        razorpayKeyId.isEmpty) {
      Get.defaultDialog(
        title: "API Error",
        middleText: orderResult['message']?.toString() ?? 'Could not initiate payment from backend.',
        textConfirm: "OK",
        onConfirm: () => Get.back(),
      );
      return;
    }

    // Step 2: Open Razorpay checkout sheet
    _pendingPackageId = package.id;
    _razorpayEventReceived = false;
    final options = {
      'key': razorpayKeyId,
      'order_id': razorpayOrderId,
      'amount': orderResult['amount'],           // in paise
      'currency': orderResult['currency'] ?? 'INR',
      'name': 'Parking Mudde',
      'description': '${package.name} - ${package.value}',
      'prefill': {
        'contact': '9999999999',
        'email': 'payments@parkingmudde.com',
      },
      'retry': {'enabled': true, 'max_count': 1},
      'theme': {'color': '#2A5EE8'},
    };

    if (kIsWeb) {
      try {
        await openRazorpayWebCheckout(
          Map<String, dynamic>.from(options),
          onSuccess: (response) async {
            _razorpayEventReceived = true;
            final packageId = _pendingPackageId;
            _pendingPackageId = null;
            if (packageId == null || !mounted) return;

            final result = await ApiService.verifyRazorpayPayment(
              packageId: packageId,
              razorpayPaymentId: response['razorpay_payment_id']?.toString() ?? '',
              razorpayOrderId: response['razorpay_order_id']?.toString() ?? '',
              razorpaySignature: response['razorpay_signature']?.toString() ?? '',
            );

            if (!mounted) return;
            if (result['success'] == true) {
              await context.read<WalletProvider>().fetchWallet();
              Get.snackbar(
                'Payment Successful',
                result['message']?.toString() ?? 'Coins added to your wallet!',
                backgroundColor: const Color(0xFF20C475),
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
              );
            } else {
              Get.snackbar(
                'Verification Failed',
                result['message']?.toString() ?? 'Payment received but verification failed.',
                backgroundColor: Colors.orange.shade700,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
              );
            }
          },
          onFailure: (message) {
            _razorpayEventReceived = true;
            _pendingPackageId = null;
            Get.defaultDialog(
              title: "Payment Failed",
              middleText: message,
              textConfirm: "OK",
              onConfirm: () => Get.back(),
            );
          },
          onDismiss: () {
            _razorpayEventReceived = true;
            _pendingPackageId = null;
          },
        );
      } catch (e) {
        _pendingPackageId = null;
        Get.defaultDialog(
          title: "Payment Error",
          middleText: "Could not open Razorpay on web. Error: $e",
          textConfirm: "OK",
          onConfirm: () => Get.back(),
        );
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _razorpay.open(options);
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted || _razorpayEventReceived || _pendingPackageId == null) {
            return;
          }
          Get.snackbar(
            'Payment Window Not Opened',
            'Razorpay did not launch on this device. Please fully close and reopen the app, then try again.',
            backgroundColor: Colors.orange.shade700,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
          );
        });
      } catch (e) {
        _pendingPackageId = null;
        Get.defaultDialog(
          title: "Plugin Error",
          middleText: "Razorpay is not installed properly. Did you completely stop and restart the app? Error: $e",
          textConfirm: "OK",
          onConfirm: () => Get.back(),
        );
      }
    });
  }

  // ──────────────────────────────────────────────────────────
  // Activity Mapping Row! Converts data specifically matched closely logic maps constraints bounded constraints
  // ──────────────────────────────────────────────────────────
  Widget _buildFigmaTransactionTile(dynamic txn, bool isCredit) {
    String descText = txn['description'].toString();
    final icon = _transactionIcon(descText, txn['type']?.toString() ?? "");
    final dynamicAvatarColor =
        _transactionColor(descText, txn['type']?.toString() ?? "");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey, width: 1.2),
      ),
      child: InkWell(
        onTap: () => _showTransactionDetails(txn, isCredit),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: dynamicAvatarColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: dynamicAvatarColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textBlack,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTransactionTime(txn['created_at']),
                      style: TextStyle(
                        color: subTextGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${isCredit ? '+' : '-'}${txn['coins']}",
                    style: TextStyle(
                      color: isCredit ? earnGreen : textBlack,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Coins",
                    style: TextStyle(
                      color: subTextGrey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.remove_red_eye_rounded,
                color: subTextGrey.withOpacity(0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(dynamic txn, bool isCredit) {
    final amountText = "${isCredit ? '+' : '-'}${txn['coins']}";
    final color = isCredit ? earnGreen : textBlack;
    
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: borderGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Transaction Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: textBlack,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCredit ? "Earned" : "Spent",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    amountText,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "PM Coins",
                    style: TextStyle(
                      color: subTextGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _detailRow("Description", txn['description']?.toString() ?? "N/A"),
            const Divider(color: borderGrey, height: 32),
            _detailRow("Date & Time", _formatTransactionTime(txn['created_at'])),
            const Divider(color: borderGrey, height: 32),
            _detailRow("Transaction ID", txn['id']?.toString() ?? "N/A"),
            if (txn['reference_id'] != null) ...[
              const Divider(color: borderGrey, height: 32),
              _detailRow("Reference ID", txn['reference_id'].toString()),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: textBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Close",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: subTextGrey,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: textBlack,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 40,
              color: Colors.blueGrey.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Recent Activity",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "When you start participating in helping \nother users, records will show up securely right here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextGrey,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _transactionIcon(String description, String type) {
    final lower = description.toLowerCase();
    if (lower.contains("coupon")) return Icons.card_giftcard_rounded;
    if (lower.contains("package")) return Icons.account_balance_wallet_rounded;
    if (lower.contains("referral")) return Icons.share_rounded;
    if (lower.contains("vehicle")) return Icons.directions_car_rounded;
    if (lower.contains("parking")) return Icons.local_parking_rounded;
    if (lower.contains("help")) return Icons.volunteer_activism_rounded;
    if (type == "spend") return Icons.payments_rounded;
    return Icons.monetization_on_rounded;
  }

  Color _transactionColor(String description, String type) {
    final lower = description.toLowerCase();
    if (lower.contains("coupon")) return const Color(0xFFF97316);
    if (lower.contains("package")) return primaryBlue;
    if (lower.contains("referral")) return const Color(0xFF0F766E);
    if (lower.contains("vehicle")) return const Color(0xFF7C3AED);
    if (lower.contains("parking")) return const Color(0xFFA855F7);
    if (lower.contains("help")) return earnGreen;
    if (type == "spend") return Colors.red.shade600;
    return const Color(0xFF5E6FF4);
  }

  String _formatTransactionTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? "");
    if (date == null) return "Recently";
    final hour = date.hour.toString().padLeft(2, "0");
    final minute = date.minute.toString().padLeft(2, "0");
    return "${date.day}/${date.month}/${date.year} at $hour:$minute";
  }
}

  // ================= AdB3 — SPONSORED BANNER =================
  Widget _buildAdBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3A6B), Color(0xFF0F2447)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF184B8C).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative background circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sponsored tag
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            "SPONSORED",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Your Brand Here",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Partner with ParkingMudde and reach thousands of vehicle owners.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () {
                            // TODO: Replace with real brand link or deep link
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              "Learn More →",
                              style: TextStyle(
                                color: Color(0xFF1A3A6B),
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Placeholder brand logo area
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.business_rounded,
                      color: Colors.white.withOpacity(0.4),
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

class _WalletPackage {
  final String id;
  final String name;
  final String value;
  final String description;
  final IconData icon;

  const _WalletPackage(this.id, this.name, this.value, this.description, this.icon);
}
