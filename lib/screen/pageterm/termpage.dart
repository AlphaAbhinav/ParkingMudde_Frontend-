import 'package:flutter/material.dart';
import 'package:get/get.dart';



class Pageterm extends StatefulWidget {
  final String tittle;
  const Pageterm({super.key,required this.tittle});

  @override
  State<Pageterm> createState() => _PagetermState();
}

class _PagetermState extends State<Pageterm> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Color(0XFFfdd708), size: 40),
          onPressed: () {
            Get.back();
          },
        ),
        automaticallyImplyLeading: true,
        toolbarHeight: 60,
        elevation: 0.2,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text(
          widget.tittle,
          style: TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
        ),
      ),
     
    
    );
  }
}