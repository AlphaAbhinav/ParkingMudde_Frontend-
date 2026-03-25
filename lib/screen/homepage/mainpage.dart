import 'package:flutter/material.dart';

import 'package:parkingmudde/screen/account/accountpage.dart';
import 'package:parkingmudde/screen/helpingvehicle.dart/vehiclescan.dart';
import 'package:parkingmudde/screen/homepage/homepage.dart';
import 'package:parkingmudde/screen/reportwrongparking/scanenter.dart';
import 'package:parkingmudde/screen/wallet/walletpage.dart';


class Dash extends StatefulWidget {
  const Dash({super.key});

  @override
  State<Dash> createState() => _DashState();
}

class _DashState extends State<Dash> {
  final List<Widget> screens = [
    const Homepage(),
    VehicleNumberHelpScreen(),
    VehicleNumberInputScreen(),
    WalletScreen(totalCoins: 10),
    Accountpage(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Color(0XFF184b8c),
        unselectedItemColor: Colors.black,
        selectedLabelStyle: const TextStyle(color: Color(0XFF184b8c)),
        unselectedLabelStyle: const TextStyle(color: Color(0XFF184b8c)),
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
              color: selectedIndex == 0 ? Color(0XFF184b8c) : Colors.black,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.category_outlined,
              color: selectedIndex == 1 ? Color(0XFF184b8c) : Colors.black,
            ),
            label: 'Help',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.add_to_drive,
              color: selectedIndex == 2 ? Color(0XFF184b8c) : Colors.black,
            ),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.wallet,
              size: 27,
              color: selectedIndex == 3 ? Color(0XFF184b8c) : Colors.black,
            ),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_circle_outlined,
              size: 27,
              color: selectedIndex == 4 ? Color(0XFF184b8c) : Colors.black,
            ),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
