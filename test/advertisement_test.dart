import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/data/models.dart';

void main() {
  AdvertisementRecord banner({
    bool active = true,
    DateTime? start,
    DateTime? end,
  }) => AdvertisementRecord(
    id: 'banner-1',
    title: 'Banner',
    imageUrl: 'https://example.com/banner.jpg',
    targetType: 'product',
    targetId: 'product-1',
    startAt: start,
    endAt: end,
    displayOrder: 2,
    isActive: active,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  test('advertisement visibility follows active date range', () {
    final now = DateTime.now();
    expect(
      banner(
        start: now.subtract(const Duration(days: 1)),
        end: now.add(const Duration(days: 1)),
      ).isCurrentlyVisible,
      isTrue,
    );
    expect(banner(active: false).isCurrentlyVisible, isFalse);
    expect(
      banner(start: now.add(const Duration(days: 1))).isCurrentlyVisible,
      isFalse,
    );
    expect(
      banner(end: now.subtract(const Duration(days: 1))).isCurrentlyVisible,
      isFalse,
    );
  });

  test('advertisement reads canonical Supabase fields', () {
    final value = AdvertisementRecord.fromJson({
      'id': 'banner-2',
      'title': 'Promotion',
      'image_url': 'https://example.com/promotion.jpg',
      'target_type': 'shop',
      'target_id': 'shop-1',
      'display_order': 3,
      'is_active': true,
    });
    expect(value.targetType, 'shop');
    expect(value.targetId, 'shop-1');
    expect(value.displayOrder, 3);
    expect(value.isActive, isTrue);
  });
}
