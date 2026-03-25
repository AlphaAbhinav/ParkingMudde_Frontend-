import 'package:flutter/material.dart';

import 'package:get/get.dart';
// import 'package:parkingmudde/screen/homepage/mainpage.dart';
import 'package:parkingmudde/screen/reportwrongparking/scandetail.dart';




class VehicleNumberInputScreen extends StatefulWidget {
  const VehicleNumberInputScreen({super.key});

  @override
  State<VehicleNumberInputScreen> createState() =>
      _VehicleNumberInputScreenState();
}

class _VehicleNumberInputScreenState extends State<VehicleNumberInputScreen> {
  final TextEditingController vehicleController = TextEditingController();
  bool isValidVehicle = false;

  /// Indian Vehicle Number Regex
  final RegExp vehicleRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}$');

  void validateVehicle(String value) {
    final text = value.replaceAll(" ", "").toUpperCase();
    vehicleController.value = vehicleController.value.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );

    setState(() {
      isValidVehicle = vehicleRegex.hasMatch(text);
    });
  }

  @override
  void dispose() {
    vehicleController.dispose();
    super.dispose();
  }

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
          "Report Wrong Praking",
          style: TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
        ),
      ),
     
     
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 Title
            Text(
              "Scan Vehicle Number Plate",
              style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              "Scan the number plate or enter manually",
              style: TextStyle(color: Colors.grey),
            ),

            SizedBox(height: 30),

            /// 📸 Scan Card
            InkWell(
              onTap: () {
                // TODO: Open OCR Camera
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0XFF184b8c)),
                  color: Color(0XFF184b8c).withOpacity(0.05),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.document_scanner_rounded,
                      size: 50,
                      color: Color(0XFF184b8c),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Scan Number Plate",
                     
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Fast & accurate",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            /// 🔹 OR Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    "OR",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            SizedBox(height: 24),

            /// ✍️ Manual Input
            Text(
              "Enter Vehicle Number",
              style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

               TextFormField(
              textCapitalization: TextCapitalization.sentences,

              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,

                labelText: "MH12AB1234",
                labelStyle: TextStyle(color: Colors.grey, fontSize: 14),
                floatingLabelStyle: TextStyle(color: Colors.grey, fontSize: 14),
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
           
          
            
            if (vehicleController.text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  isValidVehicle
                      ? "Valid vehicle number ✔"
                      : "Invalid vehicle number",
                  style: TextStyle(color: isValidVehicle ? Colors.green : Colors.red),
                ),
              ),

            const Spacer(),
            Center(
              child: InkWell(
                onTap: () {
                   Get.to(ReportProofScreen());
                },
                child: Container(
                  width: 250,
                   height: 45,
                  decoration: BoxDecoration(
                    color: Color(0XFF184b8c),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Center(
                    child: Text(
                      "Continue",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),

             
              
              
            ),

            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
