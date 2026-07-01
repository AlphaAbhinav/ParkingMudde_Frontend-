import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class DynamicAdCarousel extends StatefulWidget {
  final String pageName;

  const DynamicAdCarousel({Key? key, required this.pageName}) : super(key: key);

  @override
  State<DynamicAdCarousel> createState() => _DynamicAdCarouselState();
}

class _DynamicAdCarouselState extends State<DynamicAdCarousel> {
  List<dynamic> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  Future<void> _loadAds() async {
    try {
      final fetchedAds = await ApiService.getAds();
      if (mounted) {
        setState(() {
          // Filter ads based on target_pages
          _ads = fetchedAds.where((ad) {
            final targetPagesStr = ad['target_pages'] as String?;
            if (targetPagesStr == null || targetPagesStr.trim().isEmpty) {
              return true; // If no target pages specified, show everywhere
            }
            final pages = targetPagesStr.split(',').map((p) => p.trim()).toList();
            return pages.contains(widget.pageName);
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    var uri = Uri.parse(url);
    if (!uri.hasScheme) {
      uri = Uri.parse('https://$url');
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Could not launch $url");
    }
  }

  String _getFullImageUrl(String url) {
    if (url.startsWith('/')) {
      return "${ApiService.baseUrl}$url";
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
    }

    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 140.0,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            aspectRatio: 16 / 9,
            autoPlayInterval: const Duration(seconds: 4),
          ),
          items: _ads.map((ad) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    final targetUrl = ad['target_url'];
                    if (targetUrl != null && targetUrl.toString().isNotEmpty) {
                      _launchUrl(targetUrl);
                    }
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(_getFullImageUrl(ad['image_url'] ?? '')),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.bottomLeft,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (ad['title'] != null && ad['title'].toString().isNotEmpty)
                            Text(
                              ad['title'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (ad['text'] != null && ad['text'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                ad['text'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
