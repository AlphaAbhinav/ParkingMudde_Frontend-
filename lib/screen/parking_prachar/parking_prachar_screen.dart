import 'package:flutter/material.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ParkingPracharScreen extends StatefulWidget {
  const ParkingPracharScreen({super.key});

  @override
  State<ParkingPracharScreen> createState() => _ParkingPracharScreenState();
}

class _ParkingPracharScreenState extends State<ParkingPracharScreen> {
  List<dynamic> _blogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBlogs();
  }

  Future<void> _fetchBlogs() async {
    try {
      final blogs = await ApiService.getBlogs();
      setState(() {
        _blogs = blogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint("Error fetching blogs: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Parking Prachaar",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blogs.isEmpty
              ? const Center(child: Text("No blogs available."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _blogs.length,
                  itemBuilder: (context, index) {
                    final blog = _blogs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildBlogCard(
                        title: blog["title"] ?? "Untitled",
                        category: "Blog",
                        imageUrl: blog["image_url"] ?? "",
                        description: blog["description"] ?? "",
                        targetUrl: blog["url"] ?? "",
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildBlogCard({
    required String title,
    required String category,
    required String imageUrl,
    required String description,
    required String targetUrl,
  }) {
    final fullImageUrl = imageUrl.startsWith('/') ? '${ApiService.baseUrl}$imageUrl' : imageUrl;

    return GestureDetector(
      onTap: () async {
          var uri = Uri.parse(targetUrl);
          if (!uri.hasScheme) {
            uri = Uri.parse('https://$targetUrl');
          }
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (e) {
            debugPrint("Could not launch $targetUrl");
          }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 180,
              color: Colors.grey.shade200,
              child: fullImageUrl.isNotEmpty
                  ? Image.network(
                      fullImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                    )
                  : const Icon(Icons.article_rounded, size: 64, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        "Read More",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
