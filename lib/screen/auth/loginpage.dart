import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/api_service.dart';
import 'package:parkingmudde/screen/auth/otppage.dart';
import 'package:parkingmudde/screen/auth/signinpage.dart';
import 'package:parkingmudde/screen/pageterm/termpage.dart';

class Loginpage extends StatefulWidget {
const Loginpage({super.key});

@override
State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {

final TextEditingController mobileController = TextEditingController();
final TextEditingController referralController = TextEditingController();

bool isLoading = false;

@override
void dispose() {
mobileController.dispose();
referralController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {


return Scaffold(
  backgroundColor: Colors.white,

  appBar: AppBar(
    backgroundColor: Colors.white10,
    toolbarHeight: 0,
  ),

  body: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: SingleChildScrollView(
      child: Column(
        children: [

          const SizedBox(height: 150),

          Image.asset(
            'assets/logo.png',
            height: 100,
          ),

          const SizedBox(height: 10),

          const Text(
            "Login with mobile number",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          /// MOBILE NUMBER FIELD
          TextFormField(
            controller: mobileController,
            keyboardType: TextInputType.number,
            maxLength: 10,
            decoration: InputDecoration(
              counterText: "",
              labelText: "Enter Your Mobile Number",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 15),

          /// REFERRAL CODE FIELD (OPTIONAL)
          TextFormField(
            controller: referralController,
            decoration: InputDecoration(
              labelText: "Referral Code (Optional)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 40),

          /// LOGIN BUTTON
          InkWell(
            onTap: () async {

              final mobile = mobileController.text.trim();
              final referralCode = referralController.text.trim();

              if (mobile.length != 10) {
                Get.snackbar("Error", "Enter valid 10-digit mobile number");
                return;
              }

              setState(() => isLoading = true);

              final result = await ApiService.sendOtp(mobile);

              setState(() => isLoading = false);

              if (result["success"] == true) {

                // For testing only (OTP visible in console)
                print("Generated OTP: ${result["otp"]}");

                /// Navigate to OTP page
                Get.to(
                  () => Otppage(
                    mobile: mobile,
                    referralCode: referralCode,
                  ),
                  transition: Transition.rightToLeft,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );

              } else {

                Get.snackbar(
                  "Error",
                  result["message"] ?? "Failed to send OTP",
                );

              }

            },

            child: Container(
              height: 45,
              width: 250,
              decoration: const BoxDecoration(
                color: Color(0XFF184b8c),
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),

              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Log In",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Text(
                "Don’t have an account ?",
                style: TextStyle(fontSize: 14),
              ),

              GestureDetector(
                child: const Text(
                  " Sign Up",
                  style: TextStyle(
                    color: Color(0XFFfdd708),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                onTap: () {
                  Get.to(
                    () => SignUpScreen(),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 105),

          /// TERMS TEXT
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: 'By continuing, you agree to Parking Mudde ',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),

                children: [

                  TextSpan(
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Pageterm(
                                tittle: 'Terms & Conditions',
                              ),
                            ),
                          ),

                    text: 'Terms & Conditions',
                    style: const TextStyle(fontSize: 11),
                  ),

                  const TextSpan(
                    text: ' and ',
                    style: TextStyle(fontSize: 11),
                  ),

                  TextSpan(
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const Pageterm(
                                      tittle: 'Privacy Policy'),
                            ),
                          ),

                    text: 'Privacy Policy',

                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

        ],
      ),
    ),
  ),
);

}
}
