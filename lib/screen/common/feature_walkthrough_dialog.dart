import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FeatureWalkthroughDialog extends StatefulWidget {
  const FeatureWalkthroughDialog({super.key});

  @override
  State<FeatureWalkthroughDialog> createState() => _FeatureWalkthroughDialogState();
}

class _FeatureWalkthroughDialogState extends State<FeatureWalkthroughDialog> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _features = [
    {
      "icon": Icons.document_scanner_rounded,
      "title": "Scan Number Plates",
      "desc": "Quickly scan any vehicle's number plate to alert the owner via masked call.",
      "color": Colors.blueAccent,
    },
    {
      "icon": Icons.monetization_on_rounded,
      "title": "Earn Coinsback",
      "desc": "Get rewarded with coins for reporting wrongly parked vehicles or helping others.",
      "color": Colors.amber.shade600,
    },
    {
      "icon": Icons.sos_rounded,
      "title": "Emergency SOS",
      "desc": "Send instant alerts with your live location to your family and nearby hospitals.",
      "color": Colors.redAccent,
    },
    {
      "icon": Icons.garage_rounded,
      "title": "Manage Vehicles",
      "desc": "Add your own vehicles so the community can reach you safely without exposing your number.",
      "color": Colors.green.shade600,
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Welcome to\nParkingMudde! 🎉",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    height: 1.2,
                  ),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Slider area
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (idx) {
                  setState(() => _currentIndex = idx);
                },
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        key: ValueKey(index), // Re-triggers animation on swipe
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: feature["color"].withOpacity(0.15),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: feature["color"].withOpacity(0.3 * value),
                                    blurRadius: 20 * value,
                                    spreadRadius: 5 * value,
                                  ),
                                ],
                              ),
                              child: Icon(
                                feature["icon"],
                                size: 56,
                                color: feature["color"],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        feature["title"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0XFF184B8C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        feature["desc"],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey.shade600,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _features.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentIndex == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index ? const Color(0XFF184B8C) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 28),
            
            // Next/Done button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFfdd708),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (_currentIndex < _features.length - 1) {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    Get.back();
                  }
                },
                child: Text(
                  _currentIndex < _features.length - 1 ? "Next" : "Let's Go!",
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
