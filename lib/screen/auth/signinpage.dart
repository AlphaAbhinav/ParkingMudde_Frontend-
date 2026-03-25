import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:parkingmudde/screen/auth/loginpage.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white10, toolbarHeight: 0),
      body: Form(
        // key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(left: 20, right: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 80),
              Center(
                child: Image.asset(
                  'assets/logo.png', // Replace with your logo asset path
                  height: 100,
                ),
              ),
              SizedBox(height: 20),

              SizedBox(height: 20),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,

                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,

                  labelText: "Enter First Name*",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  floatingLabelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              SizedBox(height: 20),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,

                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,

                  labelText: "Enter Last Name*",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  floatingLabelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              SizedBox(height: 20),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,

                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,

                  labelText: "Enter Email*",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  floatingLabelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              SizedBox(height: 20),
              TextFormField(
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,

                  labelText: "Enter Mobile Number*",
                  labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  floatingLabelStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Color(0XFFff6f61).withOpacity(0.5),
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),

              SizedBox(height: 40),

              Center(
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Color(0XFF184b8c),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Center(
                      child: Text(
                        "Sign Up",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              // ),
              SizedBox(height: 40),
              Row(
                children: <Widget>[
                  const Expanded(child: Divider()),

                  const Expanded(child: Divider()),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already Have an Account?  ".tr,
                    style: TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.offAll(
                        transition: Transition.rightToLeft, // Slide from right
                        duration: Duration(
                          milliseconds: 300,
                        ), // Slow transition
                        curve: Curves.easeOutCubic, // Smooth effect
                        Loginpage(),
                      );
                    },
                    child: Text(
                      "Sign In".tr,
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Color(0XFFfdd708),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
