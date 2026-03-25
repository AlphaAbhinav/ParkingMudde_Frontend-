import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'package:parkingmudde/screen/auth/onboarding.dart';


class Splashpage extends StatefulWidget {
  const Splashpage({super.key});

  @override
  State<Splashpage> createState() => _SplashpageState();
}

class _SplashpageState extends State<Splashpage> {

  @override
  void initState() {
   Future.delayed(const Duration(seconds: 2), () {
    Get.offAll(ParkingOnboarding());

   });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
 
   

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
         
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage( "assets/logo.png"),
                  fit: BoxFit.contain)),
        ),
      ),

     
    );
  
  }
}