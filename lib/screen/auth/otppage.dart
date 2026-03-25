import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:sms_autofill/sms_autofill.dart';

class Otppage extends StatefulWidget {
final String mobile;
final String referralCode;

const Otppage({
super.key,
required this.mobile,
required this.referralCode,
});

@override
State<Otppage> createState() => _OtppageState();
}

class _OtppageState extends State<Otppage> {
String enteredOtp = "";
bool isLoading = false;

@override
Widget build(BuildContext context) {
return Scaffold(
body: SafeArea(
child: CustomScrollView(
slivers: [
SliverFillRemaining(
child: SingleChildScrollView(
child: Column(
children: [
const SizedBox(height: 150),


                /// APP LOGO
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    height: 100,
                  ),
                ),

                const SizedBox(height: 25),

                /// OTP TEXT
                Text(
                  "Please enter OTP sent to your mobile number\n${widget.mobile}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 50),

                /// OTP INPUT
                SizedBox(
                  width: MediaQuery.of(context).size.width * .70,
                  child: PinFieldAutoFill(
                    codeLength: 6,
                    autoFocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: BoxLooseDecoration(
                      textStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).primaryColor,
                      ),
                      gapSpace: 30,
                      strokeWidth: 2.0,
                      radius: const Radius.circular(8),
                      strokeColorBuilder:
                          const FixedColorBuilder(Color(0XFFfdd708)),
                      bgColorBuilder:
                          const FixedColorBuilder(Colors.white),
                    ),
                    onCodeChanged: (value) {
                      if (value != null) {
                        enteredOtp = value;
                      }
                    },
                  ),
                ),

                const SizedBox(height: 15),

                /// RESEND OTP
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: "Didn't you get code? ",
                        style: TextStyle(
                            fontSize: 16, color: Colors.black),
                      ),
                      TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final result = await ApiService.sendOtp(widget.mobile);

                            if (result["success"] == true) {
                              print("Resent OTP: ${result["otp"]}");
                              Get.snackbar("Success", "OTP resent");
                            }
                          },
                        text: 'Resend',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// VERIFY BUTTON
                InkWell(
                  onTap: () async {
                    if (enteredOtp.length != 6) {
                      Get.snackbar("Error", "Enter 6-digit OTP");
                      return;
                    }

                    setState(() => isLoading = true);

                    final result = await ApiService.verifyOtp(
                      widget.mobile,
                      enteredOtp,
                      widget.referralCode,
                    );

                    setState(() => isLoading = false);

                    if (result["success"] == true) {
                      final prefs = await SharedPreferences.getInstance();

                      await prefs.setString(
                        "user_id",
                        result["user_id"],
                      );

                      /// GO TO DASHBOARD
                      Get.offAll(() => Dash());
                    } else {
                      Get.snackbar(
                        "Error",
                        result["message"] ?? "Invalid OTP",
                      );
                    }
                  },
                  child: Container(
                    width: 250,
                    height: 45,
                    decoration: const BoxDecoration(
                      color: Color(0XFF184b8c),
                      borderRadius:
                          BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Center(
                      child: isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              "Verify",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
);


}
}
