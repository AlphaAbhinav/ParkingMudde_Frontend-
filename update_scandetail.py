import codecs
import re

file_path = r'c:\Users\Asus\OneDrive\Desktop\parking mudde\ParkingMudde_Frontend-\lib\screen\reportwrongparking\scandetail.dart'
with codecs.open(file_path, 'r', 'utf-8') as f:
    content = f.read()

replacement = '''  Future<void> _finishSubmitReport({String? rOrderId, String? rPaymentId, String? rSignature}) async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    final storedUser = await ApiService.getStoredUser();
    final currentUserId = storedUser?["user_id"]?.toString();
    final targetVehicle = "";

    Map<String, dynamic> result;
    if (_isEmergencyFlow) {
      result = await ApiService.createEmergencyAlertActivity(
        userId: currentUserId!,
        vehicleNumber: targetVehicle,
        situation: situationController.text.trim(),
        image: images.first,
        location: "Not provided",
      );
    } else if (_isHelpFlow) {
      result = await ApiService.createHelpedVehicleActivity(
        userId: currentUserId!,
        vehicleNumber: targetVehicle,
        parkingError: _issueTitle,
        image: images.first,
        location: "Not provided",
      );
    } else {
      result = await ApiService.reportWrongParking(
        vehicleNumber: targetVehicle,
        lat: null, // Replace with actual location if needed
        lng: null,
        capturedAt: DateTime.now().toIso8601String(),
        images: images,
        selectedIssue: _issueTitle,
        selectedIssueCode: _issueCode,
        razorpayOrderId: rOrderId,
        razorpayPaymentId: rPaymentId,
        razorpaySignature: rSignature,
      );
    }

    setState(() => isLoading = false);
    
    if (result['success'] == true) {
      if (!mounted) return;
      
      final dynamic data = result['data'];
      double? aiScore;
      String? aiVerdict;
      String? aiReasons;

      if (data != null && data is Map) {
         if (data.containsKey('ai_score')) aiScore = (data['ai_score'] as num?)?.toDouble();
         if (data.containsKey('ai_verdict')) aiVerdict = data['ai_verdict']?.toString();
         if (data.containsKey('ai_reasons')) aiReasons = data['ai_reasons']?.toString();
      } else {
         if (result.containsKey('score')) aiScore = (result['score'] as num?)?.toDouble();
         if (result.containsKey('verdict')) aiVerdict = result['verdict']?.toString();
         if (result.containsKey('reasons')) aiReasons = result['reasons']?.toString();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ThankYouReportScreen(
            transactionId: "TXN-${DateTime.now().millisecondsSinceEpoch}",
            date: DateTime.now().toLocal().toString().split(' ')[0],
            time: "${TimeOfDay.now().hour}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}",
            reportId: "REP-${DateTime.now().millisecondsSinceEpoch}",
            coinsEarned: _isHelpFlow || _isEmergencyFlow ? 5 : null,
            aiScore: aiScore,
            aiVerdict: aiVerdict,
            aiReasons: aiReasons,
          ),
        ),
      );
    } else {
      showSnack(result['message'] ?? "Submission failed. Please try again.");
    }
  }'''

content = re.sub(r'  Future<void> _finishSubmitReport.*?showSnack\(result\[\'message\'\] \?\? "Submission failed\. Please try again\."\);\s*\}\s*\}', replacement, content, flags=re.DOTALL)

with codecs.open(file_path, 'w', 'utf-8') as f:
    f.write(content)

print("scandetail.dart updated")
