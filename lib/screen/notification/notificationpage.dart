import 'package:flutter/material.dart';
import 'package:get/get.dart';




class Notificationpage extends StatefulWidget {
  const Notificationpage({super.key});

  @override
  State<Notificationpage> createState() => _NotificationpageState();
}

class _NotificationpageState extends State<Notificationpage> {
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
          "Notifications",
          style: TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(left: 15, right: 15),
          child: Column(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(0),
                itemCount: 10,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, i) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(120),
                            ),
                            child: Image(
                              
                              image: AssetImage('assets/logo.png'),
                             
                              height: 75,
                              width: 75,
                            ),
                          ),
                          Flexible(
                            child: Container(
                              margin: EdgeInsets.only(left: 15),
                              child: Text(
                                "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    Divider()
                    ],
                  );

                },
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
