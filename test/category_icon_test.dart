import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/core/category_icons.dart';
import 'package:suikai/data/models.dart';

void main() {
  test('category icon uses the Supabase icon identifier', () {
    final category = CategoryRecord.fromJson({
      'id': 'category-1',
      'type': 'listing',
      'name_th': 'หมวดทดสอบ',
      'icon_key': 'restaurant',
      'sort_order': 0,
    });

    expect(category.iconKey, 'restaurant');
    expect(categoryIconData(category.iconKey), Icons.restaurant_outlined);
    expect(category.toJson()['icon_key'], 'restaurant');
  });

  test('missing or unknown icon falls back to Icons.category', () {
    final missing = CategoryRecord.fromJson({
      'id': 'category-2',
      'type': 'store',
      'name_th': 'หมวดเก่า',
      'sort_order': 0,
    });

    expect(categoryIconData(missing.iconKey), Icons.category);
    expect(categoryIconData('unsupported-icon'), Icons.category);
    expect(categoryIconData(null), Icons.category);
  });

  test(
    'icon catalog is grouped and searchable without category-name mapping',
    () {
      expect(
        categoryIconGroups,
        containsAll(['Food', 'IT', 'Pets', 'General']),
      );
      expect(
        categoryIconCatalog
            .where((option) => option.matches('รถ'))
            .map((option) => option.key),
        contains('directions_car'),
      );
      expect(
        categoryIconCatalog
            .where((option) => option.matches('Cleaning'))
            .map((option) => option.group)
            .toSet(),
        contains('Cleaning'),
      );
      expect(categoryIconOptions.length, greaterThan(100));
    },
  );
}
