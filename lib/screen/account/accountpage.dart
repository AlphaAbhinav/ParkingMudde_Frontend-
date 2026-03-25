import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/account/editpage.dart';

import 'package:parkingmudde/screen/homepage/mainpage.dart';


class Accountpage extends StatefulWidget {
  const Accountpage({super.key});

  @override
  State<Accountpage> createState() => _AccountpageState();
}

class _AccountpageState extends State<Accountpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: Color(0XFFfdd708), size: 40),
          onPressed: () {
            Get.offAll(const Dash());
          },
        ),
        automaticallyImplyLeading: true,
        toolbarHeight: 60,
        elevation: 0.2,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text(
          "Account",
          style: TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
        ),
      ),


     
      body: SingleChildScrollView(
        child: Column(
          children: [
            InkWell(
              onTap: () {
                Get.to(EditProfilePage());
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 👤 Profile Image
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage("https://i.pravatar.cc/190"),
                    ),
              
                    const SizedBox(width: 16),
              
                    // 📄 Name & Phone
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Vinit Kumar",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "+91 98765 43210",
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
              
                    // ➡️ Optional Arrow
                    Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
           

            _accountOption(
              icon: Icons.delete_outline,
              title: "Delete Account",
              textColor: Colors.red,
              onTap: () {
                // Delete account flow
              },
            ),

            _accountOption(
              icon: Icons.logout,
              title: "Logout",
              onTap: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountOption({
    required IconData icon,
    required String title,
    Color textColor = Colors.black,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // cancel
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);

              // TODO: Clear user session / token
              // Navigate to login screen
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
