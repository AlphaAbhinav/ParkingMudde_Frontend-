import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/couponstore/couponsstorepage.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:parkingmudde/services/razorpay_web_checkout.dart';
import 'package:parkingmudde/widgets/dynamic_ad_carousel.dart';
import '../../providers/wallet_provider.dart';
import 'earncoinspage.dart';
import 'my_subscriptions_page.dart';
import 'package:parkingmudde/widgets/screen_slogan.dart';

class WalletScreen extends StatefulWidget {
  final int totalCoins;
  final bool returnOnSuccessfulTopUp;

  const WalletScreen({
    super.key,
    required this.totalCoins,
    this.returnOnSuccessfulTopUp = false,
  });

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
  String? _pendingPackageId;
  bool _razorpayEventReceived = false;
  List<_WalletPackage> _coinPackages = [];
  List<_WalletPackage> _renewalPackages = [];
  List<_WalletPackage> _solutionPackages = [];
  bool _packagesLoading = true;
  bool _walletLoading = true;
  double _coinValueInr = 1;

  // New UI State Variables
  int _selectedTabIndex = 0; // 0: Overview, 1: Store, 2: History
  String _transactionFilter = 'All'; // 'All', 'Earned', 'Spent'

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        _loadWallet();
        _loadWalletPackages();
      }
    });
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  Future<void> _refreshAll() async {
    HapticFeedback.lightImpact();
    await Future.wait([_loadWallet(), _loadWalletPackages()]);
  }

  Future<void> _loadWallet() async {
    await context.read<WalletProvider>().fetchWallet();
    if (!mounted) return;
    setState(() => _walletLoading = false);
  }

  Future<void> _loadWalletPackages() async {
    try {
      final packageRows = await ApiService.fetchWalletPackages();
      final coinConfig = await ApiService.fetchCoinConfig();
      if (!mounted) return;

      var coinValueInr = (coinConfig['coin_value_inr'] ?? 0).toDouble();
      if (coinValueInr <= 0) {
        for (final row in packageRows) {
          final coins =
              int.tryParse(row['coins_delta']?.toString() ?? '0') ?? 0;
          final priceInr =
              double.tryParse(row['price_inr']?.toString() ?? '0') ?? 0;
          if (coins > 0 && priceInr > 0) {
            coinValueInr = priceInr / coins;
            break;
          }
        }
      }
      if (coinValueInr <= 0) coinValueInr = 1;

      final mapped = packageRows
          .map((row) => _walletPackageFromApi(row, coinValueInr))
          .toList();

      setState(() {
        _coinValueInr = coinValueInr;
        _packagesLoading = false;
        _coinPackages = mapped
            .where((package) => package.category == 'coin_package')
            .toList();
        _renewalPackages = mapped
            .where((package) => package.category == 'renewal_alert')
            .toList();
        _solutionPackages = mapped
            .where((package) => package.category == 'all_in_one')
            .toList();
      });
    } catch (e) {
      debugPrint('Load Wallet Packages Exception: $e');
      if (!mounted) return;
      setState(() => _packagesLoading = false);
    }
  }

  _WalletPackage _walletPackageFromApi(
    Map<String, dynamic> row,
    double coinValueInr,
  ) {
    final id = row['package_id']?.toString() ?? '';
    final category = row['category']?.toString() ?? '';
    final name = row['name']?.toString() ?? id;
    final value = row['value']?.toString() ?? '';
    final description = row['description']?.toString() ?? '';
    final coinsDelta = int.tryParse(row['coins_delta']?.toString() ?? '0') ?? 0;
    final serverPrice = _normalizeRupeeLabel(row['price_label']?.toString());
    final originalPrice = _normalizeRupeeLabel(
      row['original_price_label']?.toString(),
    );
    final offerDiscountPercent =
        int.tryParse(row['offer_discount_percent']?.toString() ?? '0') ?? 0;
    final offerTag = row['offer_tag']?.toString();
    final price = category == 'coin_package' && coinsDelta > 0
        ? (serverPrice != null && serverPrice.isNotEmpty
              ? serverPrice
              : _formatRupees(coinsDelta * coinValueInr))
        : null;

    return _WalletPackage(
      id,
      category == 'coin_package' ? '$name Top-up' : name,
      value,
      description,
      _iconForPackage(id, category),
      price,
      category,
      originalPrice,
      offerDiscountPercent,
      offerTag,
      coinsDelta,
    );
  }

  String _formatInr(num value) {
    final fixed = value.toStringAsFixed(2);
    return fixed
        .replaceFirst(RegExp(r'\.0+$'), '')
        .replaceFirst(RegExp(r'(\.\d*[1-9])0+$'), r'$1');
  }

  String _formatRupees(num value) => '₹  ${_formatInr(value)}';

  String? _normalizeRupeeLabel(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed.replaceFirst(
      RegExp(r'^(?:Rs\.?|INR|₹)\s*', caseSensitive: false),
      '₹  ',
    );
  }

  IconData _iconForPackage(String id, String category) {
    if (id.contains('plus')) return Icons.account_balance_wallet_rounded;
    if (id.contains('max')) return Icons.savings_rounded;
    if (id.contains('3')) return Icons.notifications_active_rounded;
    if (id.contains('5')) return Icons.verified_rounded;
    if (id.contains('silver')) return Icons.workspace_premium_rounded;
    if (id.contains('gold')) return Icons.military_tech_rounded;
    if (id.contains('platinum')) return Icons.diamond_rounded;
    if (category == 'renewal_alert') return Icons.event_repeat_rounded;
    return Icons.add_card_rounded;
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _razorpay.clear();
    }
    super.dispose();
  }

  // ─── Refined Helper Modals ─────────────────────────────────

  void _showInfoBottomSheet(
    String title,
    String message, {
    bool isError = false,
  }) {
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
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: borderGrey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.info_outline_rounded,
              color: isError ? Colors.red : primaryBlue,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: subTextGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: textBlack,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "OK",
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

  Future<void> _returnToPreviousFlowAfterTopUp() async {
    if (!widget.returnOnSuccessfulTopUp || !mounted) return;
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    }
  }

  void _showLoadingBottomSheet() {
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
            const CircularProgressIndicator(color: primaryBlue),
            const SizedBox(height: 16),
            const Text(
              "Processing...",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isDismissible: false,
      enableDrag: false,
    );
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
      await _returnToPreviousFlowAfterTopUp();
    } else {
      _showInfoBottomSheet(
        'Verification Failed',
        result['message']?.toString() ??
            'Payment received but verification failed. Contact support.',
        isError: true,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _razorpayEventReceived = true;
    _pendingPackageId = null;
    _showInfoBottomSheet(
      "Payment Failed",
      response.message ?? 'Payment was not completed or was cancelled.',
      isError: true,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _razorpayEventReceived = true;
    _pendingPackageId = null;
    _showInfoBottomSheet(
      "External Wallet",
      'Payment via ${response.walletName} selected.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final walletCoins = walletProvider.pmCoinsBalance;
    final coinsbackBalance = walletProvider.coinsbackBalance;
    final totalBalance = walletCoins + coinsbackBalance;
    final rawTransactions = walletProvider.transactions;
    final transactions = rawTransactions.where((txn) {
      final desc = (txn['description'] ?? txn['reason'] ?? '')
          .toString()
          .toLowerCase();
      final amountStr =
          txn['coins']?.toString() ?? txn['amount']?.toString() ?? "0";
      final amount = double.tryParse(amountStr.replaceAll('-', '')) ?? 0;
      if (desc.contains("report") && amount == 0) return false;
      return true;
    }).toList();

    final filteredTransactions = transactions.where((txn) {
      final isCredit = txn['type'] == 'earn' || txn['type'] == 'refund';
      if (_transactionFilter == 'Earned') return isCredit;
      if (_transactionFilter == 'Spent') return !isCredit;
      return true;
    }).toList();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
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
          child: RefreshIndicator(
            onRefresh: _refreshAll,
            color: primaryBlue,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Global Header section (Visible across all tabs)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 16,
                    ),
                    child: Column(
                      children: [
                        _buildPremiumBlueWalletCard(
                          _walletLoading ? null : totalBalance.toString(),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.add_circle,
                                iconColor: primaryBlue,
                                label: "Earn Coins",
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Get.to(() => const EarnCoinsPage());
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _buildActionButton(
                                icon: Icons.card_giftcard_rounded,
                                iconColor: secondaryYellow,
                                label: "Use Coins",
                                onTap: () async {
                                  HapticFeedback.lightImpact();
                                  await Get.to(
                                    () => CouponStoreScreen(
                                      coinsbackBalance:
                                          walletProvider.pmCoinsBalance +
                                          walletProvider.coinsbackBalance,
                                    ),
                                  );
                                  if (mounted) await _loadWallet();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSegmentedControl(),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // TAB 0: OVERVIEW
                if (_selectedTabIndex == 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          _buildDataVisualizedSummary(
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
                          _buildPremiumSubscriptionsPanel(walletProvider),
                          const SizedBox(height: 24),
                          const DynamicAdCarousel(pageName: 'Wallet'),
                          const SizedBox(height: 18),
                          const ScreenSlogan(
                            "Every coin tells a story.",
                            color: primaryBlue,
                            icon: Icons.local_parking_rounded,
                            imagePath: 'assets/walletslogan.png',
                            normalImageWidth: 150,
                            compactImageWidth: 128,
                            textMaxLines: 2,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                // TAB 1: STORE
                if (_selectedTabIndex == 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHorizontalPackageSection(
                            title: "Coin Packages",
                            subtitle:
                                "Load your wallet with coins for alerts, calls and rewards.",
                            packages: _coinPackages,
                          ),
                          const SizedBox(height: 32),
                          _buildHorizontalPackageSection(
                            title: "Vehicle Renewal Alerts",
                            subtitle:
                                "Reminder packages for insurance and pollution validity.",
                            packages: _renewalPackages,
                          ),
                          const SizedBox(height: 32),
                          _buildHorizontalPackageSection(
                            title: "All-in-One Solutions",
                            subtitle:
                                "Individual Silver, Gold and Platinum parking support.",
                            packages: _solutionPackages,
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),

                // TAB 2: HISTORY
                if (_selectedTabIndex == 2) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: _buildFilterChips(),
                    ),
                  ),
                  if (filteredTransactions.isEmpty)
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
                          final txn = filteredTransactions[index];
                          final isCredit =
                              txn['type'] == "earn" || txn['type'] == "refund";
                          return _buildFigmaTransactionTile(txn, isCredit);
                        }, childCount: filteredTransactions.length),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── UI Refinements ──────────────────────────────────────────

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderGrey),
      ),
      child: Row(
        children: [
          _buildSegment('Overview', 0),
          _buildSegment('Store', 1),
          _buildSegment('History', 2),
        ],
      ),
    );
  }

  Widget _buildSegment(String title, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedTabIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? primaryBlue : subTextGrey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: ['All', 'Earned', 'Spent'].map((label) {
          final isSelected = _transactionFilter == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  HapticFeedback.lightImpact();
                  setState(() => _transactionFilter = label);
                }
              },
              showCheckmark: false,
              selectedColor: primaryBlue.withOpacity(0.1),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? primaryBlue : subTextGrey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              side: BorderSide(color: isSelected ? primaryBlue : borderGrey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPremiumBlueWalletCard(String? totalValue) {
    final balanceText = totalValue ?? "--";
    final valueText = totalValue == null
        ? "Loading wallet"
        : _formatRupees((int.tryParse(totalValue) ?? 0) * _coinValueInr);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A5EE8), Color(0xFF1A3A6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A5EE8).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Total Balance",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  balanceText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 44,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    valueText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Earn coins by helping others and parking\nresponsibly",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          side: const BorderSide(
            color: borderGrey,
            width: 1.2,
          ), // Toned down border
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
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataVisualizedSummary({
    required int coinsbackBalance,
    required int spentCoins,
    required int rewardsCount,
  }) {
    final int totalEarned = coinsbackBalance + spentCoins;
    final double earnedRatio = totalEarned == 0
        ? 0
        : (coinsbackBalance / totalEarned).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  "Coinsback",
                  coinsbackBalance.toString(),
                  earnGreen,
                  Icons.trending_up_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: borderGrey),
              Expanded(
                child: _summaryStat(
                  "Rewards",
                  rewardsCount.toString(),
                  secondaryYellow,
                  Icons.card_giftcard_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: borderGrey),
              Expanded(
                child: _summaryStat(
                  "Spent",
                  spentCoins.toString(),
                  primaryBlue,
                  Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: (earnedRatio * 100).toInt() > 0
                      ? (earnedRatio * 100).toInt()
                      : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: earnGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                if (earnedRatio > 0 && earnedRatio < 1)
                  const SizedBox(width: 2),
                Expanded(
                  flex: ((1 - earnedRatio) * 100).toInt() > 0
                      ? ((1 - earnedRatio) * 100).toInt()
                      : 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Available Balance",
                style: TextStyle(
                  color: subTextGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Utilized",
                style: TextStyle(
                  color: subTextGrey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String title, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: textBlack,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(
            color: subTextGrey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRedeemRewardsPanel(int coinsbackBalance) {
    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        await Get.to(
          () => CouponStoreScreen(
            coinsbackBalance:
                context.read<WalletProvider>().pmCoinsBalance +
                context.read<WalletProvider>().coinsbackBalance,
          ),
        );
        if (mounted) await _loadWallet();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF5),
          border: Border.all(color: const Color(0xFFFEF2CE), width: 1.2),
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
                    "Use PM Coins for brand coupons and offers",
                    style: TextStyle(
                      color: subTextGrey.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSubscriptionsPanel(WalletProvider wallet) {
    final activeCount = wallet.subscriptions
        .where((s) => s['status'] == 'ACTIVE')
        .length;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.to(() => const MySubscriptionsPage());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A3A6B), Color(0xFF0F2447)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF184B8C).withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 100,
                  height: 100,
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
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
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
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeCount > 0
                                ? "$activeCount active plan${activeCount > 1 ? 's' : ''} · View details & documents"
                                : "No active plans · Explore renewal packages",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalPackageSection({
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
            fontWeight: FontWeight.bold,
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
        if (_packagesLoading)
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (_, __) =>
                  const _PulsingSkeleton(width: 180, height: 250),
            ),
          )
        else if (packages.isEmpty)
          _buildEmptyPackageState()
        else
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: packages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) => _packageCard(packages[index]),
            ),
          ),
      ],
    );
  }

  Widget _packageCard(_WalletPackage package) {
    final hasOffer =
        package.category == 'coin_package' && package.offerDiscountPercent > 0;
    final offerTag = (package.offerTag?.trim().isNotEmpty ?? false)
        ? package.offerTag!.trim()
        : 'Offer';

    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderGrey, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(package.icon, color: primaryBlue, size: 24),
              ),
              if (hasOffer) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: secondaryYellow.withOpacity(0.28),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: secondaryYellow.withOpacity(0.45),
                      ),
                    ),
                    child: Text(
                      '$offerTag ${package.offerDiscountPercent}% OFF',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8A5B00),
                        fontSize: 10,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Spacer(),
          Text(
            package.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textBlack,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            package.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: subTextGrey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (package.category == 'coin_package' && package.coinsDelta > 0) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: earnGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: earnGreen.withOpacity(0.18)),
              ),
              child: Text(
                "Get ${package.coinsDelta} PM Coins",
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: earnGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _purchasePackage(package);
              },
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: const BorderSide(color: primaryBlue, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _packagePriceLabel(package),
            ),
          ),
        ],
      ),
    );
  }

  Widget _packagePriceLabel(_WalletPackage package) {
    final currentPrice = package.price ?? package.value;
    final originalPrice = package.originalPrice;
    final hasOffer =
        package.category == 'coin_package' &&
        package.offerDiscountPercent > 0 &&
        originalPrice != null &&
        originalPrice.isNotEmpty &&
        originalPrice != currentPrice;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasOffer) ...[
            Text(
              originalPrice,
              style: const TextStyle(
                color: subTextGrey,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            currentPrice,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPackageState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: subTextGrey.withOpacity(0.5),
            size: 32,
          ),
          const SizedBox(height: 12),
          const Text(
            "Nothing Available Here",
            style: TextStyle(fontWeight: FontWeight.bold, color: textBlack),
          ),
          const SizedBox(height: 4),
          const Text(
            "Check back later for new offers.",
            style: TextStyle(
              fontSize: 12,
              color: subTextGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchasePackage(_WalletPackage package) async {
    if (package.category == 'coin_package') {
      await _startRazorpayPayment(package);
      return;
    }

    if (package.category == 'renewal_alert') {
      _showRenewalPurchaseSheet(package);
      return;
    }

    final result = await ApiService.purchaseWalletPackage(
      packageId: package.id,
    );
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
      _showInfoBottomSheet(
        'Request Failed',
        result['message']?.toString() ?? 'Could not process request.',
        isError: true,
      );
    }
  }

  void _showRenewalPurchaseSheet(_WalletPackage package) {
    final wallet = context.read<WalletProvider>();
    final costText = package.value;
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
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: borderGrey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(package.icon, color: primaryBlue, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              package.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textBlack,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              package.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: subTextGrey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Covers all your registered vehicles",
              style: TextStyle(
                color: primaryBlue.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (alreadyActive) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: earnGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: earnGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Active until $endDate",
                      style: const TextStyle(
                        color: earnGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
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
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: textBlack,
                    ),
                  ),
                  const Text(
                    "PM Coins",
                    style: TextStyle(
                      color: subTextGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your balance: ${wallet.pmCoinsBalance} coins",
                    style: TextStyle(
                      color: hasEnough ? earnGreen : Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: hasEnough
                    ? () async {
                        HapticFeedback.lightImpact();
                        Get.back();
                        await _executeRenewalPurchase(package);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasEnough
                      ? primaryBlue
                      : Colors.grey.shade300,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  hasEnough
                      ? (alreadyActive
                            ? "Extend Subscription"
                            : "Buy with PM Coins")
                      : "Insufficient Coins",
                  style: TextStyle(
                    color: hasEnough ? Colors.white : Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                    color: primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
    _showLoadingBottomSheet();

    final result = await ApiService.purchaseWalletPackage(
      packageId: package.id,
    );

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

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
      _showInfoBottomSheet(
        'Purchase Failed',
        result['message']?.toString() ?? 'Could not process purchase.',
        isError: true,
      );
    }
  }

  Future<void> _startRazorpayPayment(_WalletPackage package) async {
    _showLoadingBottomSheet();

    final orderResult = await ApiService.createRazorpayOrder(
      packageId: package.id,
    );

    if (Get.isBottomSheetOpen == true) {
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
      _showInfoBottomSheet(
        "API Error",
        orderResult['message']?.toString() ??
            'Could not initiate payment from backend.',
        isError: true,
      );
      return;
    }

    _pendingPackageId = package.id;
    _razorpayEventReceived = false;
    final options = {
      'key': razorpayKeyId,
      'order_id': razorpayOrderId,
      'amount': orderResult['amount'],
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
              razorpayPaymentId:
                  response['razorpay_payment_id']?.toString() ?? '',
              razorpayOrderId: response['razorpay_order_id']?.toString() ?? '',
              razorpaySignature:
                  response['razorpay_signature']?.toString() ?? '',
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
              await _returnToPreviousFlowAfterTopUp();
            } else {
              _showInfoBottomSheet(
                'Verification Failed',
                result['message']?.toString() ??
                    'Payment received but verification failed.',
                isError: true,
              );
            }
          },
          onFailure: (message) {
            _razorpayEventReceived = true;
            _pendingPackageId = null;
            _showInfoBottomSheet("Payment Failed", message, isError: true);
          },
          onDismiss: () {
            _razorpayEventReceived = true;
            _pendingPackageId = null;
          },
        );
      } catch (e) {
        _pendingPackageId = null;
        _showInfoBottomSheet(
          "Payment Error",
          "Could not open Razorpay on web. Error: $e",
          isError: true,
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
        _showInfoBottomSheet(
          "Plugin Error",
          "Razorpay is not installed properly. Did you completely stop and restart the app? Error: $e",
          isError: true,
        );
      }
    });
  }

  Widget _buildFigmaTransactionTile(dynamic txn, bool isCredit) {
    String descText = _transactionDescription(txn);
    final icon = _transactionIcon(descText, txn['type']?.toString() ?? "");
    final dynamicAvatarColor = _transactionColor(
      descText,
      txn['type']?.toString() ?? "",
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey, width: 1.2),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showTransactionDetails(txn, isCredit);
        },
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
                child: Icon(icon, color: dynamicAvatarColor, size: 20),
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
                      style: const TextStyle(
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
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currencyShortLabel(txn),
                    style: const TextStyle(
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
    final detailRows = _transactionDetailRows(txn, isCredit);

    Get.bottomSheet(
      SafeArea(
        child: SingleChildScrollView(
          child: Container(
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
                    const Expanded(
                      child: Text(
                        "Transaction Details",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textBlack,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
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
                          fontWeight: FontWeight.bold,
                          color: color,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currencyShortLabel(txn),
                        style: const TextStyle(
                          color: subTextGrey,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                for (int i = 0; i < detailRows.length; i++) ...[
                  if (i > 0) const Divider(color: borderGrey, height: 32),
                  _detailRow(detailRows[i].key, detailRows[i].value),
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
                      elevation: 0,
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
        ),
      ),
      isScrollControlled: true,
    );
  }

  List<MapEntry<String, String>> _transactionDetailRows(
    dynamic txn,
    bool isCredit,
  ) {
    final description = _transactionDescription(txn);
    final rows = <MapEntry<String, String>>[
      MapEntry("Description", description),
      MapEntry(
        isCredit ? "Date of Credit" : "Date of Debit",
        _formatTransactionTime(txn['created_at']),
      ),
      MapEntry("Wallet", _walletLabel(txn)),
      MapEntry("Transaction Type", isCredit ? "Earned" : "Spent"),
    ];

    final activity = _transactionActivity(txn, description);
    if (activity != null) rows.add(MapEntry("Activity", activity));

    final vehicle = _transactionVehicle(txn, description);
    if (vehicle != null) rows.add(MapEntry("Vehicle", vehicle));

    final reason = _transactionReason(txn, description);
    if (reason != null) rows.add(MapEntry("Reason", reason));

    final id = _stringValue(txn, 'id');
    if (id != null) rows.add(MapEntry("Transaction ID", id));

    final reference = _firstStringValue(txn, [
      'reference_id',
      'report_id',
      'notification_id',
      'booking_id',
      'coupon_id',
      'razorpay_order_id',
      'razorpay_payment_id',
    ]);
    if (reference != null) rows.add(MapEntry("Reference ID", reference));

    for (final entry in _extraTransactionDetails(txn)) {
      if (!rows.any(
        (row) => row.key == entry.key && row.value == entry.value,
      )) {
        rows.add(entry);
      }
    }

    return rows;
  }

  List<MapEntry<String, String>> _extraTransactionDetails(dynamic txn) {
    if (txn is! Map) return const [];
    const hidden = {
      'id',
      'type',
      'coins',
      'amount',
      'currency',
      'description',
      'activity',
      'vehicle_number',
      'vehicle',
      'vehicle_no',
      'reason',
      'selected_reason',
      'selected_reason_code',
      'reason_code',
      'issue',
      'created_at',
      'updated_at',
      'reference_id',
      'report_id',
      'notification_id',
      'booking_id',
      'coupon_id',
      'razorpay_order_id',
      'razorpay_payment_id',
    };
    final rows = <MapEntry<String, String>>[];
    txn.forEach((key, value) {
      final keyText = key.toString();
      if (hidden.contains(keyText) || value == null) return;
      final valueText = value.toString().trim();
      if (valueText.isEmpty) return;
      rows.add(MapEntry(_labelFromKey(keyText), valueText));
    });
    return rows;
  }

  String _transactionDescription(dynamic txn) {
    final description =
        _firstStringValue(txn, ['description', 'reason']) ??
        'Wallet transaction';
    final currency = _walletLabel(txn);
    final activity = _transactionActivity(txn, description);
    if (activity == null) return description;

    final vehicle = _transactionVehicle(txn, description);
    final reason = _transactionReason(txn, description);

    final parts = <String>[];
    if (activity != null &&
        !description.toLowerCase().contains(activity.toLowerCase())) {
      parts.add(activity);
    }
    if (vehicle != null &&
        !description.toLowerCase().contains(vehicle.toLowerCase())) {
      parts.add('Vehicle: $vehicle');
    }
    if (reason != null &&
        !description.toLowerCase().contains(reason.toLowerCase())) {
      parts.add('Reason: $reason');
    }
    if (!description.toLowerCase().contains(currency.toLowerCase()))
      parts.add('Wallet: $currency');

    if (parts.isEmpty) return description;
    return '$description | ${parts.join(' | ')}';
  }

  String _walletLabel(dynamic txn) {
    final currency = _stringValue(txn, 'currency')?.toLowerCase() ?? '';
    if (currency.contains('coinsback')) return 'Coinsback Wallet';
    if (currency.contains('pm')) return 'PM Coins Wallet';
    return 'PM Coins Wallet';
  }

  String _currencyShortLabel(dynamic txn) {
    final currency = _stringValue(txn, 'currency')?.toLowerCase() ?? '';
    if (currency.contains('coinsback')) return 'Coinsback';
    return 'PM Coins';
  }

  String? _transactionActivity(dynamic txn, String description) {
    final direct = _stringValue(txn, 'activity');
    if (direct != null) return direct;

    final lower = description.toLowerCase();
    if (lower.contains('emergency')) return 'Emergency Alerts';
    if (lower.contains('help')) return 'Helping Alerts';
    if (lower.contains('penalty') || lower.contains('deducted')) {
      return 'Penalty on Vehicle Reported';
    }
    if (lower.contains('report')) return 'Reporting Alerts';
    return null;
  }

  String? _transactionVehicle(dynamic txn, String description) {
    final direct = _firstStringValue(txn, [
      'vehicle_number',
      'vehicle',
      'vehicle_no',
    ]);
    if (direct != null) return direct.toUpperCase();
    final match = RegExp(
      r'\b[A-Z]{2}\s?\d{1,2}\s?[A-Z]{1,3}\s?\d{3,4}\b',
    ).firstMatch(description.toUpperCase());
    return match?.group(0)?.replaceAll(' ', '');
  }

  String? _transactionReason(dynamic txn, String description) {
    final direct = _firstStringValue(txn, [
      'selected_reason',
      'selected_reason_code',
      'reason_code',
      'reason',
      'issue',
    ]);
    if (direct != null) return _cleanReason(direct);

    if (description.contains('|')) {
      for (final part in description.split('|')) {
        final trimmed = part.trim();
        if (trimmed.toLowerCase().startsWith('reason:')) {
          return _cleanReason(trimmed.substring(trimmed.indexOf(':') + 1));
        }
      }
    }

    final actionMatch = RegExp(r'\(([^)]+)\)').firstMatch(description);
    if (actionMatch != null) return _cleanReason(actionMatch.group(1)!);

    if (description.contains(':')) {
      final reason = description.split(':').last.trim();
      if (reason.isNotEmpty && reason.length <= 80) return _cleanReason(reason);
    }
    return null;
  }

  String _cleanReason(String value) {
    return value
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[.]$'), '')
        .trim();
  }

  String? _firstStringValue(dynamic source, List<String> keys) {
    for (final key in keys) {
      final value = _stringValue(source, key);
      if (value != null) return value;
    }
    return null;
  }

  String? _stringValue(dynamic source, String key) {
    if (source is! Map || !source.containsKey(key)) return null;
    final value = source[key];
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _labelFromKey(String key) {
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
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
          const Text(
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

class _WalletPackage {
  final String id;
  final String name;
  final String value;
  final String description;
  final IconData icon;
  final String? price;
  final String category;
  final String? originalPrice;
  final int offerDiscountPercent;
  final String? offerTag;
  final int coinsDelta;

  const _WalletPackage(
    this.id,
    this.name,
    this.value,
    this.description,
    this.icon, [
    this.price,
    this.category = '',
    this.originalPrice,
    this.offerDiscountPercent = 0,
    this.offerTag,
    this.coinsDelta = 0,
  ]);
}

// Minimal Animated Skeleton Placeholder Helper
class _PulsingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _PulsingSkeleton({
    required this.width,
    required this.height,
    this.borderRadius = 16,
  });

  @override
  State<_PulsingSkeleton> createState() => _PulsingSkeletonState();
}

class _PulsingSkeletonState extends State<_PulsingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 0.9).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
