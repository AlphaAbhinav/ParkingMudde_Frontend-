import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  final int totalCoins;

  const WalletScreen({super.key, required this.totalCoins});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();

    /// Fetch wallet when screen loads identically to original implementation
    Future.microtask(() {
      context.read<WalletProvider>().fetchWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    /// Listen to wallet provider smoothly
    final walletProvider = context.watch<WalletProvider>();

    final walletCoins = walletProvider.balance;
    final earnedCoins = walletProvider.earned;
    final spentCoins = walletProvider.spent;
    final transactions = walletProvider.transactions;

    return Scaffold(
      backgroundColor: const Color(
        0xFFF6F8FA,
      ), // Premium off-white super-app base
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0XFF184B8C),
            size: 22,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Wallet",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// THE WALLET MASTER CARD SECTION
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: 12,
              ),
              child: _buildPremiumWalletCard(
                walletCoins,
                earnedCoins,
                spentCoins,
              ),
            ),
          ),

          /// TRANSACTIONS HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Transactions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                  Icon(
                    Icons.history_rounded,
                    color: Colors.blueGrey.shade300,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),

          /// TRANSACTIONS LIST or EMPTY STATE
          if (transactions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyTransactionsState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final txn = transactions[index];
                  final isCredit = txn['type'] == "earn";

                  return _buildTransactionTile(txn, isCredit);
                }, childCount: transactions.length),
              ),
            ),
        ],
      ),
    );
  }

  /// THE PRISTINE FLOATING FINANCE CARD
  Widget _buildPremiumWalletCard(
    dynamic walletCoins,
    dynamic earnedCoins,
    dynamic spentCoins,
  ) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0XFF12325E), Color(0XFF184b8c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0XFF184b8c).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          /// Decor: Abstract Top Right overlapping ring
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          /// Decor: Abstract Bottom Left overlay shape
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              height: 180,
              width: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          /// Real Core Wallet Content Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Badge / Subheading ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "TOTAL COINS AVAILABLE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // --- Primary Massive Readout ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      "$walletCoins",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        height: 1.0, // Strict crisp height locking
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "🪙",
                      style: TextStyle(fontSize: 32),
                    ), // Keeping pure identical value outputs visually bound distinctively!
                  ],
                ),

                const Spacer(),

                // --- Bottom Frost-Glass Mini Stats Container Row ---
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _miniStatsBox(
                          "Earned Lifetime",
                          "+$earnedCoins",
                          Colors.greenAccent,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 35,
                        color: Colors.white.withOpacity(0.3),
                      ), // Sleek separator
                      Expanded(
                        child: _miniStatsBox(
                          "Coins Redeemed",
                          "-$spentCoins",
                          Colors.redAccent.shade200,
                          crossAlign: CrossAxisAlignment.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Elegant isolated sub-state components internally attached on the main wallet widget
  Widget _miniStatsBox(
    String title,
    String value,
    Color badgeColor, {
    CrossAxisAlignment crossAlign = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: crossAlign == CrossAxisAlignment.end
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: badgeColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Text("🪙", style: TextStyle(fontSize: 11)),
          ],
        ),
      ],
    );
  }

  /// Individual clean high fidelity rounded transaction log rows!
  Widget _buildTransactionTile(dynamic txn, bool isCredit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
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
        border: Border.all(
          color: Colors.grey.shade100,
          width: 2,
        ), // Gives cards strong rigid shape without deep harshness
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment
            .center, // Kept completely centered to hold line visuals natively perfect
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green.shade50 : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isCredit
                  ? Colors.green.shade600
                  : Colors.redAccent.shade700,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn['description'],
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow
                      .ellipsis, // Failsafe text breaking prevention
                ),
                const SizedBox(height: 4),
                Text(
                  txn['created_at']
                      .toString(), // Pure identically authored property mapping!
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${isCredit ? '+' : '-'}${txn['coins']} 🪙", // Safe Emoji bind wrapper identical string build!
                style: TextStyle(
                  color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isCredit ? "INCOME" : "EXPENSE",
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Visually graceful zero-record holder
  Widget _buildEmptyTransactionsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 40,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Activities Found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Transactions regarding coin earning points, redemptions and usage will permanently log right here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey.shade400,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
