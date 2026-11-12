import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SharedCouponFeed {
  SharedCouponFeed.fromJson(Map<String, dynamic> json)
    : state = json['state'] as String?,
      societyName = json['society_name'] as String?,
      regionalCoupons = _readCoupons(json['regional_coupons']),
      societyCoupons = _readCoupons(json['society_coupons']);

  final String? state;
  final String? societyName;
  final List<SharedCoupon> regionalCoupons;
  final List<SharedCoupon> societyCoupons;

  static List<SharedCoupon> _readCoupons(List<dynamic> items) => items
      .map((item) => SharedCoupon.fromJson(item as Map<String, dynamic>))
      .toList();
}

class SharedCoupon {
  SharedCoupon.fromJson(Map<String, dynamic> json)
    : brand = json['brand'] as String,
      title = json['title'] as String,
      description = json['description'] as String,
      code = json['code'] as String,
      priority = json['society_priority'] == true;

  final String brand;
  final String title;
  final String description;
  final String code;
  final bool priority;
}

class SharedCouponCard extends StatelessWidget {
  const SharedCouponCard({super.key, required this.coupon});

  final SharedCoupon coupon;

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
          ],
        ),
      ),
    );
  }
}
