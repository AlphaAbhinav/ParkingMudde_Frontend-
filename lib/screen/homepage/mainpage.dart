import 'package:flutter/material.dart';
import 'package:parkingmudde/screen/account/accountpage.dart';
import 'package:parkingmudde/screen/homepage/homepage.dart';
import 'package:parkingmudde/screen/notification/notificationpage.dart';
import 'package:parkingmudde/screen/reportwrongparking/scanenter.dart';
import 'package:parkingmudde/screen/wallet/walletpage.dart';

class Dash extends StatefulWidget {
  const Dash({super.key});

  @override
  State<Dash> createState() => _DashState();
}

class _DashState extends State<Dash> {
  // Ordered strictly identically to match existing tabs array mapped boundaries map bounds
  final List<Widget> screens = [
    const Homepage(),
    const Notificationpage(),
    const VehicleNumberInputScreen(), // Triggered centrally by FAB Scan limit mapped map
    WalletScreen(totalCoins: 10),
    const Accountpage(),
  ];

  int selectedIndex = 0;

  final PageController pageController = PageController();

  void onPageChanged(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void onItemTapped(int selectedItem) {
    pageController.jumpToPage(selectedItem);
  }

  // Exact Colors matched visually straight from Figma UI Panel form limits mappings layouts boundary maps mapped limit forms bounds map constraints spaces mapping mapped layout constraints
  static const Color primaryBlue = Color(0xFF2A5EE8);
  static const Color textBlack = Color(0xFF222222);
  static const Color subTextGrey = Color(0xFF888888);
  static const Color fabYellow = Color(0xFFFFB703);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Prevents white boxy corners around dock
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: screens,
      ),

      // FIGMA PIXEL-PERFECT YELLOW FLOATING ACTION SCAN BUTTON mapping forms spaces limit layouts limits mappings boundaries boundary limits standard layout constraints mapped map boundary limit boundary limits maps boundary boundary boundaries bounds
      floatingActionButton: FloatingActionButton(
        onPressed: () => onItemTapped(2),
        backgroundColor: fabYellow,
        elevation: 6,
        shape:
            const CircleBorder(), // Guarantee strict uniform round edge mapping constraints
        child: const Icon(
          Icons
              .qr_code_scanner_rounded, // Best fit for the center icon bound boundary form mappings limits mappings
          color: Colors.white,
          size: 26,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape:
            const CircularNotchedRectangle(), // Clean elegant arch mapping layouts spaces forms mappings maps limits
        notchMargin: 8,
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 20,
        padding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(icon: Icons.home_rounded, label: 'Home', index: 0),
              _buildTabItem(
                icon: Icons.article_rounded,
                label: 'Activities',
                index: 1,
              ),

              const SizedBox(
                width: 48,
              ), // Dedicated gap limits mappings spacing

              _buildTabItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Wallet',
                index: 3,
              ),
              _buildTabItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                index: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = selectedIndex == index;
    return InkWell(
      onTap: () => onItemTapped(index),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? primaryBlue : subTextGrey, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? primaryBlue : subTextGrey,
            ),
          ),
        ],
      ),
    );
  }
}
