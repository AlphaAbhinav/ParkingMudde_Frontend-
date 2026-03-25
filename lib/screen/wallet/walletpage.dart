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

    /// Fetch wallet when screen loads
    Future.microtask(() {
      context.read<WalletProvider>().fetchWallet();
    });
  }

  @override
  Widget build(BuildContext context) {

    /// Listen to wallet provider
    final walletProvider = context.watch<WalletProvider>();

    final walletCoins = walletProvider.balance;
    final earnedCoins = walletProvider.earned;
    final spentCoins = walletProvider.spent;
    final transactions = walletProvider.transactions;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0XFFfdd708), size: 40),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        automaticallyImplyLeading: true,
        toolbarHeight: 60,
        elevation: 0.2,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "My Wallet",
          style: TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
        ),
      ),

      body: Column(
        children: [

          /// WALLET CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0XFF184b8c),
                  const Color(0XFF184b8c).withOpacity(.8)
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const Text(
                  "Available Coins",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 5),

                /// WALLET BALANCE FROM PROVIDER
                Text(
                  "$walletCoins 🪙",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _summaryTile(
                      context,
                      title: "Earned",
                      value: "+$earnedCoins",
                      color: Colors.green,
                    ),
                    _summaryTile(
                      context,
                      title: "Spent",
                      value: "-$spentCoins",
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// TRANSACTION LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: transactions.length,
              itemBuilder: (context, index) {

                final txn = transactions[index];

                final isCredit = txn['type'] == "earn";

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// ICON
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCredit
                              ? Colors.green.withOpacity(.1)
                              : Colors.red.withOpacity(.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: isCredit
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),

                      const SizedBox(width: 12),

                      /// DETAILS
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              txn['description'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              txn['created_at'].toString(),
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14),
                            ),

                          ],
                        ),
                      ),

                      /// COINS
                      Text(
                        "${isCredit ? '+' : '-'}${txn['coins']} 🪙",
                        style: TextStyle(
                            color: isCredit
                                ? Colors.green
                                : Colors.red),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// SUMMARY TILE
  Widget _summaryTile(
      BuildContext context, {
        required String title,
        required String value,
        required Color color,
      }) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          title,
          style: const TextStyle(color: Colors.white70),
        ),

        const SizedBox(height: 4),

        Text(
          "$value 🪙",
          style: TextStyle(color: color, fontSize: 20),
        ),

      ],
    );
  }
}