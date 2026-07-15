import 'package:flutter/material.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
const Color primaryBlue = Color(0xFF1E3A8A);


class MyChallansScreen extends StatefulWidget {
  const MyChallansScreen({Key? key}) : super(key: key);

  @override
  _MyChallansScreenState createState() => _MyChallansScreenState();
}

class _MyChallansScreenState extends State<MyChallansScreen> {
  bool _isLoading = true;
  List<dynamic> _challans = [];

  @override
  void initState() {
    super.initState();
    _fetchChallans();
  }

  Future<void> _fetchChallans() async {
    final res = await ApiService.fetchMyChallans();
    if (mounted) {
      setState(() {
        _challans = res['challans'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Towed & Challans', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF6F8FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _challans.isEmpty
              ? const Center(
                  child: Text(
                    "No challans or towed vehicles found",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _challans.length,
                  itemBuilder: (context, index) {
                    final c = _challans[index];
                    final isTowed = c['is_towed'] ?? false;
                    final reason = c['reason'] ?? 'Unknown Reason';
                    final fineAmount = c['fine_amount']?.toString() ?? '0';
                    final towedLocation = c['towed_location'] ?? 'Unknown Location';
                    final actualVehicleNumber = c['actual_vehicle_number'] ?? 'Unknown Vehicle';
                    
                    final createdAt = c['created_at'] != null 
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(c['created_at']).toLocal()) 
                        : '';
                    final capturedAt = c['captured_at'] != null 
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(c['captured_at']).toLocal()) 
                        : '';

                    final aiScore = c['ai_score'] ?? 0;
                    final aiVerdict = c['ai_verdict'] ?? 'UNKNOWN';
                    final aiReasons = c['ai_reasons'] ?? 'None';
                    final verifiedIssues = c['verified_issues'] ?? 'None';
                    final location = c['location'] ?? 'Unknown Location';
                    final lat = c['lat'];
                    final lng = c['lng'];
                    
                    final photoUrls = List<String>.from(c['photo_urls'] ?? []);
                    
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isTowed ? Colors.red.shade100 : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isTowed ? "TOWED" : "CHALLAN",
                                    style: TextStyle(
                                      color: isTowed ? Colors.red.shade700 : Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  "₹$fineAmount",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.red,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              actualVehicleNumber,
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.access_time_rounded, 'Reported: $capturedAt'),
                            _buildInfoRow(Icons.gavel_rounded, 'Processed: $createdAt'),
                            const Divider(height: 24),
                            
                            const Text('Violation Details', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
                            const SizedBox(height: 8),
                            Text("Location: $location", style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("Reason: $reason", style: const TextStyle(fontSize: 14)),
                            const SizedBox(height: 4),
                            Text("Officer Remarks: $verifiedIssues", style: const TextStyle(fontSize: 14)),
                            
                            if (isTowed) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on, color: Colors.red.shade700, size: 18),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "Towed to: $towedLocation",
                                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const Divider(height: 24),
                            const Text('AI Analysis', style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue)),
                            const SizedBox(height: 8),
                            _buildInfoRow(Icons.analytics_outlined, 'Verdict: $aiVerdict (Confidence: $aiScore%)'),
                            const SizedBox(height: 4),
                            Text("Detected Offenses: $aiReasons", style: const TextStyle(fontSize: 13, color: Colors.grey)),

                            if (lat != null && lng != null) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final url = Uri.parse('https://maps.google.com/?q=$lat,$lng');
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url);
                                    }
                                  },
                                  icon: const Icon(Icons.map, size: 18),
                                  label: const Text('View Violation on Map'),
                                ),
                              ),
                            ],

                            if (photoUrls.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text('Evidence Photos', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photoUrls.length,
                                  itemBuilder: (ctx, i) {
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: NetworkImage(photoUrls[i]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )
                            ],

                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  final url = Uri.parse('https://echallan.parivahan.gov.in/index/accused-challan');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.payment_rounded, size: 20),
                                label: const Text('Pay Challan Online'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade800, fontSize: 13))),
        ],
      ),
    );
  }
}
