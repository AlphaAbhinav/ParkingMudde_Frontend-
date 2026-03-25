import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parkingmudde/screen/vehicle/addvehicle.dart';

// import 'package:parkingmudde/screen/widget/custom_textFormField.dart';


class VehicleDetailPage extends StatefulWidget {
  const VehicleDetailPage({super.key});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  List galleryItems = [
    "data:image/jpeg;base64,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",
  ];
   void showDeleteReasonSheet({
    required BuildContext context,
    required Function(String reason) onConfirm,
  }) {
    final TextEditingController otherController = TextEditingController();
    String? selectedReason;

    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  /// Title
                  Text(
                    "Reason for Deletion",
                    style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 12),

                  /// Reasons
                  _reasonTile("Vehicle sold", selectedReason, setState, (v) {
                    selectedReason = v;
                  }),
                  _reasonTile("Wrong vehicle added", selectedReason, setState, (
                    v,
                  ) {
                    selectedReason = v;
                  }),
                  _reasonTile("Duplicate entry", selectedReason, setState, (v) {
                    selectedReason = v;
                  }),
                  _reasonTile("Other", selectedReason, setState, (v) {
                    selectedReason = v;
                  }),

                  /// Other Input
                  if (selectedReason == "Other") ...[
                    SizedBox(height: 8),
                    
                      TextFormField(
                        controller: otherController,
                      textCapitalization: TextCapitalization.sentences,
maxLines: 2,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,

                        labelText: "Enter reason",
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

            
                  ],

                  SizedBox(height: 16),

                  /// Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            "Cancel",
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                          
                            Navigator.pop(context);
                           
                          },
                          child: Text(
                            "Delete",
                            style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
          "Vehicle Details",
          style: TextStyle(fontSize: 18, color: Color(0XFFfdd708)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 5,
          bottom: 5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Vehicle Images
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: galleryItems.length,
                separatorBuilder: (_, __) => SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      "assets/car.jpeg",
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 20),

            /// Vehicle Info Card
            _infoCard(
              context,
              title: "Vehicle Information",
              children: [
                _infoRow("Vehicle Type", "4 Wheeler"),
                _infoRow("Registration No", "UP32 AB 1234"),
                _infoRow("RC Status", "Verified", isVerified: true),
              ],
            ),

            SizedBox(height: 16),

            /// Owner Info
            _infoCard(
              context,
              title: "Owner Details",
              children: [
                _infoRow("Registered Mobile", "+91 9876543210"),
                _infoRow("OTP Status", "Verified", isVerified: true),
              ],
            ),

            SizedBox(height: 24),

            /// Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                       Get.to(AddVehicleScreen(edit: "1"));
                    },
                    icon: const Icon(Icons.edit),
                    label: Text("Edit", style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () {
                     showDeleteReasonSheet(
                        context: context,
                        onConfirm: (reason) {
                          debugPrint("DELETE REASON: $reason");
                         
                        },
                      );
                    },
                    icon:  Icon(Icons.delete,size: 20,color: Colors.white,),
                    label: Text(
                      "Delete",
                      style: TextStyle(color: Colors.white,fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isVerified = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isVerified ? Colors.green : Colors.black,
                ),
              ),
              if (isVerified)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
   Widget _reasonTile(
    String title,
    String? selected,
    StateSetter setState,
    Function(String value) onSelect,
  ) {
    return RadioListTile<String>(
      value: title,
      groupValue: selected,
      onChanged: (value) {
        setState(() {
          onSelect(value!);
        });
      },
      title: Text(title),
      contentPadding: EdgeInsets.zero,
    );
  }


}
