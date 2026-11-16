import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parkingmudde/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

Uri? sharedCouponWebsiteUri(String? text) {
  final uri = Uri.tryParse(text?.trim() ?? '');
  if (uri == null ||
      (uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return uri;
}

class SharedCouponFeed {
  SharedCouponFeed.fromJson(Map<String, dynamic> json)
    : state = json['state'] as String?,
      societyName = json['society_name'] as String?,
      regionalCoupons = _readCoupons(json['regional_coupons']),
      societyCoupons = _readCoupons(json['society_coupons']),
      myCoupons = _readCoupons(json['my_coupons']);

  final String? state;
  final String? societyName;
  final List<SharedCoupon> regionalCoupons;
  final List<SharedCoupon> societyCoupons;
  final List<SharedCoupon> myCoupons;

  static List<SharedCoupon> _readCoupons(List<dynamic>? items) => (items ?? [])
      .map((item) => SharedCoupon.fromJson(item as Map<String, dynamic>))
      .toList();
}

class SharedCoupon {
  SharedCoupon.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int?,
      brand = json['brand'] as String,
      title = json['title'] as String,
      description = json['description'] as String,
      code = json['code'] as String,
      website = sharedCouponWebsiteUri(json['website_url'] as String?),
      imageUrl = json['image_url'] as String?,
      states = (json['states'] as List<dynamic>?)?.cast<String>(),
      priority = json['society_priority'] == true,
      priorityRequested = json['priority_requested'] == true;

  final int? id;
  final String brand;
  final String title;
  final String description;
  final String code;
  final Uri? website;
  final String? imageUrl;
  final List<String>? states;
  final bool priority;
  final bool priorityRequested;
}

class SharedCouponImage extends StatelessWidget {
  const SharedCouponImage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url.startsWith('/') ? '${ApiService.baseUrl}$url' : url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(
          Icons.broken_image_outlined,
          semanticLabel: 'Image unavailable',
        ),
      ),
    );
  }
}

class SharedCouponCard extends StatelessWidget {
  const SharedCouponCard({
    super.key,
    required this.coupon,
    this.onEdit,
    this.onDelete,
    this.deleting = false,
  });

  final SharedCoupon coupon;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool deleting;

  Future<void> _visitWebsite(BuildContext context, Uri website) async {
    try {
      if (await launchUrl(website, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {
      // The device may not have a browser that handles this link.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the coupon website.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const blue = Color(0xFF184B8C);
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (coupon.imageUrl case final imageUrl?) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: const Color(0xFFF6F8FA),
                  child: AspectRatio(
                    aspectRatio: 2,
                    child: SharedCouponImage(url: imageUrl),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  coupon.brand,
                  style: theme.textTheme.labelLarge?.copyWith(color: blue),
                ),
                if (coupon.priority)
                  const Text(
                    'Society priority',
                    style: TextStyle(
                      color: Color(0xFF854D0E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(coupon.title, style: theme.textTheme.titleMedium),
            if (coupon.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(coupon.description, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEDF4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: SelectableText(
                        coupon.code,
                        style: const TextStyle(
                          color: blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy code',
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: coupon.code));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coupon code copied')),
                      );
                    },
                    icon: const Icon(Icons.copy_outlined, color: blue),
                  ),
                ],
              ),
            ),
            if (coupon.website != null || onEdit != null || onDelete != null)
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (coupon.website case final website?)
                    TextButton.icon(
                      onPressed: () => _visitWebsite(context, website),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Visit website'),
                    ),
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: deleting ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  if (onDelete != null)
                    OutlinedButton.icon(
                      onPressed: deleting ? null : onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(
                          color: deleting
                              ? theme.colorScheme.outlineVariant
                              : theme.colorScheme.error,
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(deleting ? 'Deleting…' : 'Delete'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
