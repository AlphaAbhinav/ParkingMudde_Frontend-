import 'package:flutter/material.dart';

import 'package:get/get.dart';

class VisitorModel {
  final String name;
  final String mobile;
  final String purpose;
  final String vehicleNo;
  final String dateTime;
  final String status; // Pending / Approved / Exited

  VisitorModel({
    required this.name,
    required this.mobile,
    required this.purpose,
    required this.vehicleNo,
    required this.dateTime,
    required this.status,
  });
}

class VisitorManagementScreen extends StatefulWidget {
  const VisitorManagementScreen({super.key});

  @override
  State<VisitorManagementScreen> createState() =>
      _VisitorManagementScreenState();
}

class _VisitorManagementScreenState extends State<VisitorManagementScreen> {
  final List<VisitorModel> visitors = [
    VisitorModel(
      name: "Rahul Sharma",
      mobile: "XXXXXX1234",
      purpose: "Delivery",
      vehicleNo: "DL 01 AB 1234",
      dateTime: "12 Jan, 10:30 AM",
      status: "Pending",
    ),
    VisitorModel(
      name: "Amit Verma",
      mobile: "XXXXXX9876",
      purpose: "Guest",
      vehicleNo: "UP 16 CD 5678",
      dateTime: "11 Jan, 6:15 PM",
      status: "Approved",
    ),
  ];

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
          "Visitor Management",
          style: TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddVisitorSheet(context);
        },
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: visitors.length,
        itemBuilder: (context, index) {
          return _visitorCard(context, visitors[index]);
        },
      ),
    );
  }

  Widget _visitorCard(BuildContext context, VisitorModel visitor) {
    Color statusColor = visitor.status == "Approved"
        ? Colors.green
        : visitor.status == "Exited"
        ? Colors.grey
        : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                visitor.name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  visitor.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 6),

          Text(
            visitor.mobile,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),

          SizedBox(height: 8),

          Row(
            children: [
              _infoChip("Purpose", visitor.purpose),
              SizedBox(width: 10),
              _infoChip("Vehicle", visitor.vehicleNo),
            ],
          ),

          SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                visitor.dateTime,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (visitor.status == "Pending")
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () {},
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String title, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text("$title: $value", style: TextStyle(fontSize: 12)),
    );
  }

  void showAddVisitorSheet(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.grey,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Add Visitor",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                ),
                InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Icon(Icons.close),
                ),
              ],
            ),

            SizedBox(height: 16),
            TextFormField(
              textCapitalization: TextCapitalization.sentences,

              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,

                labelText: "Visitor Name",
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

            SizedBox(height: 20),
             TextFormField(
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,

                labelText: "Mobile Number",
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

            SizedBox(height: 20),
            TextFormField(
              textCapitalization: TextCapitalization.sentences,

              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,

                labelText: "Purpose",
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

            SizedBox(height: 20),
            TextFormField(
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,

                labelText: "Vehicle Number",
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

            SizedBox(height: 20),
            Center(
              child: InkWell(
                onTap: () {},
                child: Container(
                  height: 45,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Color(0XFF184b8c),
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Center(
                    child: Text(
                      "Generate Entry Pass",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
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
