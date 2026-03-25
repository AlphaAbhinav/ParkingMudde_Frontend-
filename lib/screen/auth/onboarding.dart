import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/auth/loginpage.dart';


class ParkingOnboarding extends StatefulWidget {
  const ParkingOnboarding({super.key});

  @override
  State<ParkingOnboarding> createState() => _ParkingOnboardingState();
}

class _ParkingOnboardingState extends State<ParkingOnboarding> {
  final PageController _controller = PageController();
  int currentIndex = 0;

  final List<Map<String, String>> pages = [
    {
      "title": "Find Parking Easily",
      "desc": "Search nearby parking spots in seconds",
      "image": "assets/logo.png",
    },
    {
      "title": "Book & Pay",
      "desc": "Reserve parking and pay securely online",
      "image": "assets/logo.png",
    },
    {
      "title": "Park Hassle-Free",
      "desc": "Navigate, park and go stress-free",
      "image": "assets/logo.png",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) {
                setState(() => currentIndex = index);
              },
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(pages[index]['image']!, height: 280),
                      const SizedBox(height: 30),
                      Text(
                        pages[index]['title']!,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        pages[index]['desc']!,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pages.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: currentIndex == index ? 20 : 8,
                decoration: BoxDecoration(
                  color: currentIndex == index
                      ? Color(0XFFfdd708)
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          SizedBox(height: 30),

          // Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Get.to(Loginpage());
                    // Navigate to Login/Home
                  },
                  child: const Text("Skip"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (currentIndex == pages.length - 1) {
                      Get.to(Loginpage());
                      // Navigate to Login/Home
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                  child: Text(
                    currentIndex == pages.length - 1 ? "Get Started" : "Next",
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }
}
