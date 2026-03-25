import 'package:flutter/material.dart';



class AddVehicleBottomSheet extends StatelessWidget {
  const AddVehicleBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            SizedBox(height: 20),

            Text("Add Your Vehicle", ),

            SizedBox(height: 8),

            Text(
              "You can add your vehicle details now or do it later.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Add Vehicle Now",
                        style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Later",
                        style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold),
                      ),
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
}
