import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum ListingStatus { available, reserved, sold, outOfStock }

extension ListingStatusUi on ListingStatus {
  String get label => switch (this) {
    ListingStatus.available => 'พร้อมขาย',
    ListingStatus.reserved => 'จอง',
    ListingStatus.sold => 'ขายแล้ว',
    ListingStatus.outOfStock => 'หมด',
  };

  Color get color => switch (this) {
    ListingStatus.available => AppTheme.success,
    ListingStatus.reserved => AppTheme.warning,
    ListingStatus.sold => AppTheme.textSecondary,
    ListingStatus.outOfStock => AppTheme.danger,
  };
}

class CategoryItem {
  final String label;
  final IconData icon;
  const CategoryItem(this.label, this.icon);
}

class ProductItem {
  final String id;
  final String title;
  final String price;
  final String city;
  final String category;
  final String image;
  final int likes;
  final int views;
  final ListingStatus status;
  final String? storeId;

  const ProductItem({
    required this.id,
    required this.title,
    required this.price,
    required this.city,
    required this.category,
    required this.image,
    required this.likes,
    required this.views,
    required this.status,
    this.storeId,
  });
}

class StoreItem {
  final String id;
  final String name;
  final String category;
  final String city;
  final String logo;
  final String hours;
  final String phone;
  final bool approved;

  const StoreItem({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.logo,
    required this.hours,
    required this.phone,
    required this.approved,
  });
}

const categories = <CategoryItem>[
  CategoryItem('ทั้งหมด', Icons.grid_view_rounded),
  CategoryItem('รถยนต์', Icons.directions_car_filled_rounded),
  CategoryItem('มอเตอร์ไซค์', Icons.two_wheeler_rounded),
  CategoryItem('มือถือ', Icons.smartphone_rounded),
  CategoryItem('คอมพิวเตอร์', Icons.laptop_mac_rounded),
  CategoryItem('บ้าน', Icons.chair_alt_rounded),
  CategoryItem('เสื้อผ้า', Icons.checkroom_rounded),
  CategoryItem('อื่นๆ', Icons.more_horiz_rounded),
];

const storeCategories = <CategoryItem>[
  CategoryItem('ทั้งหมด', Icons.storefront_rounded),
  CategoryItem('อาหาร', Icons.restaurant_rounded),
  CategoryItem('ไอที', Icons.devices_rounded),
  CategoryItem('อะไหล่รถ', Icons.build_rounded),
  CategoryItem('ความงาม', Icons.spa_rounded),
  CategoryItem('เสื้อผ้า', Icons.checkroom_rounded),
  CategoryItem('โรงแรม', Icons.hotel_rounded),
  CategoryItem('ปั๊มน้ำมัน', Icons.local_gas_station_rounded),
];

const products = <ProductItem>[
  ProductItem(
    id: 'p1',
    title: 'Toyota Vios 2019',
    price: '32,500,000 Ks',
    city: 'Nam Chan',
    category: 'รถยนต์',
    image:
        'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=800&q=80',
    likes: 42,
    views: 760,
    status: ListingStatus.available,
  ),
  ProductItem(
    id: 'p2',
    title: 'iPhone 13 Pro Max 256GB',
    price: '1,850,000 Ks',
    city: 'Nam Chan',
    category: 'มือถือ',
    image:
        'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?auto=format&fit=crop&w=800&q=80',
    likes: 27,
    views: 530,
    status: ListingStatus.reserved,
  ),
  ProductItem(
    id: 'p3',
    title: 'โซฟา 3 ที่นั่ง',
    price: '420,000 Ks',
    city: 'Nam Chan',
    category: 'บ้าน',
    image:
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=800&q=80',
    likes: 16,
    views: 210,
    status: ListingStatus.available,
  ),
  ProductItem(
    id: 'p4',
    title: 'MacBook Air M2',
    price: '2,700,000 Ks',
    city: 'Nam Chan',
    category: 'คอมพิวเตอร์',
    image:
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=800&q=80',
    likes: 51,
    views: 980,
    status: ListingStatus.available,
    storeId: 's2',
  ),
];

const stores = <StoreItem>[
  StoreItem(
    id: 's1',
    name: 'Shan Kitchen',
    category: 'อาหาร',
    city: 'Nam Chan',
    logo:
        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=500&q=80',
    hours: '08:00 - 20:00',
    phone: '09 111 222 333',
    approved: true,
  ),
  StoreItem(
    id: 's2',
    name: 'Mobi Center',
    category: 'ไอที',
    city: 'Nam Chan',
    logo:
        'https://images.unsplash.com/photo-1531297484001-80022131f5a1?auto=format&fit=crop&w=500&q=80',
    hours: '09:00 - 19:00',
    phone: '09 222 333 444',
    approved: true,
  ),
  StoreItem(
    id: 's3',
    name: 'Nam Chan Auto Parts',
    category: 'อะไหล่รถ',
    city: 'Nam Chan',
    logo:
        'https://images.unsplash.com/photo-1486262715619-67b85e0b08d3?auto=format&fit=crop&w=500&q=80',
    hours: '08:00 - 18:00',
    phone: '09 333 444 555',
    approved: true,
  ),
];
