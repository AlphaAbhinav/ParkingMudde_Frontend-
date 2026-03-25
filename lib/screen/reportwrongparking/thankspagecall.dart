import 'dart:async';
import 'package:flutter/material.dart';



class ThankYouReportScreen extends StatefulWidget {
  final typecv;
  const ThankYouReportScreen({super.key, this.typecv});

  @override
  State<ThankYouReportScreen> createState() => _ThankYouReportScreenState();
}

class _ThankYouReportScreenState extends State<ThankYouReportScreen> {
  static const int maxSeconds = 60;
  int secondsLeft = maxSeconds;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    widget.typecv == "1" ? "" : startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCallEnabled = secondsLeft == 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// ✅ Success Icon
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),

              SizedBox(height: 24),

              /// 🙏 Thank You Text
              Text(
                widget.typecv == "1"
                    ? "Thanks for helping!"
                    : "Thanks for reporting!",
                style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8),

              Text(
                "Your help has been sent successfully.\nYou may contact the offender after the cooldown period.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey,fontSize: 14),
              ),

              SizedBox(height: 30),

              /// ⏳ Countdown Timer
              widget.typecv == "1"
                  ? SizedBox()
                  : Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Color(0XFF184b8c).withOpacity(0.1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Calling will be enabled in",
                           
                          ),
                          SizedBox(height: 6),
                          Text(
                            "$secondsLeft sec",
                            style: TextStyle(color: Color(0XFF184b8c),fontSize: 24),
                          ),
                        ],
                      ),
                    ),

              widget.typecv == "1" ? SizedBox() : SizedBox(height: 40),

              /// 📞 Call Button
              widget.typecv == "1"
                  ? SizedBox()
                  : SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isCallEnabled
                            ? () {
                                // 👉 Trigger masked IVR call
                              }
                            : null,
                        icon: const Icon(Icons.call, color: Colors.white),
                        label: Text(
                          "Call Vehicle Owner",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCallEnabled
                              ? Color(0XFF184b8c)
                              : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

              SizedBox(height: 16),

              /// ⏭ Skip Option
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  "Go Back",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
