import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // --- UI/UX Design Tokens ---
  static const Color brandBlueLight = Color(0xFFEFF6FF); 
  static const Color textDark = Color(0xFF1E293B); 
  static const Color textGrey = Color(0xFF64748B); 
  static const Color bgSurface = Color(0xFFF8FAFC); 
  static const Color surfaceGrey = Color(0xFFF1F5F9); 
  static const Color indBlue = Color(0xFF1D4ED8); 
  
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
      backgroundColor: bgSurface,
      appBar: AppBar(
        title: const Text('Challan Updates', style: TextStyle(color: textDark, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: textDark),
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.5),
        ),
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _challans.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _challans.length,
                  itemBuilder: (context, index) {
                    final c = _challans[index];
                    final isTowed = c['is_towed'] ?? false;
                    final reason = c['reason'] ?? 'Unknown Reason';
                    final fineAmount = c['fine_amount']?.toString() ?? '0';
                    final towedLocation = c['towed_location'] ?? 'Location not added';
                    final actualVehicleNumber = c['actual_vehicle_number'] ?? 'Unknown Vehicle';
                    
                    final createdAt = c['created_at'] != null 
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(c['created_at']).toLocal()) 
                        : '';
                    final capturedAt = c['captured_at'] != null 
                        ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(c['captured_at']).toLocal()) 
                        : '';

                    final aiScoreText = c['ai_score']?.toString() ?? '0';
                    final double aiScore = double.tryParse(aiScoreText) ?? 0.0;
                    
                    final aiVerdict = _formatAiVerdict(c['ai_verdict']?.toString() ?? 'UNKNOWN', aiScore);

                    final aiReasons = _formatAiReasons(c['ai_reasons'], aiScore);

                    final verifiedIssues = c['verified_issues'] ?? 'None';
                    final location = c['location'] ?? 'Unknown Location';
                    final lat = c['lat'];
                    final lng = c['lng'];
                    
                    final photoUrls = List<String>.from(c['photo_urls'] ?? []);
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: Colors.grey.shade200, width: 1.5)
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. HEADER (Status & Price)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatusBadge(isTowed),
                                Text(
                                  "Rs$fineAmount",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    color: Colors.red,
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // 2. LICENSE PLATE & TIME INFO
                            _buildMiniLicensePlateView(actualVehicleNumber),
                            const SizedBox(height: 16),
                            _buildInfoRow(Icons.access_time_rounded, 'Reported', capturedAt),
                            _buildInfoRow(Icons.gavel_rounded, 'Processed', createdAt),
                            const SizedBox(height: 16),
                            
                            // 3. ORGANIZED VIOLATION DATA BLOCK
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surfaceGrey,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('REPORT DETAILS', style: TextStyle(fontWeight: FontWeight.w800, color: textGrey, fontSize: 11, letterSpacing: 0.5)),
                                  const SizedBox(height: 12),
                                  _buildDataPair("Location", location),
                                  const SizedBox(height: 8),
                                  _buildDataPair("Reason", reason),
                                  const SizedBox(height: 8),
                                  _buildDataPair("Authority Remarks", verifiedIssues),
                                  if (isTowed) ...[
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.location_on_rounded, color: Colors.red.shade700, size: 16),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: _buildDataPair("Authority Tow Location", towedLocation, isRed: true),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),

                            // 4. AI SCORE CONFIDENCE (HIGHER = MORE GUILTY = RED)
                            const Text('Evidence Confidence', style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 14)),
                            const SizedBox(height: 12),
                            _buildAIConfidenceWidget(aiScore, aiVerdict, aiReasons),
                            
                            const SizedBox(height: 20),

                            // 5. EVIDENCE PHOTOS
                            if (photoUrls.isNotEmpty) ...[
                              const Text('Evidence Photos', style: TextStyle(fontWeight: FontWeight.w700, color: textDark, fontSize: 14)),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 90,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: photoUrls.length,
                                  itemBuilder: (ctx, i) {
                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        _showFullImage(photoUrls[i]);
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 12),
                                        width: 120,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            photoUrls[i],
                                            fit: BoxFit.cover,
                                            errorBuilder: (ctx, _, __) => Icon(Icons.broken_image_rounded, color: Colors.grey.shade400),
                                            loadingBuilder: (ctx, child, progress) {
                                              if (progress == null) return child;
                                              return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue)));
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // 6. ACTION BUTTONS CLUSTER
                            if (lat != null && lng != null) ...[
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    HapticFeedback.lightImpact();
                                    final url = Uri.parse('https://maps.google.com/?q=$lat,$lng');
                                    if (await canLaunchUrl(url)) await launchUrl(url);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.map_rounded, size: 18, color: textDark),
                                  label: const Text('View Reported Location', style: TextStyle(color: textDark, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  HapticFeedback.lightImpact();
                                  final url = Uri.parse('https://echallan.parivahan.gov.in/index/accused-challan');
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                  }
                                },
                                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                                label: const Text('Check/Pay Official Challan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
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

  String _formatAiVerdict(String verdict, double aiScore) {
    if (aiScore >= 45) return "Evidence accepted";
    final normalized = verdict.toUpperCase();
    if (normalized == "CORRECT_PARKED" || normalized == "WRONG_REPORT") {
      return "Not enough evidence";
    }
    if (normalized == "UNDER_REVIEW" || normalized == "UNKNOWN") {
      return "Evidence being checked";
    }
    return _humanizeCode(normalized);
  }

  String _formatAiReasons(dynamic rawReasons, double aiScore) {
    final items = _extractReasonCodes(rawReasons)
        .where((code) => code.toUpperCase() != "NEEDS_REVIEW")
        .map(_humanizeCode)
        .where((label) => label.isNotEmpty)
        .toList();

    if (items.isEmpty) {
      return aiScore >= 45
          ? "Evidence meets report threshold"
          : "Evidence did not meet report threshold";
    }
    return items.join(', ');
  }

  List<String> _extractReasonCodes(dynamic rawReasons) {
    if (rawReasons == null) return const [];
    if (rawReasons is List) {
      return rawReasons.map((item) => item.toString()).toList();
    }

    final value = rawReasons.toString().trim();
    if (value.isEmpty) return const [];

    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList();
      }
    } catch (_) {}

    return value
        .replaceAll(RegExp(r'[\[\]"]'), '')
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _humanizeCode(String code) {
    final normalized = code.trim().toUpperCase();
    const labels = {
      "EVIDENCE_MATCH": "Evidence matched report",
      "LOW_CONFIDENCE": "Low evidence confidence",
      "SUSPICIOUS": "Needs authority check",
      "WRONG_PARKING": "Wrong parking evidence",
      "CORRECT_PARKED": "No clear violation",
    };
    final mapped = labels[normalized];
    if (mapped != null) return mapped;
    return normalized
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  /// Helper to map the AI Confidence dynamically 
  /// Evidence confidence shown without implying ParkingMudde made the final authority decision.
  Widget _buildAIConfidenceWidget(double aiScore, String verdict, String reasons) {
    Color trackColor;
    if (aiScore >= 80) trackColor = Colors.red.shade600;
    else if (aiScore >= 50) trackColor = Colors.orange.shade500;
    else trackColor = Colors.grey.shade600; // Unsure or low conviction.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Assessment: $verdict',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textDark),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              "${aiScore.toInt()}% confidence",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: trackColor),
            )
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(color: surfaceGrey, borderRadius: BorderRadius.circular(10)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * (aiScore.clamp(0, 100) / 100),
                    decoration: BoxDecoration(color: trackColor, borderRadius: BorderRadius.circular(10)),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text("Signals: $reasons", style: const TextStyle(fontSize: 12, color: textGrey)),
      ],
    );
  }

  /// Visually split data info so labels fade and the actual value shines
  Widget _buildDataPair(String label, String value, {bool isRed = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: textGrey, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: isRed ? Colors.red.shade700 : textDark, fontSize: 14, fontWeight: isRed ? FontWeight.w700 : FontWeight.w600)),
      ],
    );
  }

  /// The beautiful, uniform Indian License plate visualization used throughout your application.
  Widget _buildMiniLicensePlateView(String? regNumber) {
    final formattedReg = _formatLicensePlate(regNumber);

    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            decoration: const BoxDecoration(
              color: indBlue,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
            ),
            alignment: Alignment.center,
            child: const Text("IND", style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                formattedReg,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700, 
                  fontSize: 15, 
                  color: textDark,
                  letterSpacing: 1.0, 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLicensePlate(String? regNumber) {
    if (regNumber == null || regNumber.isEmpty) return 'NO-REG-NUM';
    String clean = regNumber.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    RegExp exp = RegExp(r'^([A-Z]{2})(\d{1,2})([A-Z]{1,3})(\d{4})$');
    if (exp.hasMatch(clean)) {
      final match = exp.firstMatch(clean)!;
      return "${match.group(1)} ${match.group(2)} ${match.group(3)} ${match.group(4)}";
    }
    return clean;
  }

  /// Modern, Premium "Celebrate" empty state representation.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.green.withOpacity(0.1), width: 10),
              ),
              child: const Icon(Icons.verified_user_rounded, size: 64, color: Colors.green),
            ),
            const SizedBox(height: 24),
            const Text(
              "Clean Record!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textDark, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              "No active challan or tow notices were found for vehicles registered to your account.",
              textAlign: TextAlign.center,
              style: TextStyle(color: textGrey, fontSize: 14.5, height: 1.4, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  /// Sophisticated Loading skeletons for visual smoothness.
  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(2, (index) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _PulsingSkeleton(width: 80, height: 26, borderRadius: 8),
                        _PulsingSkeleton(width: 100, height: 28, borderRadius: 8),
                      ],
                    ),
                    SizedBox(height: 20),
                    _PulsingSkeleton(width: 160, height: 32, borderRadius: 6),
                    SizedBox(height: 24),
                    _PulsingSkeleton(width: double.infinity, height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    _PulsingSkeleton(width: double.infinity, height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    _PulsingSkeleton(width: 200, height: 16, borderRadius: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Better aligned Icons alongside Badges.
  Widget _buildStatusBadge(bool isTowed) {
    final bgColor = isTowed ? Colors.red.shade50 : Colors.orange.shade50;
    final fgColor = isTowed ? Colors.red.shade700 : Colors.orange.shade800;
    final iconType = isTowed ? Icons.local_shipping_rounded : Icons.receipt_long_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconType, size: 14, color: fgColor),
          const SizedBox(width: 4),
          Text(
            isTowed ? "TOW NOTICE" : "CHALLAN NOTICE",
            style: TextStyle(color: fgColor, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey.shade300),
          const SizedBox(width: 8),
          Text("$label:", style: const TextStyle(color: textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Expanded(child: Text(val, style: const TextStyle(color: textDark, fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  /// Dialog full screen Lightbox UX Viewer
  void _showFullImage(String url) {
    showGeneralDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.95),
      barrierDismissible: true,
      barrierLabel: "Close",
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, _, __) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    url,
                    loadingBuilder: (ctx, child, p) => p == null 
                        ? child 
                        : const CircularProgressIndicator(color: Colors.white),
                    errorBuilder: (ctx, _, __) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Image not found.', style: TextStyle(color: Colors.white))
                      ]
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 50,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

// MINIMAL ANIMATED SKELETON HELPER
class _PulsingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  
  const _PulsingSkeleton({required this.width, required this.height, this.borderRadius = 16});

  @override
  State<_PulsingSkeleton> createState() => _PulsingSkeletonState();
}

class _PulsingSkeletonState extends State<_PulsingSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 0.8).animate(_controller),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
