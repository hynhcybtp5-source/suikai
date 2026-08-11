import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/locale_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mobile_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../services/suikai_service.dart';
import '../../services/fx_service.dart';
import '../../data/models.dart';
import '../admin/admin_dashboard.dart';
import '../auth/auth_page.dart';

class SuikaiRoutes {
  static const home = '/';
  static const stores = '/stores';
  static const post = '/post';
  static const map = '/map';
  static const profile = '/profile';
  static const search = '/search';
  static const notifications = '/notifications';
  static const storeDetail = '/store-detail';
  static const productDetail = '/product-detail';
  static const report = '/report';
  static const openShop = '/open-shop';
  static const admin = '/admin';
  static const login = '/login';

  static Widget _protected(String route, Widget child) =>
      SuikaiService.isLoggedIn ? child : LoginPage(pendingRoute: route);

  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const HomePage(),
    stores: (_) => const StoreListPage(),
    post: (_) => _protected(post, const PostPage()),
    map: (_) => const MapPage(),
    profile: (_) => _protected(profile, const ProfilePage()),
    search: (_) => const SearchPage(),
    notifications: (_) => const NotificationsPage(),
    openShop: (_) => _protected(openShop, const OpenShopPage()),
    login: (_) => const LoginPage(pendingRoute: home),
    admin: (_) => const AdminDashboard(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case storeDetail:
        final storeId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => StoreDetailPage(storeId: storeId ?? ''),
          settings: settings,
        );
      case productDetail:
        final productId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ProductDetailPage(productId: productId ?? ''),
          settings: settings,
        );
      case report:
        final productId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ReportPage(productId: productId ?? ''),
          settings: settings,
        );
      default:
        return null;
    }
  }
}

enum ProductStatus { available, reserved, sold, outOfStock, deleted }

ProductStatus _productStatus(String? value) => switch (value) {
  'reserved' => ProductStatus.reserved,
  'sold' => ProductStatus.sold,
  'out_of_stock' || 'outOfStock' => ProductStatus.outOfStock,
  'deleted' => ProductStatus.deleted,
  _ => ProductStatus.available,
};

extension ProductStatusX on ProductStatus {
  Color get color {
    switch (this) {
      case ProductStatus.available:
        return const Color(0xFF1D9B53);
      case ProductStatus.reserved:
        return const Color(0xFFE28A00);
      case ProductStatus.sold:
        return AppTheme.textMuted;
      case ProductStatus.outOfStock:
        return const Color(0xFFD24A00);
      case ProductStatus.deleted:
        return const Color(0xFFB12020);
    }
  }
}

class MockStore {
  final String id;
  final String name;
  final String type;
  final String city;
  final String distance;
  final String logo;
  final String description;
  final String phone;
  final String viber;
  final String hours;
  final bool approved;
  final String searchableProducts;
  final String? ownerId;
  final String? coverUrl;
  final String? email;
  final bool isPromoted;
  final DateTime? promotionStartAt;
  final DateTime? promotionEndAt;
  final double? latitude;
  final double? longitude;

  const MockStore({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.distance,
    required this.logo,
    required this.description,
    required this.phone,
    required this.viber,
    required this.hours,
    required this.approved,
    this.searchableProducts = '',
    this.ownerId,
    this.coverUrl,
    this.email,
    this.isPromoted = false,
    this.promotionStartAt,
    this.promotionEndAt,
    this.latitude,
    this.longitude,
  });

  bool get promotionIsActive {
    if (!isPromoted) return false;
    final now = DateTime.now();
    return (promotionStartAt == null || !now.isBefore(promotionStartAt!)) &&
        (promotionEndAt == null || !now.isAfter(promotionEndAt!));
  }
}

IconData _storeCategoryIcon(String value) => switch (value) {
  'store_food' || 'listing_food' => Icons.restaurant_rounded,
  'store_cafe' => Icons.local_cafe_rounded,
  'store_auto_repair' || 'listing_vehicles' => Icons.car_repair_rounded,
  'store_hotpot' => Icons.soup_kitchen_rounded,
  'store_grill' => Icons.outdoor_grill_rounded,
  'store_supermarket' => Icons.shopping_basket_rounded,
  'store_beauty' => Icons.content_cut_rounded,
  'store_pets' => Icons.pets_rounded,
  'store_pharmacy' => Icons.medical_services_rounded,
  'store_mobile' || 'listing_mobile' => Icons.phone_android_rounded,
  'store_electronics' || 'listing_electronics' => Icons.devices_rounded,
  'store_fashion' || 'listing_fashion' => Icons.checkroom_rounded,
  'store_home' || 'listing_home' => Icons.home_outlined,
  'store_services' || 'listing_tools' => Icons.handyman_outlined,
  _ => Icons.more_horiz_rounded,
};

String _categoryLabel(BuildContext context, String type, String value) =>
    SuikaiService.categoryLabel(
      type,
      value,
      Localizations.localeOf(context).languageCode,
    );

class MockProduct {
  final String id;
  final String title;
  final int priceValue;
  final String currencyCode;
  final String description;
  final String category;
  final String city;
  final String location;
  final String time;
  final String image;
  final String phone;
  final String viber;
  final int likeCount;
  final int viewCount;
  final ProductStatus status;
  final String? storeId;
  final String? ownerId;
  final List<String> images;
  final double? latitude;
  final double? longitude;
  final bool isLocationVisible;

  const MockProduct({
    required this.id,
    required this.title,
    required this.priceValue,
    this.currencyCode = 'THB',
    required this.description,
    required this.category,
    required this.city,
    required this.location,
    required this.time,
    required this.image,
    required this.phone,
    required this.viber,
    required this.likeCount,
    required this.viewCount,
    required this.status,
    this.storeId,
    this.ownerId,
    this.images = const [],
    this.latitude,
    this.longitude,
    this.isLocationVisible = true,
  });

  bool get isStoreProduct => storeId != null;
  String get price => formatPrice(priceValue, currencyCode);
  List<String> get imageUrls => images.isEmpty ? [image] : images;
}

String? primaryProductImage(MockProduct product) {
  final source = product.images.firstOrNull ?? product.image;
  return source.trim().isEmpty ? null : source;
}

String formatPrice(int value, String currencyCode) {
  final formatted = value.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  switch (currencyCode.toUpperCase()) {
    case 'MMK':
      return '$formatted MMK';
    case 'USD':
      return '\$$formatted';
    case 'CNY':
      return '¥$formatted';
    case 'THB':
    default:
      return '฿$formatted';
  }
}

String formatCurrencyAmount(double value, String currencyCode) {
  final safe = value.isFinite && !value.isNaN && value >= 0 ? value : 0.0;
  final decimals = currencyCode == 'USD' || currencyCode == 'CNY' ? 2 : 0;
  final parts = safe.toStringAsFixed(decimals).split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  final fraction = decimals > 0 ? '.${parts.last}' : '';
  return '$whole$fraction ${currencyCode.toUpperCase()}';
}

String normalizeText(String? value) => (value ?? '').trim();

int? parsePriceValue(String? value) {
  final text = normalizeText(value).replaceAll(',', '');
  if (text.isEmpty) {
    return null;
  }
  return int.tryParse(text);
}

String normalizePhone(String? value) {
  final normalized = normalizeText(value).replaceAll(RegExp(r'[^0-9+]'), '');
  if (normalized.isEmpty) {
    return '';
  }
  return normalized.startsWith('+') ? normalized : normalized;
}

String? validatePhone(String? value) {
  final normalized = normalizePhone(value);
  if (normalized.isEmpty) {
    return 'กรุณากรอกเบอร์โทร';
  }
  final isValid = RegExp(r'^\+?[0-9\s()-]{7,15}$').hasMatch(normalized);
  return isValid ? null : 'รูปแบบเบอร์โทรไม่ถูกต้อง';
}

String? validateEmail(String? value) {
  final normalized = normalizeText(value);
  if (normalized.isEmpty) {
    return null;
  }
  final isValid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized);
  return isValid ? null : 'รูปแบบอีเมลไม่ถูกต้อง';
}

class MockRepo {
  static final stores = <MockStore>[
    MockStore(
      id: 's1',
      name: 'Nang Auto House',
      type: 'ยานพาหนะ',
      city: 'เมืองนาง',
      distance: '1.2 กม.',
      logo:
          'https://images.unsplash.com/photo-1549924231-f129b911e442?auto=format&fit=crop&w=300&q=80',
      description: 'รถมือสองคุณภาพ พร้อมตรวจเช็คก่อนส่งมอบ',
      phone: '0205551111',
      viber: '0205551111',
      hours: '08:00 - 18:00',
      approved: true,
    ),
    MockStore(
      id: 's2',
      name: 'Mobi Center',
      type: 'มือถือ & แท็บเล็ต',
      city: 'เมืองนาง',
      distance: '2.0 กม.',
      logo:
          'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=300&q=80',
      description: 'เครื่องแท้ อุปกรณ์ครบ มีรับประกันร้าน',
      phone: '0205552222',
      viber: '0205552222',
      hours: '09:00 - 19:00',
      approved: true,
    ),
    MockStore(
      id: 's3',
      name: 'Home Loft Market',
      type: 'บ้าน & สวน',
      city: 'หาดคำ',
      distance: '3.8 กม.',
      logo:
          'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=300&q=80',
      description: 'เฟอร์นิเจอร์และของแต่งบ้านสภาพดี',
      phone: '0205553333',
      viber: '0205553333',
      hours: '10:00 - 20:00',
      approved: true,
    ),
    MockStore(
      id: 's4',
      name: 'Pending Gadget Shop',
      type: 'มือถือ & แท็บเล็ต',
      city: 'เมืองนาง',
      distance: '5.0 กม.',
      logo:
          'https://images.unsplash.com/photo-1468495244123-6c6c332eeece?auto=format&fit=crop&w=300&q=80',
      description: 'ร้านยังรอการอนุมัติ',
      phone: '0205554444',
      viber: '0205554444',
      hours: '08:00 - 17:00',
      approved: false,
    ),
  ];

  static final products = <MockProduct>[
    MockProduct(
      id: 'p1',
      title: 'Toyota Vios 2019',
      priceValue: 325000,
      description: 'รถบ้านสภาพดี ไมล์แท้ พร้อมโอน',
      category: 'ยานพาหนะ',
      city: 'เมืองนาง',
      location: 'น้ำจ่าง, เมืองนาง',
      time: '2 ชั่วโมงที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&w=700&q=80',
      phone: '0201110001',
      viber: '0201110001',
      likeCount: 42,
      viewCount: 760,
      status: ProductStatus.available,
    ),
    MockProduct(
      id: 'p2',
      title: 'iPhone 13 Pro Max 256GB',
      priceValue: 18500,
      description: 'เครื่องศูนย์ แบตดี 88%',
      category: 'มือถือ & แท็บเล็ต',
      city: 'เมืองนาง',
      location: 'น้ำจ่าง, เมืองนาง',
      time: '3 ชั่วโมงที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?auto=format&fit=crop&w=700&q=80',
      images: [
        'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?auto=format&fit=crop&w=700&q=80',
        'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?auto=format&fit=crop&w=700&q=80',
        'https://images.unsplash.com/photo-1580910051074-3eb694886505?auto=format&fit=crop&w=700&q=80',
      ],
      phone: '0201110002',
      viber: '0201110002',
      likeCount: 27,
      viewCount: 530,
      status: ProductStatus.available,
    ),
    MockProduct(
      id: 'p3',
      title: 'โซฟา 3 ที่นั่ง สภาพดี',
      priceValue: 4200,
      description: 'ใช้งานน้อย ไม่มีรอยขาด',
      category: 'บ้าน & สวน',
      city: 'หาดคำ',
      location: 'หาดคำ, เมืองนาง',
      time: '5 ชั่วโมงที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?auto=format&fit=crop&w=700&q=80',
      phone: '0201110003',
      viber: '0201110003',
      likeCount: 18,
      viewCount: 240,
      status: ProductStatus.reserved,
    ),
    MockProduct(
      id: 'p4',
      title: 'Yamaha Exciter 150cc',
      priceValue: 28000,
      description: 'รถพร้อมใช้งาน เอกสารครบ',
      category: 'ยานพาหนะ',
      city: 'เมืองนาง',
      location: 'หนองบัว, เมืองนาง',
      time: '1 วันที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1558981806-ec527fa84c39?auto=format&fit=crop&w=700&q=80',
      phone: '0201110004',
      viber: '0201110004',
      likeCount: 35,
      viewCount: 412,
      status: ProductStatus.sold,
    ),
    MockProduct(
      id: 'p5',
      title: 'MacBook Air M1 256GB',
      priceValue: 21500,
      description: 'อุปกรณ์ครบ ใช้งานปกติ',
      category: 'มือถือ & แท็บเล็ต',
      city: 'เมืองนาง',
      location: 'น้ำจ่าง, เมืองนาง',
      time: '1 วันที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?auto=format&fit=crop&w=700&q=80',
      phone: '0201110005',
      viber: '0201110005',
      likeCount: 48,
      viewCount: 1002,
      status: ProductStatus.available,
      storeId: 's2',
    ),
    MockProduct(
      id: 'p6',
      title: 'iPhone 11 128GB',
      priceValue: 12900,
      description: 'เครื่องศูนย์ไทย มีเคสและสายชาร์จ',
      category: 'มือถือ & แท็บเล็ต',
      city: 'เมืองนาง',
      location: 'น้ำจ่าง, เมืองนาง',
      time: '2 วันที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1574755393849-623942496936?auto=format&fit=crop&w=700&q=80',
      phone: '0201110006',
      viber: '0201110006',
      likeCount: 22,
      viewCount: 390,
      status: ProductStatus.outOfStock,
      storeId: 's2',
    ),
    MockProduct(
      id: 'p7',
      title: 'โต๊ะอาหาร 4 ที่นั่ง',
      priceValue: 7800,
      description: 'ไม้จริง แข็งแรง',
      category: 'บ้าน & สวน',
      city: 'หาดคำ',
      location: 'หาดคำ, เมืองนาง',
      time: '2 วันที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1577140917170-285929fb55b7?auto=format&fit=crop&w=700&q=80',
      phone: '0201110007',
      viber: '0201110007',
      likeCount: 15,
      viewCount: 206,
      status: ProductStatus.deleted,
      storeId: 's3',
    ),
    MockProduct(
      id: 'p8',
      title: 'Honda City 2018',
      priceValue: 265000,
      description: 'เจ้าของขายเอง เอกสารพร้อม',
      category: 'ยานพาหนะ',
      city: 'เมืองนาง',
      location: 'น้ำจ่าง, เมืองนาง',
      time: '2 วันที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1553440569-bcc63803a83d?auto=format&fit=crop&w=700&q=80',
      phone: '0201110008',
      viber: '0201110008',
      likeCount: 31,
      viewCount: 460,
      status: ProductStatus.available,
      storeId: 's1',
    ),
    MockProduct(
      id: 'p9',
      title: 'เสื้อแจ็กเก็ตผ้ายีนส์',
      priceValue: 45,
      currencyCode: 'USD',
      description: 'สภาพดี ใส่น้อย',
      category: 'แฟชั่น',
      city: 'เมืองนาง',
      location: 'ตลาดกลาง, เมืองนาง',
      time: '3 วันที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1551028719-00167b16eac5?auto=format&fit=crop&w=700&q=80',
      phone: '0201110009',
      viber: '0201110009',
      likeCount: 12,
      viewCount: 184,
      status: ProductStatus.available,
    ),
    MockProduct(
      id: 'p10',
      title: 'กาแฟคั่วเมล็ด 1 กิโลกรัม',
      priceValue: 32000,
      currencyCode: 'MMK',
      description: 'คั่วสด กลิ่นหอม',
      category: 'อาหาร & เครื่องดื่ม',
      city: 'ตองจี',
      location: 'ตองจี, รัฐฉาน',
      time: '4 ชั่วโมงที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1447933601403-0c6688de566e?auto=format&fit=crop&w=700&q=80',
      phone: '0201110010',
      viber: '0201110010',
      likeCount: 33,
      viewCount: 298,
      status: ProductStatus.available,
    ),
    MockProduct(
      id: 'p11',
      title: 'สว่านไร้สายพร้อมแบตเตอรี่',
      priceValue: 1850,
      currencyCode: 'THB',
      description: 'พร้อมกล่องและดอกสว่าน',
      category: 'เครื่องมือ & อุปกรณ์',
      city: 'หาดคำ',
      location: 'หาดคำ, เมืองนาง',
      time: '6 ชั่วโมงที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=700&q=80',
      phone: '0201110011',
      viber: '0201110011',
      likeCount: 9,
      viewCount: 126,
      status: ProductStatus.reserved,
    ),
    MockProduct(
      id: 'p12',
      title: 'ลำโพง Bluetooth',
      priceValue: 260,
      currencyCode: 'CNY',
      description: 'เสียงดี แบตใช้งานได้ทั้งวัน',
      category: 'มือถือ & แท็บเล็ต',
      city: 'เมืองนาง',
      location: 'น้ำจ่าง, เมืองนาง',
      time: 'เมื่อวาน',
      image:
          'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?auto=format&fit=crop&w=700&q=80',
      phone: '0201110012',
      viber: '0201110012',
      likeCount: 21,
      viewCount: 347,
      status: ProductStatus.available,
    ),
    MockProduct(
      id: 'p13',
      title: 'ตู้ไม้เก็บของสองบาน',
      priceValue: 6500,
      currencyCode: 'THB',
      description: 'ไม้แข็งแรง พร้อมใช้งาน',
      category: 'บ้าน & สวน',
      city: 'เมืองนาง',
      location: 'หนองบัว, เมืองนาง',
      time: '2 วันที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1558997519-83ea9252edf8?auto=format&fit=crop&w=700&q=80',
      phone: '0201110013',
      viber: '0201110013',
      likeCount: 16,
      viewCount: 211,
      status: ProductStatus.available,
    ),
    MockProduct(
      id: 'p14',
      title: 'กล่องสะสมงานหัตถกรรม',
      priceValue: 75000,
      currencyCode: 'MMK',
      description: 'งานทำมือจากชุมชน',
      category: 'อื่นๆ',
      city: 'สีป้อ',
      location: 'สีป้อ, รัฐฉาน',
      time: '5 วันที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1452860606245-08befc0ff44b?auto=format&fit=crop&w=700&q=80',
      phone: '0201110014',
      viber: '0201110014',
      likeCount: 7,
      viewCount: 98,
      status: ProductStatus.available,
    ),
    MockProduct(
      id: 'p15',
      title: 'หมวกกันน็อกเต็มใบ',
      priceValue: 2200,
      description: 'มี มอก. สภาพใหม่',
      category: 'ยานพาหนะ',
      city: 'เมืองนาง',
      location: 'เมืองนาง',
      time: '1 ชั่วโมงที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1558981359-219d6364c9c8?auto=format&fit=crop&w=700&q=80',
      phone: '0201110015',
      viber: '0201110015',
      likeCount: 14,
      viewCount: 190,
      status: ProductStatus.available,
    ),
    MockProduct(
      id: 'p16',
      title: 'รองเท้าผ้าใบสีขาว',
      priceValue: 980,
      description: 'ไซซ์ 40 ไม่เคยใช้งาน',
      category: 'แฟชั่น',
      city: 'ตองจี',
      location: 'ตองจี',
      time: '8 ชั่วโมงที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=700&q=80',
      phone: '0201110016',
      viber: '0201110016',
      likeCount: 25,
      viewCount: 321,
      status: ProductStatus.available,
    ),
    MockProduct(
      id: 'p17',
      title: 'ชุดประแจอเนกประสงค์',
      priceValue: 48000,
      currencyCode: 'MMK',
      description: 'ครบชุดพร้อมกล่อง',
      category: 'เครื่องมือ & อุปกรณ์',
      city: 'สีป้อ',
      location: 'สีป้อ',
      time: 'เมื่อวาน',
      image:
          'https://images.unsplash.com/photo-1581147036324-c1c89c2c8b5c?auto=format&fit=crop&w=700&q=80',
      phone: '0201110017',
      viber: '0201110017',
      likeCount: 11,
      viewCount: 155,
      status: ProductStatus.available,
    ),
    MockProduct(
      id: 'p18',
      title: 'น้ำผึ้งธรรมชาติ 500 กรัม',
      priceValue: 38,
      currencyCode: 'CNY',
      description: 'น้ำผึ้งแท้จากชุมชน',
      category: 'อาหาร & เครื่องดื่ม',
      city: 'หาดคำ',
      location: 'หาดคำ',
      time: '2 ชั่วโมงที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1587049352846-4a222e784d38?auto=format&fit=crop&w=700&q=80',
      phone: '0201110018',
      viber: '0201110018',
      likeCount: 19,
      viewCount: 267,
      status: ProductStatus.available,
    ),
  ];

  static List<MockStore> get approvedStores =>
      stores.where((store) => store.approved).toList();

  static List<MockProduct> get feedProducts {
    return products.where((product) {
      if (product.status == ProductStatus.sold ||
          product.status == ProductStatus.outOfStock ||
          product.status == ProductStatus.deleted) {
        return false;
      }
      if (!product.isStoreProduct) {
        return true;
      }
      final store = storeById(product.storeId!);
      return store?.approved == true;
    }).toList();
  }

  static MockStore? storeById(String id) {
    for (final store in stores) {
      if (store.id == id) {
        return store;
      }
    }
    return null;
  }

  static MockProduct? productById(String id) {
    for (final product in products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  static void cacheProducts(Iterable<MockProduct> remote) {
    for (final product in remote) {
      final index = products.indexWhere((item) => item.id == product.id);
      if (index < 0)
        products.add(product);
      else
        products[index] = product;
    }
  }

  static void syncLocalProducts(Iterable<MockProduct> values) {
    products.removeWhere((item) => item.ownerId != null);
    for (final product in values.toList().reversed) {
      products.removeWhere((item) => item.id == product.id);
      products.insert(0, product);
    }
  }

  static void cacheStores(Iterable<MockStore> remote) {
    for (final store in remote) {
      final index = stores.indexWhere((item) => item.id == store.id);
      if (index < 0)
        stores.add(store);
      else
        stores[index] = store;
    }
  }

  static void syncLocalStores(Iterable<MockStore> values) {
    stores.removeWhere((item) => item.ownerId != null);
    cacheStores(values);
  }

  static List<MockProduct> productsByStore(String storeId) {
    return products.where((product) => product.storeId == storeId).toList();
  }

  static List<MockProduct> get managedProducts {
    return products.where((product) {
      if (!product.isStoreProduct) {
        return true;
      }
      return product.storeId == 's2';
    }).toList();
  }

  static void incrementView(String productId) {
    final index = products.indexWhere((product) => product.id == productId);
    if (index < 0) {
      return;
    }
    final current = products[index];
    products[index] = MockProduct(
      id: current.id,
      title: current.title,
      priceValue: current.priceValue,
      currencyCode: current.currencyCode,
      description: current.description,
      category: current.category,
      city: current.city,
      location: current.location,
      time: current.time,
      image: current.image,
      phone: current.phone,
      viber: current.viber,
      likeCount: current.likeCount,
      viewCount: current.viewCount + 1,
      status: current.status,
      storeId: current.storeId,
      ownerId: current.ownerId,
      images: current.images,
      latitude: current.latitude,
      longitude: current.longitude,
      isLocationVisible: current.isLocationVisible,
    );
  }

  static void setStatus(String productId, ProductStatus status) {
    final index = products.indexWhere((p) => p.id == productId);
    if (index < 0) return;
    final p = products[index];
    products[index] = MockProduct(
      id: p.id,
      title: p.title,
      priceValue: p.priceValue,
      currencyCode: p.currencyCode,
      description: p.description,
      category: p.category,
      city: p.city,
      location: p.location,
      time: p.time,
      image: p.image,
      phone: p.phone,
      viber: p.viber,
      likeCount: p.likeCount,
      viewCount: p.viewCount,
      status: status,
      storeId: p.storeId,
      ownerId: p.ownerId,
      images: p.images,
      latitude: p.latitude,
      longitude: p.longitude,
      isLocationVisible: p.isLocationVisible,
    );
  }

  static void removeProduct(String id) =>
      products.removeWhere((p) => p.id == id);
}

class InteractionStore {
  static final likedIds = ValueNotifier<Set<String>>(<String>{});
  static final viewedIds = ValueNotifier<Set<String>>(<String>{});

  static bool isLiked(String productId) => likedIds.value.contains(productId);

  static bool addLike(String productId) {
    if (isLiked(productId)) {
      return false;
    }
    final next = Set<String>.from(likedIds.value)..add(productId);
    likedIds.value = next;
    SuikaiService.likeListing(productId);
    return true;
  }

  static void trackView(String productId) {
    if (viewedIds.value.contains(productId)) {
      return;
    }
    viewedIds.value = Set<String>.from(viewedIds.value)..add(productId);
    SuikaiService.trackView(productId);
  }

  static Future<void> restore() async {
    likedIds.value = await SuikaiService.fetchLikedIds();
  }
}

Widget persistentImage(
  String source, {
  double? width,
  double? height,
  BoxFit? fit,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  if (source.isNotEmpty && !source.startsWith('http')) {
    return Image.file(
      File(source),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
  return Image.network(
    source,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: errorBuilder,
  );
}

Future<void> launchPhone(String phone) async {
  final normalized = normalizePhone(phone);
  final uri = Uri.parse('tel:$normalized');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('cannot launch phone');
  }
}

Future<void> launchViber(String number) async {
  final normalized = normalizePhone(number);
  final nativeUri = Uri.parse('viber://chat?number=$normalized');
  if (await canLaunchUrl(nativeUri)) {
    await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
    return;
  }
  final webUri = Uri.parse('https://invite.viber.com/?number=$normalized');
  if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
    throw Exception('cannot launch viber');
  }
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: LocalizedText(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class RootScaffold extends StatelessWidget {
  final int selectedIndex;
  final Widget body;

  const RootScaffold({
    super.key,
    required this.selectedIndex,
    required this.body,
  });

  void _onTap(BuildContext context, int index) {
    if (index == selectedIndex) {
      return;
    }
    const routeByIndex = [
      SuikaiRoutes.home,
      SuikaiRoutes.stores,
      SuikaiRoutes.post,
      SuikaiRoutes.map,
      SuikaiRoutes.profile,
    ];
    Navigator.pushNamed(context, routeByIndex[index]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: NavigationBar(
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: selectedIndex,
        indicatorColor: Colors.transparent,
        backgroundColor: Colors.white,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(
              Icons.home_rounded,
              color: AppTheme.orange,
            ),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.storefront_outlined),
            selectedIcon: const Icon(
              Icons.storefront_rounded,
              color: AppTheme.orange,
            ),
            label: l10n.stores,
          ),
          NavigationDestination(
            icon: const _PostIcon(),
            selectedIcon: const _PostIcon(),
            label: '+${l10n.post}',
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map_rounded, color: AppTheme.orange),
            label: l10n.map,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(
              Icons.person_rounded,
              color: AppTheme.orange,
            ),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}

class _SuikaiHeader extends StatelessWidget {
  const _SuikaiHeader();

  Future<void> _select(BuildContext context, String value) async {
    if (value == 'language') {
      await showDialog<void>(
        context: context,
        builder: (_) => const SimpleDialog(
          title: LocalizedText('เปลี่ยนภาษา'),
          children: [
            _LanguageOption(code: 'th', label: 'ไทย'),
            _LanguageOption(code: 'shn', label: 'လိၵ်ႈတႆး'),
            _LanguageOption(code: 'en', label: 'English'),
            _LanguageOption(code: 'my', label: 'မြန်မာ'),
          ],
        ),
      );
      return;
    }
    final route = switch (value) {
      'map' => SuikaiRoutes.map,
      'search' => SuikaiRoutes.search,
      _ => SuikaiRoutes.notifications,
    };
    if (context.mounted) Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 400;
    final buttonSize = compact ? 40.0 : 42.0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  'Suikai',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.orange,
                    fontSize: compact ? 34 : 38,
                    height: .95,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 5),
                LocalizedText(
                  AppLocalizations.of(context).tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: AppLocalizations.of(context).source('เมนู'),
            onSelected: (value) => _select(context, value),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'language',
                child: _HeaderMenuItem(
                  icon: Icons.language_rounded,
                  label: 'เปลี่ยนภาษา',
                ),
              ),
              PopupMenuItem(
                value: 'map',
                child: _HeaderMenuItem(
                  icon: Icons.map_outlined,
                  label: 'แผนที่',
                ),
              ),
              PopupMenuItem(
                value: 'search',
                child: _HeaderMenuItem(
                  icon: Icons.search_rounded,
                  label: 'ค้นหา',
                ),
              ),
              PopupMenuItem(
                value: 'notifications',
                child: _HeaderMenuItem(
                  icon: Icons.notifications_none_rounded,
                  label: 'การแจ้งเตือน',
                ),
              ),
            ],
            icon: Icon(Icons.menu_rounded, color: AppTheme.orange, size: 25),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.orangeSoft,
              fixedSize: Size.square(buttonSize),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderMenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppTheme.orange),
      const SizedBox(width: 12),
      Flexible(
        child: LocalizedText(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _LanguageOption extends StatelessWidget {
  final String code, label;
  const _LanguageOption({required this.code, required this.label});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
    onPressed: () {
      localeController.setLocale(code);
      Navigator.pop(context);
    },
    child: Row(
      children: [
        Icon(
          localeController.locale.languageCode == code
              ? Icons.radio_button_checked
              : Icons.radio_button_off,
          color: AppTheme.orange,
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _filterCurrency = 'THB';
  String _selectedCategory = 'all';
  RangeValues _priceRange = const RangeValues(0, 1);
  double _currencyMaxAmount = 1000000;
  FxSnapshot? _fx;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadListings();
    _loadFx();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeNearby());
  }

  Future<void> _initializeNearby() async {
    try {
      final existing = await SuikaiService.getCurrentPosition(request: false);
      if (existing != null) {
        if (mounted) setState(() => _currentPosition = existing);
        return;
      }
      if (!await SuikaiService.shouldOfferLocationOnLaunch() || !mounted) {
        return;
      }
      await SuikaiService.markLocationIntroSeen();
      if (!mounted) return;
      final allow = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const LocalizedText('สินค้าและร้านใกล้คุณ'),
          content: const LocalizedText(
            'อนุญาตตำแหน่งเพื่อแสดงสินค้าและร้านภายใน 500 กม. คุณยังใช้แอปได้ตามปกติหากไม่อนุญาต',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const LocalizedText('ไม่อนุญาต'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const LocalizedText('อนุญาต'),
            ),
          ],
        ),
      );
      if (allow != true) return;
      final position = await SuikaiService.getCurrentPosition();
      if (mounted && position != null) {
        setState(() => _currentPosition = position);
      }
    } catch (_) {}
  }

  Future<void> _loadFx() async {
    final snapshot = await FxService().latest();
    if (!mounted) return;
    setState(() {
      _fx = snapshot;
      _currencyMaxAmount = _safeCurrencyMax(
        FxService().convert(1000000, 'THB', _filterCurrency, snapshot),
      );
      _priceRange = const RangeValues(0, 1);
    });
  }

  void _changeCurrency(String currency) {
    final snapshot = _fx;
    setState(() {
      _filterCurrency = currency;
      if (snapshot != null) {
        _currencyMaxAmount = _safeCurrencyMax(
          FxService().convert(1000000, 'THB', currency, snapshot),
        );
      }
      _priceRange = const RangeValues(0, 1);
    });
  }

  double _safeCurrencyMax(double value) =>
      value.isFinite && !value.isNaN && value > 0 ? value : 1000000;

  Future<void> _loadListings() async {
    try {
      final data = await SuikaiService.fetchListings();
      final next = <MockProduct>[];
      for (final item in data) {
        final images = item['listing_images'] as List<dynamic>?;
        final stats = item['listing_stats'] as Map<String, dynamic>?;
        final image = images != null && images.isNotEmpty
            ? (images.first as Map<String, dynamic>)['image_url']?.toString() ??
                  ''
            : '';
        final imageUrls = (images ?? const [])
            .map(
              (entry) =>
                  (entry as Map<String, dynamic>)['image_url']?.toString() ??
                  '',
            )
            .where((url) => url.isNotEmpty)
            .toList();
        next.add(
          MockProduct(
            id: item['id'].toString(),
            title: item['title']?.toString() ?? '',
            priceValue: (item['price'] as num?)?.toInt() ?? 0,
            currencyCode: item['currency']?.toString() ?? 'MMK',
            description: item['description']?.toString() ?? '',
            category: item['category']?.toString() ?? 'อื่นๆ',
            city: item['city']?.toString() ?? '',
            location: item['city']?.toString() ?? '',
            time: 'ข้อมูลในเครื่อง',
            image: image.isEmpty
                ? 'https://images.unsplash.com/photo-1515923256482-1c04580b477c?auto=format&fit=crop&w=800&q=80'
                : image,
            phone: item['phone']?.toString() ?? '',
            viber: item['viber_phone']?.toString() ?? '',
            likeCount:
                int.tryParse((stats?['like_count'] ?? '0').toString()) ?? 0,
            viewCount:
                int.tryParse((stats?['view_count'] ?? '0').toString()) ?? 0,
            status: _productStatus(item['status']?.toString()),
            storeId: item['store_id']?.toString(),
            ownerId: item['owner_id']?.toString(),
            images: imageUrls,
            latitude: (item['latitude'] as num?)?.toDouble(),
            longitude: (item['longitude'] as num?)?.toDouble(),
            isLocationVisible: item['is_location_visible'] != false,
          ),
        );
      }
      if (mounted) {
        MockRepo.syncLocalProducts(next);
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final source = MockRepo.feedProducts;
    final items = source.where((product) {
      if (product.status == ProductStatus.sold ||
          product.status == ProductStatus.outOfStock ||
          product.status == ProductStatus.deleted) {
        return false;
      }
      final matchesCategory =
          _selectedCategory == 'all' ||
          SuikaiService.categoryIdForValue('listing', product.category) ==
              _selectedCategory;
      final productPrice = _fx == null
          ? product.priceValue.toDouble()
          : FxService().convert(
              product.priceValue.toDouble(),
              product.currencyCode,
              _filterCurrency,
              _fx!,
            );
      final matchesPrice =
          productPrice.isFinite &&
          productPrice >= _priceRange.start * _currencyMaxAmount &&
          productPrice <= _priceRange.end * _currencyMaxAmount;
      final position = _currentPosition;
      final matchesNearby =
          position == null ||
          !product.isLocationVisible ||
          product.latitude == null ||
          SuikaiService.isWithin500Km(
            position,
            product.latitude,
            product.longitude,
          );
      return matchesCategory && matchesPrice && matchesNearby;
    }).toList();
    return RootScaffold(
      selectedIndex: 0,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _homeHeader(context)),
          SliverToBoxAdapter(child: _priceFilter(context)),
          SliverToBoxAdapter(child: _banner(context)),
          SliverToBoxAdapter(child: _categories(context)),
          SliverToBoxAdapter(child: _sectionTitle(context)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 1280
                    ? 6
                    : width >= 1024
                    ? 5
                    : width >= 760
                    ? 4
                    : 3;
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ProductCard(product: items[index]),
                    childCount: items.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                    childAspectRatio: width >= 1024
                        ? .78
                        : width < 400
                        ? .60
                        : .66,
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 78)),
        ],
      ),
    );
  }

  Widget _homeHeader(BuildContext context) {
    return const _SuikaiHeader();
  }

  Widget _priceFilter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText(
            AppLocalizations.of(context).priceRange,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.border),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      Flexible(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isDense: true,
                            value: _filterCurrency,
                            items: const ['MMK', 'THB', 'USD', 'CNY']
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: LocalizedText(value),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) _changeCurrency(value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LocalizedText(
                          '${formatCurrencyAmount(_priceRange.start * _currencyMaxAmount, _filterCurrency)}–${formatCurrencyAmount(_priceRange.end * _currencyMaxAmount, _filterCurrency)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () =>
                    setState(() => _priceRange = const RangeValues(0, 1)),
                child: Container(
                  width: 54,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 1,
            divisions: 100,
            labels: RangeLabels(
              formatCurrencyAmount(
                _priceRange.start * _currencyMaxAmount,
                _filterCurrency,
              ),
              formatCurrencyAmount(
                _priceRange.end * _currencyMaxAmount,
                _filterCurrency,
              ),
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),
        ],
      ),
    );
  }

  Widget _banner(BuildContext context) {
    return Container(
      height: 190,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE7D6), Color(0xFFFFF7EF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: 0,
            top: 18,
            width: 280,
            child: persistentImage(
              'https://images.unsplash.com/photo-1504215680853-026ed2a45def?auto=format&fit=crop&w=1000&q=85',
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) => const SizedBox(),
            ),
          ),
          Positioned(
            left: 24,
            top: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LocalizedText(
                  AppLocalizations.of(context).advertisement,
                  style: const TextStyle(
                    color: AppTheme.orangeDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 29,
                  ),
                ),
                const SizedBox(height: 4),
                LocalizedText(
                  AppLocalizations.of(context).featuredPromotions,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF675A52),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _categories(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final categories = <(IconData, String, String)>[
      (
        Icons.grid_view_rounded,
        AppLocalizations.of(context).source('ทั้งหมด'),
        'all',
      ),
      for (final category in SuikaiService.categoryRecords('listing'))
        (
          _storeCategoryIcon(category.id),
          category.localizedName(locale),
          category.id,
        ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final label = category.$2;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedCategory = category.$3),
                child: SizedBox(
                  width: 74,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: _selectedCategory == category.$3
                              ? AppTheme.orange
                              : AppTheme.orangeSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.$1,
                          color: _selectedCategory == category.$3
                              ? Colors.white
                              : AppTheme.orange,
                          size: 23,
                        ),
                      ),
                      const SizedBox(height: 7),
                      LocalizedText(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(17, 5, 17, 12),
      child: Row(
        children: [
          Expanded(
            child: LocalizedText(
              AppLocalizations.of(context).latestListings,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          InkWell(
            onTap: () => setState(() {
              _selectedCategory = 'all';
              _priceRange = const RangeValues(0, 1);
            }),
            child: LocalizedText(
              AppLocalizations.of(context).viewAllProducts,
              style: const TextStyle(
                color: AppTheme.orange,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StoreListPage extends StatefulWidget {
  const StoreListPage({super.key});

  @override
  State<StoreListPage> createState() => _StoreListPageState();
}

class _StoreListPageState extends State<StoreListPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      final data = await SuikaiService.fetchStores();
      final next = data.map((item) {
        return MockStore(
          id: item['id'].toString(),
          name: item['name']?.toString() ?? '',
          type: item['category']?.toString() ?? 'ร้านค้า',
          city: item['city']?.toString() ?? '',
          distance: '0 กม.',
          logo: item['logo_url']?.toString() ?? '',
          description: item['description']?.toString() ?? '',
          phone: item['phone']?.toString() ?? '',
          viber: item['viber_phone']?.toString() ?? '',
          hours: '${item['opening_time'] ?? ''}-${item['closing_time'] ?? ''}',
          approved: true,
          searchableProducts: ((item['listings'] as List<dynamic>?) ?? const [])
              .map(
                (listing) =>
                    '${listing['title'] ?? ''} ${listing['category'] ?? ''}',
              )
              .join(' '),
          ownerId: item['owner_id']?.toString(),
          coverUrl: item['cover_url']?.toString(),
          email: item['email']?.toString(),
          latitude: (item['latitude'] as num?)?.toDouble(),
          longitude: (item['longitude'] as num?)?.toDouble(),
        );
      }).toList();
      if (mounted) {
        MockRepo.syncLocalStores(next);
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase().trim();
    final source = MockRepo.approvedStores;
    final stores = source.where((store) {
      final matchesQuery =
          query.isEmpty ||
          store.name.toLowerCase().contains(query) ||
          _categoryLabel(
            context,
            'store',
            store.type,
          ).toLowerCase().contains(query) ||
          store.city.toLowerCase().contains(query);
      final matchesStoreProduct =
          store.searchableProducts.toLowerCase().contains(query) ||
          MockRepo.productsByStore(store.id).any(
            (product) =>
                product.title.toLowerCase().contains(query) ||
                _categoryLabel(
                  context,
                  'listing',
                  product.category,
                ).toLowerCase().contains(query),
          );
      final matchesType =
          _selectedType == 'all' ||
          SuikaiService.categoryIdForValue('store', store.type) ==
              _selectedType;
      return (matchesQuery || (query.isNotEmpty && matchesStoreProduct)) &&
          matchesType;
    }).toList();

    return RootScaffold(
      selectedIndex: 1,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _storeHeader()),
          SliverToBoxAdapter(child: _searchBox()),
          SliverToBoxAdapter(child: _actionSelector()),
          SliverToBoxAdapter(child: _categorySection()),
          SliverToBoxAdapter(child: _recommendedHeader()),
          if (stores.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: LocalizedText(
                    'ไม่พบร้านค้าในหมวดนี้',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 104),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.crossAxisExtent - 10) / 2;
                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _StoreGridCard(store: stores[index]),
                      childCount: stores.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: cardWidth < 180 ? 1.28 : 1.45,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _storeHeader() {
    return const _SuikaiHeader();
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(
            context,
          ).source('ค้นหาร้านค้า หมวดร้าน หรือสินค้าในร้าน'),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded, color: AppTheme.orange),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppTheme.orange),
          ),
        ),
      ),
    );
  }

  Widget _actionSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.025),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 120,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                persistentImage(
                  'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=1200&q=80',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: AppTheme.orangeSoft),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xBB000000), Color(0x22000000)],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      LocalizedText(
                        'พื้นที่โฆษณา',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      LocalizedText(
                        'โปรโมชันและร้านค้าแนะนำบน Suikai',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categorySection() {
    final categories = <_StoreCategoryData>[
      for (final category in SuikaiService.categoryRecords('store'))
        _StoreCategoryData(category.id, _storeCategoryIcon(category.id)),
      const _StoreCategoryData('all', Icons.grid_view_rounded),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: LocalizedText(
                  'หมวดหมู่ร้านค้า',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedType = 'all'),
                child: const LocalizedText('ดูทั้งหมด  ›'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 82,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final item = categories[index];
                final selected = _selectedType == item.id;
                return InkWell(
                  onTap: () => setState(() => _selectedType = item.id),
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 78,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.orange
                                : AppTheme.orangeSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            color: selected ? Colors.white : AppTheme.orange,
                            size: 23,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.id == 'all'
                              ? AppLocalizations.of(context).source('ทั้งหมด')
                              : _categoryLabel(context, 'store', item.id),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 2),
      child: Row(
        children: [
          const Expanded(
            child: LocalizedText(
              'ร้านค้าแนะนำ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _selectedType = 'all';
              _searchController.clear();
            }),
            child: const LocalizedText('ดูทั้งหมด  ›'),
          ),
        ],
      ),
    );
  }
}

class _StoreCategoryData {
  final String id;
  final IconData icon;
  const _StoreCategoryData(this.id, this.icon);
}

class _StoreActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _StoreActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.orangeSoft, AppTheme.orangeSoft.withOpacity(.42)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppTheme.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 27),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LocalizedText(
                    title,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LocalizedText(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 10.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.orange,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

class _StoreGridCard extends StatelessWidget {
  final MockStore store;
  const _StoreGridCard({required this.store});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 400;
    final logoSize = compact ? 46.0 : 56.0;
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        SuikaiRoutes.storeDetail,
        arguments: store.id,
      ),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(compact ? 8 : 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            ClipOval(
              child: persistentImage(
                store.logo,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: logoSize,
                  height: logoSize,
                  color: AppTheme.orangeSoft,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.storefront_rounded,
                    color: AppTheme.orange,
                    size: compact ? 23 : 27,
                  ),
                ),
              ),
            ),
            SizedBox(width: compact ? 7 : 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LocalizedText(
                    store.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _categoryLabel(context, 'store', store.type),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: LocalizedText(
                          store.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFFFA000),
                      ),
                      const SizedBox(width: 2),
                      LocalizedText(
                        store.id.hashCode.isEven ? '4.9' : '4.8',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 5 : 8,
                                vertical: 2,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              side: const BorderSide(color: AppTheme.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            child: const LocalizedText(
                              'ติดตาม',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9.5),
                            ),
                          ),
                        ),
                      ),
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

class StoreDetailPage extends StatefulWidget {
  final String storeId;

  const StoreDetailPage({super.key, required this.storeId});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  Future<void> _manageProduct(MockProduct product, String action) async {
    if (action == 'edit') {
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => EditListingPage(productId: product.id),
        ),
      );
      if (mounted) setState(() {});
      return;
    }
    if (action == 'delete') {
      await SuikaiService.deleteListing(product.id);
      MockRepo.removeProduct(product.id);
    } else {
      final status = _productStatus(action);
      await SuikaiService.updateListing(
        listingId: product.id,
        title: product.title,
        description: product.description,
        city: product.city,
        phone: product.phone,
        viber: product.viber,
        price: product.priceValue.toDouble(),
        currency: product.currencyCode,
        status: action,
      );
      MockRepo.setStatus(product.id, status);
    }
    if (mounted) setState(() {});
  }

  Future<void> _ownerAction(MockStore store, String action) async {
    if (action == 'add') {
      final added = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => PostPage(storeId: store.id)),
      );
      if (added == true && mounted) setState(() {});
    } else if (action == 'edit') {
      await _editStore(context, store);
    } else if (action == 'promote') {
      try {
        await SuikaiService.submitPromotionRequest(store.id);
        if (mounted) showInfo(context, 'ส่งคำขอโปรโมตร้านแล้ว');
      } catch (_) {
        if (mounted) showInfo(context, 'มีคำขอโปรโมตร้านที่รอตรวจสอบอยู่แล้ว');
      }
    }
  }

  Future<void> _editStore(BuildContext context, MockStore store) async {
    final name = TextEditingController(text: store.name);
    final category = TextEditingController(
      text: SuikaiService.categoryIdForValue('store', store.type),
    );
    final selectableCategories = SuikaiService.categoryRecords(
      'store',
      activeOnly: true,
    );
    final currentCategory = SuikaiService.categoryForValue(
      'store',
      category.text,
    );
    if (currentCategory != null &&
        !selectableCategories.any((value) => value.id == currentCategory.id)) {
      selectableCategories.add(currentCategory);
    }
    final description = TextEditingController(text: store.description);
    final phone = TextEditingController(text: store.phone);
    final viber = TextEditingController(text: store.viber);
    final email = TextEditingController(text: store.email ?? '');
    final hours = TextEditingController(text: store.hours);
    final city = TextEditingController(text: store.city);
    SelectedImage? logoImage;
    SelectedImage? coverImage;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const LocalizedText('แก้ไขร้าน'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).source('ชื่อร้าน'),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue:
                      selectableCategories.any(
                        (value) => value.id == category.text,
                      )
                      ? category.text
                      : selectableCategories.firstOrNull?.id,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).source('ประเภทร้าน'),
                  ),
                  items: selectableCategories
                      .map(
                        (value) => DropdownMenuItem(
                          value: value.id,
                          child: Text(
                            value.localizedName(
                              Localizations.localeOf(context).languageCode,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => category.text = value ?? category.text,
                ),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).source('รายละเอียด'),
                  ),
                ),
                TextField(
                  controller: phone,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).source('Phone'),
                  ),
                ),
                TextField(
                  controller: viber,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).source('Viber'),
                  ),
                ),
                TextField(
                  controller: email,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).source('Email'),
                  ),
                ),
                TextField(
                  controller: hours,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).source('เวลาเปิด-ปิด'),
                  ),
                ),
                TextField(
                  controller: city,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).source('Location'),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final value = await SuikaiService.pickImage();
                          if (value != null)
                            setDialogState(() => logoImage = value);
                        },
                        child: LocalizedText(
                          logoImage == null
                              ? 'เปลี่ยน Logo'
                              : 'เลือก Logo แล้ว',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final value = await SuikaiService.pickImage();
                          if (value != null)
                            setDialogState(() => coverImage = value);
                        },
                        child: LocalizedText(
                          coverImage == null
                              ? 'เปลี่ยน Cover'
                              : 'เลือก Cover แล้ว',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const LocalizedText('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.text.trim().isEmpty ||
                    normalizePhone(phone.text).isEmpty ||
                    validateEmail(email.text) != null) {
                  showInfo(context, 'กรุณาตรวจสอบข้อมูลร้าน');
                  return;
                }
                try {
                  await SuikaiService.submitStoreEditRequest(
                    storeId: store.id,
                    values: {
                      'name': name.text.trim(),
                      'category': category.text.trim(),
                      'description': description.text.trim(),
                      'phone': normalizePhone(phone.text),
                      'viber_phone': normalizePhone(viber.text),
                      'email': email.text.trim().isEmpty
                          ? null
                          : email.text.trim(),
                      'city': city.text.trim(),
                      'location': city.text.trim(),
                      'opening_time': hours.text.split('-').first.trim(),
                      'closing_time': hours.text.contains('-')
                          ? hours.text.split('-').last.trim()
                          : hours.text.trim(),
                    },
                    logo: logoImage,
                    cover: coverImage,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  if (context.mounted)
                    showInfo(context, 'ส่งคำร้องแก้ไขร้านให้ Admin แล้ว');
                } catch (_) {
                  if (context.mounted)
                    showInfo(context, 'ส่งคำร้องแก้ไขร้านไม่สำเร็จ');
                }
              },
              child: const LocalizedText('บันทึก'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [
      name,
      category,
      description,
      phone,
      viber,
      email,
      hours,
      city,
    ]) {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MockRepo.storeById(widget.storeId);
    if (store == null) {
      return const _MissingPage(title: 'ไม่พบร้าน');
    }
    final products = MockRepo.productsByStore(store.id);

    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('รายละเอียดร้าน'),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).source('รายงานร้าน'),
            onPressed: () => Navigator.pushNamed(
              context,
              SuikaiRoutes.report,
              arguments: 'store:${store.id}',
            ),
            icon: const Icon(Icons.flag_outlined),
          ),
          if (store.ownerId != null &&
              store.ownerId == SuikaiService.currentUserId)
            PopupMenuButton<String>(
              onSelected: (value) => _ownerAction(store, value),
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'add',
                  child: LocalizedText('เพิ่มสินค้า'),
                ),
                PopupMenuItem(value: 'edit', child: LocalizedText('แก้ไขร้าน')),
                PopupMenuItem(
                  value: 'promote',
                  child: LocalizedText('ขอโปรโมตร้าน'),
                ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: persistentImage(
                  store.logo,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: AppTheme.orangeSoft,
                    alignment: Alignment.center,
                    child: const Icon(Icons.store, color: AppTheme.orange),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      store.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LocalizedText(store.description),
                    const SizedBox(height: 4),
                    LocalizedText(
                      'เวลาเปิดปิด: ${store.hours}',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await launchPhone(store.phone);
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }
                      showInfo(context, 'เปิดโทรศัพท์ไม่ได้');
                    }
                  },
                  icon: const Icon(Icons.phone),
                  label: const LocalizedText('โทร'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await launchViber(store.viber);
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }
                      showInfo(context, 'เปิด Viber ไม่ได้');
                    }
                  },
                  icon: const Icon(Icons.call),
                  label: const LocalizedText('Viber'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const LocalizedText(
            'สินค้าของร้าน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          for (final product in products)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  SuikaiRoutes.productDetail,
                  arguments: product.id,
                ),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: persistentImage(
                          product.image,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, stackTrace) => Container(
                            width: 72,
                            height: 72,
                            color: const Color(0xFFF2F2F2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LocalizedText(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LocalizedText(
                              product.price,
                              style: const TextStyle(
                                color: AppTheme.orange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _cardStatusMarker(product.status),
                            ),
                          ],
                        ),
                      ),
                      if (store.ownerId == SuikaiService.currentUserId)
                        PopupMenuButton<String>(
                          onSelected: (value) => _manageProduct(product, value),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: LocalizedText('แก้ไข'),
                            ),
                            for (final status in const [
                              ProductStatus.available,
                              ProductStatus.outOfStock,
                              ProductStatus.deleted,
                            ])
                              PopupMenuItem(
                                value: status.name,
                                child: Row(
                                  children: [
                                    _statusDot(status),
                                    const SizedBox(width: 8),
                                    LocalizedText(
                                      _statusLabel(context, status),
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: LocalizedText('ลบ'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class EditListingPage extends StatefulWidget {
  final String productId;
  const EditListingPage({super.key, required this.productId});

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  late final MockProduct? _original;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _viber;
  final List<_ProductImageDraft> _images = [];
  late String _currency;
  late ProductStatus _status;
  String? _category;
  bool _saving = false;
  late bool _isLocationVisible;

  @override
  void initState() {
    super.initState();
    _original = MockRepo.productById(widget.productId);
    final product = _original;
    _name = TextEditingController(text: product?.title ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _price = TextEditingController(
      text: product == null ? '' : product.priceValue.toString(),
    );
    _city = TextEditingController(text: product?.city ?? '');
    _phone = TextEditingController(text: product?.phone ?? '');
    _viber = TextEditingController(text: product?.viber ?? '');
    _currency = product?.currencyCode ?? 'MMK';
    _status = product?.status ?? ProductStatus.available;
    _isLocationVisible = product?.isLocationVisible ?? true;
    final matchedCategory = product == null
        ? null
        : SuikaiService.categoryForValue('listing', product.category);
    _category = matchedCategory?.id;
    if (product != null) {
      _images.addAll(
        product.imageUrls
            .where((source) => source.isNotEmpty)
            .take(5)
            .map(_ProductImageDraft.existing),
      );
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _description,
      _price,
      _city,
      _phone,
      _viber,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage({int? replaceIndex}) async {
    if (replaceIndex == null && _images.length >= 5) return;
    final selected = await SuikaiService.pickImage();
    if (!mounted || selected == null) return;
    setState(() {
      final draft = _ProductImageDraft.selected(selected);
      if (replaceIndex == null) {
        _images.add(draft);
      } else {
        _images[replaceIndex] = draft;
      }
    });
  }

  List<CategoryRecord> _selectableCategories() {
    final categories = SuikaiService.categoryRecords(
      'listing',
      activeOnly: true,
    );
    final current = _category == null
        ? null
        : SuikaiService.categoryForValue('listing', _category!);
    if (current != null &&
        !categories.any((category) => category.id == current.id)) {
      categories.add(current);
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final product = _original;
    if (product == null) {
      return const _MissingPage(title: 'ไม่พบสินค้า');
    }
    final l10n = AppLocalizations.of(context);
    final categories = _selectableCategories();
    return Scaffold(
      appBar: AppBar(title: const LocalizedText('แก้ไขสินค้า')),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            _editSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.productImages,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        _images.length.toString() + '/5',
                        style: const TextStyle(
                          color: AppTheme.orange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    l10n.firstImageIsMain,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth < 300 ? 2 : 3;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 5,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (context, index) =>
                            _imageSlot(index, l10n),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _editSection(
              title: 'ข้อมูลสินค้า',
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: l10n.productNameRequired,
                    ),
                    validator: (value) => normalizeText(value).isEmpty
                        ? l10n.productNameValidation
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _description,
                    minLines: 4,
                    maxLines: 7,
                    decoration: InputDecoration(
                      labelText: l10n.productDescriptionOptional,
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    hint: const LocalizedText('หมวดหมู่'),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      ).source('หมวดหมู่'),
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(
                              category.localizedName(
                                Localizations.localeOf(context).languageCode,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _category = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _editSection(
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _price,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: l10n.priceRequired,
                          ),
                          validator: (value) {
                            final amount = parsePriceValue(value);
                            return amount == null || amount < 0
                                ? l10n.priceValidation
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 104,
                        child: DropdownButtonFormField<String>(
                          initialValue: _currency,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l10n.currency),
                          items: const ['MMK', 'THB', 'USD', 'CNY']
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _currency = value ?? _currency),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ProductStatus>(
                    initialValue: _status,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l10n.productStatus),
                    items:
                        (product.isStoreProduct
                                ? const [
                                    ProductStatus.available,
                                    ProductStatus.outOfStock,
                                    ProductStatus.deleted,
                                  ]
                                : const [
                                    ProductStatus.available,
                                    ProductStatus.reserved,
                                    ProductStatus.sold,
                                  ])
                            .map(
                              (status) => DropdownMenuItem(
                                value: status,
                                child: Row(
                                  children: [
                                    _statusDot(status),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: LocalizedText(
                                        _statusLabel(context, status),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => _status = value ?? _status),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _editSection(
              title: 'ข้อมูลเพิ่มเติม',
              child: Column(
                children: [
                  TextFormField(
                    controller: _city,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      ).source('ตำแหน่ง/เมือง'),
                    ),
                  ),
                  if (!product.isStoreProduct) ...[
                    const SizedBox(height: 10),
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _isLocationVisible,
                        title: const LocalizedText('เปิดเผยตำแหน่งสินค้า'),
                        subtitle: const LocalizedText(
                          'ใช้เพื่อแสดงสินค้าใกล้เคียง โดยไม่แสดงพิกัดตัวเลข',
                        ),
                        onChanged: (value) =>
                            setState(() => _isLocationVisible = value),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      ).source('เบอร์ติดต่อ'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _viber,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Viber'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_rounded),
          label: Text(_saving ? l10n.saving : l10n.save),
        ),
      ),
    );
  }

  Widget _editSection({String? title, required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          LocalizedText(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
        ],
        child,
      ],
    ),
  );

  Widget _imageSlot(int index, AppLocalizations l10n) {
    final hasImage = index < _images.length;
    return Material(
      color: AppTheme.orangeSoft,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasImage
            ? () => _pickImage(replaceIndex: index)
            : index == _images.length
            ? _pickImage
            : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              _images[index].selectedImage == null
                  ? persistentImage(
                      _images[index].existingPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    )
                  : Image.memory(
                      _images[index].selectedImage!.bytes,
                      fit: BoxFit.cover,
                    )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    index == _images.length
                        ? Icons.add_a_photo_outlined
                        : Icons.image_outlined,
                    color: index == _images.length
                        ? AppTheme.orange
                        : AppTheme.textMuted,
                  ),
                  if (index == _images.length)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        l10n.addImage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            if (hasImage)
              Positioned(
                right: 4,
                top: 4,
                child: IconButton.filled(
                  visualDensity: VisualDensity.compact,
                  tooltip: AppLocalizations.of(context).source('ลบ'),
                  onPressed: () => setState(() => _images.removeAt(index)),
                  icon: const Icon(Icons.close, size: 16),
                ),
              ),
            if (index == 0 && hasImage)
              Positioned(
                left: 5,
                bottom: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.mainImage,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final product = _original;
    final l10n = AppLocalizations.of(context);
    if (product == null || !_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      showInfo(context, l10n.imageValidation);
      return;
    }
    setState(() => _saving = true);
    try {
      final drafts = [..._images];
      final persisted = await SuikaiService.persistSelectedImages(
        drafts
            .where((image) => image.selectedImage != null)
            .map((image) => image.selectedImage!)
            .toList(),
        listingId: product.id,
      );
      var selectedIndex = 0;
      final finalImages = [
        for (final image in drafts)
          image.existingPath ?? persisted[selectedIndex++],
      ];
      final amount = parsePriceValue(_price.text)!;
      final category = _category ?? product.category;
      Position? position;
      if (!product.isStoreProduct &&
          _isLocationVisible &&
          product.latitude == null) {
        position = await SuikaiService.getCurrentPosition();
        if (position == null && mounted) {
          showInfo(context, 'บันทึกประกาศโดยไม่มีตำแหน่ง GPS');
        }
      }
      await SuikaiService.updateListing(
        listingId: product.id,
        title: normalizeText(_name.text),
        description: normalizeText(_description.text),
        city: normalizeText(_city.text),
        phone: normalizePhone(_phone.text),
        viber: normalizePhone(_viber.text),
        price: amount.toDouble(),
        currency: _currency,
        status: _status.name,
        category: category,
        images: finalImages,
        latitude: position?.latitude,
        longitude: position?.longitude,
        isLocationVisible: product.isStoreProduct
            ? product.isLocationVisible
            : _isLocationVisible,
      );
      MockRepo.cacheProducts([
        MockProduct(
          id: product.id,
          title: normalizeText(_name.text),
          priceValue: amount,
          currencyCode: _currency,
          description: normalizeText(_description.text),
          category: category,
          city: normalizeText(_city.text),
          location: normalizeText(_city.text),
          time: product.time,
          image: finalImages.first,
          phone: normalizePhone(_phone.text),
          viber: normalizePhone(_viber.text),
          likeCount: product.likeCount,
          viewCount: product.viewCount,
          status: _status,
          storeId: product.storeId,
          ownerId: product.ownerId,
          images: finalImages,
          latitude: _isLocationVisible
              ? (position?.latitude ?? product.latitude)
              : null,
          longitude: _isLocationVisible
              ? (position?.longitude ?? product.longitude)
              : null,
          isLocationVisible: product.isStoreProduct
              ? product.isLocationVisible
              : _isLocationVisible,
        ),
      ]);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showInfo(context, l10n.saveFailed);
    }
  }
}

class _ProductImageDraft {
  final String? existingPath;
  final SelectedImage? selectedImage;
  const _ProductImageDraft._({this.existingPath, this.selectedImage});
  const _ProductImageDraft.existing(String path) : this._(existingPath: path);
  const _ProductImageDraft.selected(SelectedImage image)
    : this._(selectedImage: image);
}

class PostPage extends StatefulWidget {
  final bool startGeneral;
  final String? storeId;
  const PostPage({super.key, this.startGeneral = false, this.storeId});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final _formKey = GlobalKey<FormState>();
  bool _showGeneralWizard = false;
  int _step = 0;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _detailsController = TextEditingController();
  final _phoneController = TextEditingController(text: '09 9999 9999');
  final _viberController = TextEditingController(text: '09 8888 8888');
  final _locationNoteController = TextEditingController();

  String _category = '';
  String _currency = 'MMK';
  String _condition = 'มือหนึ่ง';
  bool _negotiable = false;
  bool _isLocationVisible = true;
  bool _submitting = false;
  Position? _listingPosition;
  ProductStatus _listingStatus = ProductStatus.available;
  final List<SelectedImage> _selectedImages = [];
  String _address = 'บ้านน้ำจ๋าง, เมืองน้ำจ๋าง, รัฐฉาน\nใกล้ ตลาดสดน้ำจ๋าง';

  @override
  void initState() {
    super.initState();
    _showGeneralWizard = widget.startGeneral || widget.storeId != null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _detailsController.dispose();
    _phoneController.dispose();
    _viberController.dispose();
    _locationNoteController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      final price = parsePriceValue(_priceController.text);
      if (price == null || price < 0) {
        showInfo(context, 'กรุณากรอกราคาที่ถูกต้อง');
        return;
      }
      final phone = normalizePhone(_phoneController.text);
      if (phone.isEmpty) {
        showInfo(context, 'กรุณากรอกเบอร์โทร');
        return;
      }
      if (_category.isEmpty) {
        showInfo(context, 'กรุณาเลือกหมวดหมู่สินค้า');
        return;
      }
    }
    if (_step == 1 && _selectedImages.isEmpty) {
      showInfo(context, 'กรุณาเพิ่มรูปสินค้าอย่างน้อย 1 รูป');
      return;
    }
    if (_step < 3) {
      setState(() => _step++);
    }
  }

  Future<void> _captureListingLocation({bool notify = true}) async {
    try {
      final position = await SuikaiService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _listingPosition = position);
      if (notify) {
        showInfo(
          context,
          position == null
              ? 'ไม่สามารถใช้ตำแหน่ง GPS ได้'
              : 'บันทึกตำแหน่งสำหรับการค้นหาใกล้เคียงแล้ว',
        );
      }
    } catch (_) {
      if (mounted && notify) showInfo(context, 'ไม่สามารถใช้ตำแหน่ง GPS ได้');
    }
  }

  Future<void> _pickListingImage({int? replaceIndex}) async {
    final limit = widget.storeId == null ? 8 : 5;
    if (replaceIndex == null && _selectedImages.length >= limit) return;
    try {
      final image = await SuikaiService.pickImage();
      if (!mounted || image == null) return;
      setState(() {
        if (replaceIndex == null) {
          _selectedImages.add(image);
        } else {
          _selectedImages[replaceIndex] = image;
        }
      });
    } catch (_) {
      if (mounted) showInfo(context, 'ไม่สามารถเลือกรูปได้ กรุณาลองใหม่');
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      if (widget.startGeneral) {
        Navigator.pop(context);
      } else {
        setState(() => _showGeneralWizard = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.storeId != null) return _buildStoreProductForm();
    if (!_showGeneralWizard) return _buildTypeChooser();
    return _buildWizard();
  }

  Widget _buildStoreProductForm() {
    final l10n = AppLocalizations.of(context);
    final statuses = const [
      ProductStatus.available,
      ProductStatus.outOfStock,
      ProductStatus.deleted,
    ];
    return Scaffold(
      appBar: AppBar(title: LocalizedText(l10n.addStoreProduct)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            Row(
              children: [
                Expanded(
                  child: LocalizedText(
                    l10n.productImages,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                LocalizedText(
                  '${_selectedImages.length}/5',
                  style: const TextStyle(
                    color: AppTheme.orange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LocalizedText(
              l10n.firstImageIsMain,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final hasImage = index < _selectedImages.length;
                return Material(
                  color: AppTheme.orangeSoft,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: hasImage
                        ? () => _pickListingImage(replaceIndex: index)
                        : index == _selectedImages.length
                        ? _pickListingImage
                        : null,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasImage)
                          Image.memory(
                            _selectedImages[index].bytes,
                            fit: BoxFit.cover,
                          )
                        else
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                index == _selectedImages.length
                                    ? Icons.add_a_photo_outlined
                                    : Icons.image_outlined,
                                color: index == _selectedImages.length
                                    ? AppTheme.orange
                                    : AppTheme.textMuted,
                              ),
                              if (index == _selectedImages.length)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: LocalizedText(
                                    l10n.addImage,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                            ],
                          ),
                        if (hasImage)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: IconButton.filled(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(
                                () => _selectedImages.removeAt(index),
                              ),
                              icon: const Icon(Icons.close, size: 16),
                            ),
                          ),
                        if (index == 0 && hasImage)
                          Positioned(
                            left: 5,
                            bottom: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.orange,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: LocalizedText(
                                l10n.mainImage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.productNameRequired),
              validator: (value) => normalizeText(value).isEmpty
                  ? l10n.productNameValidation
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.productDescriptionOptional,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.priceRequired),
                    validator: (value) {
                      final price = parsePriceValue(value);
                      return price == null || price < 0
                          ? l10n.priceValidation
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 92,
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: InputDecoration(labelText: l10n.currency),
                    items: const ['MMK', 'THB', 'USD', 'CNY']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: LocalizedText(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _currency = value ?? _currency),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductStatus>(
              initialValue: _listingStatus,
              decoration: InputDecoration(labelText: l10n.productStatus),
              items: statuses
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _statusDot(status),
                          const SizedBox(width: 8),
                          LocalizedText(_statusLabel(context, status)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _listingStatus = value ?? _listingStatus),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton.icon(
          onPressed: _submitting ? null : _saveStoreProduct,
          icon: const Icon(Icons.save_rounded),
          label: LocalizedText(_submitting ? l10n.saving : l10n.save),
        ),
      ),
    );
  }

  Future<void> _saveStoreProduct() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      showInfo(context, l10n.imageValidation);
      return;
    }
    setState(() => _submitting = true);
    try {
      final price = parsePriceValue(_priceController.text)!;
      final listing = await SuikaiService.createListing(
        title: normalizeText(_nameController.text),
        description: normalizeText(_detailsController.text),
        category: 'store-product',
        city: '',
        phone: normalizePhone(_phoneController.text),
        viber: normalizePhone(_viberController.text),
        price: price.toDouble(),
        currency: _currency,
        listingType: 'store',
        storeId: widget.storeId,
        status: _listingStatus.name,
        images: _selectedImages,
      );
      if (listing != null) {
        MockRepo.products.insert(
          0,
          MockProduct(
            id: '${listing['id']}',
            title: normalizeText(_nameController.text),
            priceValue: price,
            currencyCode: _currency,
            description: normalizeText(_detailsController.text),
            category: 'store-product',
            city: '',
            location: '',
            time: l10n.justPosted,
            image: (listing['images'] as List).first.toString(),
            phone: normalizePhone(_phoneController.text),
            viber: normalizePhone(_viberController.text),
            likeCount: 0,
            viewCount: 0,
            status: _listingStatus,
            storeId: widget.storeId,
            ownerId: SuikaiService.currentUserId,
            images: List<String>.from(listing['images'] ?? const []),
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        showInfo(context, l10n.saveFailed);
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildTypeChooser() {
    return RootScaffold(
      selectedIndex: 2,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
          children: [
            const _SuikaiHeader(),
            const SizedBox(height: 52),
            const LocalizedText(
              'ประกาศขาย',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const LocalizedText(
              'เลือกประเภทการประกาศที่คุณต้องการ',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 30),
            _sellTypeCard(
              key: const ValueKey('general-listing-choice'),
              title: 'เพิ่มสินค้าทั่วไป',
              subtitle: 'ลงประกาศขายสินค้าของคุณได้ทันที',
              icon: Icons.add_shopping_cart_rounded,
              onTap: () => setState(() {
                _showGeneralWizard = true;
                _step = 0;
              }),
            ),
            const SizedBox(height: 18),
            _sellTypeCard(
              key: const ValueKey('open-store-choice'),
              title: 'เปิดร้าน',
              subtitle: 'สร้างหน้าร้านสำหรับขายสินค้าหลายรายการ',
              icon: Icons.storefront_rounded,
              onTap: () => Navigator.pushNamed(context, SuikaiRoutes.openShop),
            ),
            const SizedBox(height: 36),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFFFF1E8),
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: AppTheme.orange,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LocalizedText(
                          'ปลอดภัย มั่นใจ ได้ทุกการซื้อขาย',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 3),
                        LocalizedText(
                          'เรามีระบบตรวจสอบและรายงาน เพื่อให้คุณซื้อขายได้อย่างปลอดภัย',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.shield_outlined,
                    color: Color(0xFFFFD8C0),
                    size: 44,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWizard() {
    return PopScope(
      canPop: _step == 0 && widget.startGeneral,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _wizardHeader(),
                Expanded(
                  child: IndexedStack(
                    index: _step,
                    children: [
                      _stepBasic(),
                      _stepPhotos(),
                      _stepLocation(),
                      _stepConfirm(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _wizardHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Column(
        children: [
          Row(
            children: [
              _roundBackButton(_back),
              const Expanded(
                child: LocalizedText(
                  'ลงขายสินค้าทั่วไป',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => showInfo(context, 'บันทึกฉบับร่างแล้ว (mock)'),
                child: const LocalizedText(
                  'บันทึกฉบับร่าง',
                  style: TextStyle(
                    color: AppTheme.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _stepIndicator(),
        ],
      ),
    );
  }

  Widget _stepIndicator() {
    const labels = ['ข้อมูลสินค้า', 'รูปภาพ', 'ตำแหน่ง', 'ยืนยันการลงขาย'];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(labels.length, (i) {
        final active = i <= _step;
        final current = i == _step;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: active ? AppTheme.orange : AppTheme.border,
                      ),
                    ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: current ? AppTheme.orange : Colors.white,
                      border: Border.all(
                        color: active
                            ? AppTheme.orange
                            : const Color(0xFFBFC1C5),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: i < _step
                        ? const Icon(
                            Icons.check,
                            size: 18,
                            color: AppTheme.orange,
                          )
                        : LocalizedText(
                            '${i + 1}',
                            style: TextStyle(
                              color: current
                                  ? Colors.white
                                  : (active
                                        ? AppTheme.orange
                                        : AppTheme.textMuted),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  if (i < labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < _step ? AppTheme.orange : AppTheme.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 7),
              LocalizedText(
                labels[i],
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  color: current ? AppTheme.orange : AppTheme.textMuted,
                  fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _stepBasic() {
    return _stepScroll([
      _sectionCard(
        title: 'ข้อมูลพื้นฐาน',
        children: [
          const _FieldLabel('หมวดหมู่'),
          DropdownButtonFormField<String>(
            value: _category.isEmpty ? null : _category,
            hint: const LocalizedText('เลือกหมวดหมู่สินค้า'),
            decoration: _inputDecoration(),
            items: SuikaiService.categoryRecords('listing', activeOnly: true)
                .map(
                  (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(
                      category.localizedName(
                        Localizations.localeOf(context).languageCode,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('ชื่อสินค้า *'),
          TextFormField(
            controller: _nameController,
            maxLength: 100,
            decoration: _inputDecoration(
              hint: 'ใส่ชื่อสินค้าที่ต้องการขาย',
              counter: true,
            ),
            validator: (value) => normalizeText(value).isEmpty
                ? AppLocalizations.of(context).source('กรุณาใส่ชื่อสินค้า')
                : null,
          ),
          const SizedBox(height: 10),
          const _FieldLabel('ราคา *'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(hint: 'ระบุราคา'),
                  validator: (value) {
                    final price = parsePriceValue(value);
                    return price != null && price >= 0
                        ? null
                        : AppLocalizations.of(
                            context,
                          ).source('กรุณากรอกราคาที่ถูกต้อง');
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 88,
                child: DropdownButtonFormField<String>(
                  initialValue: _currency,
                  decoration: _inputDecoration(),
                  items: const ['MMK', 'THB', 'USD', 'CNY']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: LocalizedText(value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _currency = value ?? _currency),
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: _negotiable,
                activeColor: AppTheme.orange,
                onChanged: (v) => setState(() => _negotiable = v),
              ),
              const LocalizedText(
                'ต่อรองได้',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      _sectionCard(
        title: 'สภาพสินค้า',
        children: [
          Row(
            children: [
              _conditionButton('มือหนึ่ง', Icons.inventory_2_outlined),
              const SizedBox(width: 8),
              _conditionButton('มือสอง\nสภาพดี', Icons.thumb_up_alt_outlined),
              const SizedBox(width: 8),
              _conditionButton(
                'มือสอง\nสภาพปานกลาง',
                Icons.sentiment_neutral_outlined,
              ),
              const SizedBox(width: 8),
              _conditionButton('มือสอง\nต้องซ่อม', Icons.build_outlined),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      _sectionCard(
        title: 'รายละเอียดสินค้า',
        children: [
          TextFormField(
            controller: _detailsController,
            maxLines: 5,
            maxLength: 1000,
            decoration: _inputDecoration(
              hint:
                  'อธิบายรายละเอียดสินค้า เช่น สภาพการใช้งาน จุดเด่น อุปกรณ์ที่มีให้ เป็นต้น',
              counter: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _sectionCard(
        title: 'ข้อมูลการติดต่อ',
        children: [
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              hint: 'เบอร์โทรศัพท์',
              prefixIcon: Icons.phone_outlined,
            ),
            validator: (value) => validatePhone(value),
          ),
          const SizedBox(height: 12),
          const LocalizedText(
            'เบอร์โทรที่จะแสดงให้ผู้สนใจติดต่อคุณ',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _viberController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              hint: 'เบอร์โทร Viber',
              prefixIcon: Icons.phone_in_talk_outlined,
            ),
          ),
          const SizedBox(height: 12),
          const LocalizedText(
            'เบอร์ Viber ที่จะแสดงให้ผู้สนใจติดต่อคุณ',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _primaryButton('ถัดไป', _next),
    ]);
  }

  Widget _stepPhotos() {
    return _stepScroll([
      _sectionCard(
        title: 'รูปภาพสินค้า',
        children: [
          const LocalizedText(
            'เพิ่มรูปสินค้าได้สูงสุด 8 รูป โดยรูปแรกจะเป็นรูปหน้าปก',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),
          InkWell(
            onTap: _pickListingImage,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 210,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD3B8)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: Color(0xFFFFE7D8),
                    child: Icon(
                      Icons.add_a_photo_outlined,
                      color: AppTheme.orange,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LocalizedText(
                    _selectedImages.isEmpty
                        ? 'เพิ่มรูปสินค้า'
                        : 'เพิ่มรูปอีก (${_selectedImages.length}/8)',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const LocalizedText(
                    'แตะเพื่อเลือกจากคลังรูป',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _selectedImages[i].bytes,
                      width: 78,
                      height: 78,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: InkWell(
                      onTap: () => setState(() => _selectedImages.removeAt(i)),
                      child: const CircleAvatar(
                        radius: 11,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _bottomPair(backText: 'ย้อนกลับ', nextText: 'ถัดไป'),
    ]);
  }

  Widget _stepDetails() {
    return _stepScroll([
      _sectionCard(
        title: 'รายละเอียดเพิ่มเติม',
        children: [
          const _FieldLabel('ยี่ห้อ / แบรนด์ (ไม่บังคับ)'),
          TextField(
            decoration: _inputDecoration(
              hint: 'เช่น Apple, Samsung, Toyota...',
            ),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('รุ่น (ไม่บังคับ)'),
          TextField(decoration: _inputDecoration(hint: 'ระบุรุ่นสินค้า')),
          const SizedBox(height: 18),
          const _FieldLabel('ปีผลิต (ไม่บังคับ)'),
          TextField(
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(hint: 'เช่น 2024'),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('สี (ไม่บังคับ)'),
          TextField(decoration: _inputDecoration(hint: 'ระบุสีสินค้า')),
        ],
      ),
      const SizedBox(height: 16),
      _sectionCard(
        title: 'ข้อมูลเพิ่มเติม',
        children: const [
          _InfoRow(
            icon: Icons.verified_outlined,
            title: 'ตรวจสอบข้อมูลก่อนลงขาย',
            subtitle: 'ข้อมูลที่ครบถ้วนช่วยให้ผู้ซื้อเข้าใจสินค้าได้ง่ายขึ้น',
          ),
        ],
      ),
      const SizedBox(height: 18),
      _bottomPair(backText: 'ย้อนกลับ', nextText: 'ถัดไป'),
    ]);
  }

  Widget _stepLocation() {
    return _stepScroll([
      _sectionCard(
        title: 'ตำแหน่งสินค้า',
        children: [
          if (widget.storeId == null) ...[
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isLocationVisible,
                title: const LocalizedText('เปิดเผยตำแหน่งสินค้า'),
                subtitle: const LocalizedText(
                  'ใช้เพื่อแสดงสินค้าใกล้เคียง โดยไม่แสดงพิกัดตัวเลข',
                ),
                onChanged: (value) => setState(() {
                  _isLocationVisible = value;
                  if (!value) _listingPosition = null;
                }),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLocationVisible
                      ? _captureListingLocation
                      : null,
                  icon: const Icon(Icons.location_on_rounded),
                  label: const LocalizedText('ตำแหน่งปัจจุบัน'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.orange,
                    side: const BorderSide(color: AppTheme.orange),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      showInfo(context, 'เลือกตำแหน่งบนแผนที่ (mock)'),
                  icon: const Icon(Icons.map_outlined),
                  label: const LocalizedText('เลือกบนแผนที่'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.border),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 285,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF2F1EC),
              border: Border.all(color: AppTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _MiniLocationMapPainter()),
                ),
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 62,
                        color: AppTheme.orange,
                      ),
                      CircleAvatar(radius: 7, backgroundColor: Colors.blue),
                    ],
                  ),
                ),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Material(
                    color: Colors.white,
                    elevation: 2,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: null,
                      icon: Icon(
                        Icons.my_location_rounded,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('ที่อยู่สินค้า'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LocalizedText(
                    _address,
                    style: const TextStyle(height: 1.55),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const LocalizedText(
                    'แก้ไข',
                    style: TextStyle(color: AppTheme.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('รายละเอียดตำแหน่ง (ไม่บังคับ)'),
          TextField(
            controller: _locationNoteController,
            maxLength: 200,
            maxLines: 4,
            decoration: _inputDecoration(
              hint: 'เช่น ใกล้ 7-11, ตรงข้ามโรงเรียน...',
              counter: true,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        'ข้อมูลตำแหน่งจะถูกเก็บเป็นความลับ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 3),
                      LocalizedText(
                        'ตำแหน่งที่แสดงจะเป็นเพียงตำแหน่งโดยประมาณ เพื่อความปลอดภัยของคุณ',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      _bottomPair(backText: 'ย้อนกลับ', nextText: 'ถัดไป'),
    ]);
  }

  Widget _stepConfirm() {
    final title = _nameController.text.trim().isEmpty
        ? 'iPhone 13 Pro Max 256GB'
        : _nameController.text.trim();
    final parsedPrice = parsePriceValue(_priceController.text) ?? 0;
    final price = formatPrice(parsedPrice, _currency);
    return _stepScroll([
      _sectionCard(
        title: 'ยืนยันการลงขาย',
        subtitle: 'ตรวจสอบข้อมูลให้ถูกต้องก่อนยืนยันการลงขาย',
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 150,
                  height: 150,
                  color: const Color(0xFFF2F2F2),
                  child: _selectedImages.isEmpty
                      ? const Icon(
                          Icons.phone_iphone_rounded,
                          size: 76,
                          color: AppTheme.textMuted,
                        )
                      : Image.memory(
                          _selectedImages.first.bytes,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LocalizedText(
                      price,
                      style: const TextStyle(
                        fontSize: 22,
                        color: AppTheme.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LocalizedText(
                      '☎  มือสอง สภาพดี',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '◈  ' +
                          (_category.isEmpty
                              ? '-'
                              : _categoryLabel(context, 'listing', _category)),
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
              ),
            ],
          ),
          const Divider(height: 34),
          _confirmSection(
            'รายละเอียดสินค้า',
            _detailsController.text.trim().isEmpty
                ? 'เครื่องสภาพดีมาก ไม่มีรอยหนัก ใช้งานปกติทุกฟังก์ชัน\nแบตเตอรี่ 86% อุปกรณ์ครบกล่อง'
                : _detailsController.text.trim(),
          ),
          const Divider(height: 30),
          _confirmSection(
            'ตำแหน่งสินค้า',
            _address,
            icon: Icons.location_on_outlined,
          ),
          const Divider(height: 30),
          const LocalizedText(
            'ข้อมูลการติดต่อ',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          _contactRow(
            Icons.phone_outlined,
            'เบอร์โทรศัพท์',
            _phoneController.text,
          ),
          const SizedBox(height: 14),
          _contactRow(
            Icons.phone_in_talk_outlined,
            'เบอร์โทร Viber',
            _viberController.text,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppTheme.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LocalizedText(
                        'เมื่อยืนยันการลงขาย',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 5),
                      LocalizedText(
                        '• สินค้าของคุณจะถูกเผยแพร่ให้ผู้ใช้งานคนอื่นเห็น\n• คุณสามารถปิดการขายหรือแก้ไขข้อมูลได้ในภายหลัง',
                        style: TextStyle(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(child: _outlineButton('ย้อนกลับ', _back)),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: _primaryButton(
              _submitting ? 'กำลังบันทึก...' : 'ยืนยันการลงขาย',
              _submitting
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      final price = parsePriceValue(_priceController.text);
                      if (price == null || price < 0) {
                        showInfo(context, 'กรุณากรอกราคาที่ถูกต้อง');
                        return;
                      }
                      final phone = normalizePhone(_phoneController.text);
                      if (phone.isEmpty) {
                        showInfo(context, 'กรุณากรอกเบอร์โทร');
                        return;
                      }
                      if (_selectedImages.isEmpty) {
                        showInfo(context, 'กรุณาเพิ่มรูปสินค้าอย่างน้อย 1 รูป');
                        return;
                      }
                      setState(() => _submitting = true);
                      try {
                        if (widget.storeId == null &&
                            _isLocationVisible &&
                            _listingPosition == null) {
                          await _captureListingLocation(notify: false);
                        }
                        final listing = await SuikaiService.createListing(
                          title: normalizeText(_nameController.text),
                          description: normalizeText(_detailsController.text),
                          category: _category,
                          city: 'เมืองนาง',
                          phone: phone,
                          viber: normalizePhone(_viberController.text),
                          price: price.toDouble(),
                          currency: _currency,
                          listingType: widget.storeId == null
                              ? 'general'
                              : 'store',
                          storeId: widget.storeId,
                          images: _selectedImages,
                          latitude: _listingPosition?.latitude,
                          longitude: _listingPosition?.longitude,
                          isLocationVisible:
                              widget.storeId != null || _isLocationVisible,
                        );
                        if (listing != null) {
                          MockRepo.products.insert(
                            0,
                            MockProduct(
                              id:
                                  listing['id']?.toString() ??
                                  'mock-${DateTime.now().millisecondsSinceEpoch}',
                              title: normalizeText(_nameController.text),
                              priceValue: price,
                              currencyCode: _currency,
                              description: normalizeText(
                                _detailsController.text,
                              ),
                              category: _category,
                              city: 'เมืองนาง',
                              location: _address,
                              time: 'เพิ่งลงประกาศ',
                              image:
                                  (listing['images'] as List?)?.firstOrNull
                                      ?.toString() ??
                                  'https://images.unsplash.com/photo-1515923256482-1c04580b477c?auto=format&fit=crop&w=800&q=80',
                              phone: phone,
                              viber: normalizePhone(_viberController.text),
                              likeCount: 0,
                              viewCount: 0,
                              status: ProductStatus.available,
                              storeId: widget.storeId,
                              ownerId: SuikaiService.currentUserId,
                              images: List<String>.from(
                                listing['images'] ?? const [],
                              ),
                              latitude: (listing['latitude'] as num?)
                                  ?.toDouble(),
                              longitude: (listing['longitude'] as num?)
                                  ?.toDouble(),
                              isLocationVisible:
                                  listing['is_location_visible'] != false,
                            ),
                          );
                        }
                        if (!context.mounted) {
                          return;
                        }
                        showInfo(context, 'ลงประกาศสำเร็จ');
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context, true);
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            SuikaiRoutes.home,
                          );
                        }
                      } catch (_) {
                        if (!context.mounted) {
                          return;
                        }
                        showInfo(context, 'ลงประกาศไม่สำเร็จ กรุณาลองใหม่');
                        setState(() => _submitting = false);
                      }
                    },
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _stepScroll(List<Widget> children) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: children,
    );
  }

  Widget _sellTypeCard({
    required Key key,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: const Color(0xFFFFF5EC),
      elevation: 1.5,
      shadowColor: AppTheme.orange.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFDDC5),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: AppTheme.orange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 7),
                    LocalizedText(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.orange,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundBackButton(VoidCallback onTap) => Material(
    color: const Color(0xFFFFF4EC),
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onTap,
      icon: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 19,
        color: AppTheme.orange,
      ),
    ),
  );

  InputDecoration _inputDecoration({
    String? hint,
    String? prefixText,
    IconData? prefixIcon,
    bool counter = false,
  }) {
    return InputDecoration(
      hintText: hint == null ? null : AppLocalizations.of(context).source(hint),
      prefixText: prefixText,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: AppTheme.textMuted),
      counterText: counter ? null : '',
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.orange, width: 1.4),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.orange,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 9),
              LocalizedText(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            LocalizedText(
              subtitle,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ],
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _conditionButton(String label, IconData icon) {
    final selected = _condition == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _condition = label),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 90,
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF7F1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.orange : AppTheme.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppTheme.orange : AppTheme.textMuted,
                size: 28,
              ),
              const SizedBox(height: 7),
              LocalizedText(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomPair({required String backText, required String nextText}) =>
      Row(
        children: [
          Expanded(child: _outlineButton(backText, _back)),
          const SizedBox(width: 14),
          Expanded(flex: 2, child: _primaryButton(nextText, _next)),
        ],
      );

  Widget _primaryButton(String text, VoidCallback? onTap) => SizedBox(
    height: 58,
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: LocalizedText(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
    ),
  );

  Widget _outlineButton(String text, VoidCallback onTap) => SizedBox(
    height: 58,
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.orange,
        side: const BorderSide(color: AppTheme.orange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: LocalizedText(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    ),
  );

  Widget _confirmSection(String title, String value, {IconData? icon}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[
        Icon(icon, color: AppTheme.textMuted),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            LocalizedText(
              value,
              style: const TextStyle(color: AppTheme.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
      const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
    ],
  );

  Widget _contactRow(IconData icon, String title, String value) => Row(
    children: [
      Icon(icon, color: AppTheme.textMuted),
      const SizedBox(width: 16),
      Expanded(
        child: LocalizedText(
          title,
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      ),
      LocalizedText(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(width: 8),
      const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: LocalizedText(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        backgroundColor: const Color(0xFFFFF2E8),
        child: Icon(icon, color: AppTheme.orange),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocalizedText(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            LocalizedText(
              subtitle,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    ],
  );
}

class _MiniLocationMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFD8D6CE)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final minor = Paint()
      ..color = const Color(0xFFE6E3DB)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final water = Paint()
      ..color = const Color(0xFFBFDDEB)
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke;
    final green = Paint()
      ..color = const Color(0xFFDDEAD7)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * .67,
        size.height * .49,
        size.width * .16,
        size.height * .14,
      ),
      green,
    );
    final river = Path()
      ..moveTo(size.width * .08, -10)
      ..cubicTo(
        size.width * .02,
        size.height * .25,
        size.width * .16,
        size.height * .58,
        size.width * .08,
        size.height + 10,
      );
    canvas.drawPath(river, water);
    for (var i = 1; i < 7; i++) {
      final y = size.height * i / 7;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (i.isEven ? 18 : -12)),
        minor,
      );
    }
    for (var i = 1; i < 8; i++) {
      final x = size.width * i / 8;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + (i.isEven ? 28 : -18), size.height),
        minor,
      );
    }
    canvas.drawLine(
      Offset(0, size.height * .7),
      Offset(size.width, size.height * .52),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .52, 0),
      Offset(size.width * .45, size.height),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  MockStore? _selected;
  bool _showFilter = false;
  bool _loading = true;
  String _category = 'all';
  String _distance = '25 เมตร';
  List<MockStore> _stores = [];
  bool _filterApplied = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadStores();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestLocation());
  }

  Future<void> _requestLocation() async {
    try {
      final position = await SuikaiService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = position);
      if (position == null) {
        showInfo(
          context,
          'เปิดแผนที่ได้ตามปกติ แต่ไม่สามารถแสดงตำแหน่งปัจจุบันได้',
        );
      }
    } catch (_) {
      if (mounted) {
        showInfo(context, 'ไม่สามารถใช้บริการตำแหน่งได้');
      }
    }
  }

  Future<void> _loadStores() async {
    try {
      final data = await SuikaiService.fetchStores();
      final next = data.map((item) {
        return MockStore(
          id: item['id'].toString(),
          name: item['name']?.toString() ?? '',
          type: item['category']?.toString() ?? 'ร้านค้า',
          city: item['city']?.toString() ?? '',
          distance: '0 กม.',
          logo: item['logo_url']?.toString() ?? '',
          description: item['description']?.toString() ?? '',
          phone: item['phone']?.toString() ?? '',
          viber: item['viber_phone']?.toString() ?? '',
          hours: '${item['opening_time'] ?? ''}-${item['closing_time'] ?? ''}',
          approved: true,
          ownerId: item['owner_id']?.toString(),
          isPromoted: item['is_promoted'] == true,
          promotionStartAt: DateTime.tryParse('${item['promotion_start_at']}'),
          promotionEndAt: DateTime.tryParse('${item['promotion_end_at']}'),
          latitude: (item['latitude'] as num?)?.toDouble(),
          longitude: (item['longitude'] as num?)?.toDouble(),
        );
      }).toList();
      if (mounted) {
        setState(() {
          _stores = next;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<MockStore> get _storesForView {
    final approved = _loading ? MockRepo.approvedStores : _stores;
    if (!_filterApplied) {
      return approved.where((store) => store.promotionIsActive).toList();
    }
    final filtered = _category == 'all'
        ? approved
        : approved
              .where(
                (store) =>
                    SuikaiService.categoryIdForValue('store', store.type) ==
                    _category,
              )
              .toList();
    final position = _currentPosition;
    if (position == null) return filtered;
    return filtered.where((store) {
      if (store.latitude == null || store.longitude == null) return true;
      return SuikaiService.isWithin500Km(
        position,
        store.latitude,
        store.longitude,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stores = _storesForView;

    return RootScaffold(
      selectedIndex: 3,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SuikaiMapPainter())),
          SafeArea(
            child: Column(
              children: [
                _mapTopBar(),
                _categoryStrip(),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _mapMarkers(stores)),
                      Positioned(
                        left: 14,
                        bottom: 210,
                        child: _MapRoundButton(
                          icon: Icons.my_location_rounded,
                          onTap: _requestLocation,
                        ),
                      ),
                      if (_selected != null)
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: _selectedStoreCard(_selected!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_showFilter) _filterSheet(),
        ],
      ),
    );
  }

  Widget _mapTopBar() => Container(
    color: Colors.white,
    child: Column(
      children: [
        const _SuikaiHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  readOnly: true,
                  onTap: () => showInfo(context, 'ค้นหาร้านค้าบนแผนที่ (mock)'),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    ).source('ค้นหาร้านค้า หรือหมวดหมู่'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: const Color(0xFFF8F8F8),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showFilter = true),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: const LocalizedText('ตัวกรอง'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xFFE7E7E7)),
                  minimumSize: const Size(104, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _categoryStrip() {
    final items = <(String, IconData)>[
      const ('all', Icons.grid_view_rounded),
      for (final category in SuikaiService.categoryRecords('store'))
        (category.id, _storeCategoryIcon(category.id)),
    ];
    return Container(
      height: 76,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final active = _category == item.$1;
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() {
              _category = item.$1;
              _selected = null;
              _filterApplied = true;
            }),
            child: SizedBox(
              width: 66,
              child: Column(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: active
                          ? AppTheme.orangeSoft
                          : const Color(0xFFFFF7F0),
                      shape: BoxShape.circle,
                      border: active
                          ? Border.all(color: AppTheme.orange, width: 1.4)
                          : null,
                    ),
                    child: Icon(item.$2, size: 20, color: AppTheme.orange),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$1 == 'all'
                        ? AppLocalizations.of(context).source('ทั้งหมด')
                        : _categoryLabel(context, 'store', item.$1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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

  Widget _mapMarkers(List<MockStore> stores) {
    return LayoutBuilder(
      builder: (context, c) {
        final coords = <Offset>[
          Offset(c.maxWidth * .28, c.maxHeight * .32),
          Offset(c.maxWidth * .68, c.maxHeight * .22),
          Offset(c.maxWidth * .52, c.maxHeight * .50),
          Offset(c.maxWidth * .78, c.maxHeight * .58),
          Offset(c.maxWidth * .18, c.maxHeight * .62),
        ];
        return Stack(
          children: [
            if (_currentPosition != null)
              Positioned(
                left: c.maxWidth * .45 - 21,
                top: c.maxHeight * .38 - 21,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: .16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ),
              ),
            for (var i = 0; i < stores.length; i++)
              Positioned(
                left: coords[i % coords.length].dx - 20,
                top: coords[i % coords.length].dy - 20,
                child: GestureDetector(
                  onTap: () => setState(() => _selected = stores[i]),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _selected?.id == stores[i].id
                          ? AppTheme.orange
                          : const Color(0xFFD86D18),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _storeIcon(stores[i].type),
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  IconData _storeIcon(String type) {
    if (type.contains('ยาน')) return Icons.directions_car_rounded;
    if (type.contains('มือถือ')) return Icons.phone_iphone_rounded;
    if (type.contains('บ้าน')) return Icons.home_rounded;
    if (type.contains('แฟชั่น')) return Icons.checkroom_rounded;
    return Icons.storefront_rounded;
  }

  Widget _selectedStoreCard(MockStore store) => Material(
    color: Colors.white,
    elevation: 5,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: persistentImage(
                  store.logo,
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 68,
                    height: 68,
                    color: AppTheme.orangeSoft,
                    child: const Icon(Icons.storefront, color: AppTheme.orange),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      store.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _categoryLabel(context, 'store', store.type),
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 16,
                          color: Color(0xFFFFA000),
                        ),
                        const SizedBox(width: 3),
                        const LocalizedText(
                          '4.8',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.near_me_outlined,
                          size: 15,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 3),
                        LocalizedText(
                          _distanceLabel(store),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selected = null),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 9, color: Color(0xFF26A65B)),
                    const SizedBox(width: 5),
                    LocalizedText(
                      store.hours,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  try {
                    await launchPhone(store.phone);
                  } catch (_) {
                    if (context.mounted) {
                      showInfo(context, 'เปิดโทรศัพท์ไม่ได้');
                    }
                  }
                },
                icon: const Icon(Icons.phone_outlined, color: AppTheme.orange),
              ),
              IconButton(
                onPressed: _requestLocation,
                icon: const Icon(
                  Icons.navigation_outlined,
                  color: AppTheme.orange,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(
                context,
                SuikaiRoutes.storeDetail,
                arguments: store.id,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const LocalizedText(
                'ดูรายละเอียดร้าน',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String _distanceLabel(MockStore store) {
    final position = _currentPosition;
    if (position == null || store.latitude == null || store.longitude == null) {
      return store.distance;
    }
    final distance = SuikaiService.distanceKm(
      position.latitude,
      position.longitude,
      store.latitude!,
      store.longitude!,
    );
    final l10n = AppLocalizations.of(context);
    return '${l10n.source('ประมาณ')} '
        '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} '
        '${l10n.source('กม.')}';
  }

  Widget _filterSheet() {
    final categories = <(String, IconData)>[
      const ('all', Icons.grid_view_rounded),
      for (final category in SuikaiService.categoryRecords('store'))
        (category.id, _storeCategoryIcon(category.id)),
    ];
    const distances = ['10 เมตร', '25 เมตร', '50 เมตร', '100 เมตร'];

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: .28),
        child: Column(
          children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: LocalizedText(
                            'ตัวกรองร้านค้า',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _showFilter = false),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const LocalizedText(
                      'หมวดหมู่ร้านค้า',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: .9,
                      children: categories.map((item) {
                        final active = _category == item.$1;
                        return InkWell(
                          onTap: () => setState(() => _category = item.$1),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              color: active
                                  ? AppTheme.orangeSoft
                                  : const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: active
                                    ? AppTheme.orange
                                    : const Color(0xFFEAEAEA),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(item.$2, size: 20, color: AppTheme.orange),
                                const SizedBox(height: 5),
                                Text(
                                  item.$1 == 'all'
                                      ? AppLocalizations.of(
                                          context,
                                        ).source('ทั้งหมด')
                                      : _categoryLabel(
                                          context,
                                          'store',
                                          item.$1,
                                        ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    const LocalizedText(
                      'ระยะห่างจากคุณ',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: distances
                          .map(
                            (d) => ChoiceChip(
                              label: LocalizedText(d),
                              selected: _distance == d,
                              selectedColor: AppTheme.orangeSoft,
                              side: BorderSide(
                                color: _distance == d
                                    ? AppTheme.orange
                                    : const Color(0xFFE5E5E5),
                              ),
                              onSelected: (_) => setState(() => _distance = d),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() {
                              _category = 'all';
                              _distance = '25 เมตร';
                              _filterApplied = false;
                              _selected = null;
                            }),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const LocalizedText('ล้างค่า'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() {
                              _showFilter = false;
                              _selected = null;
                              _filterApplied = true;
                            }),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.orange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const LocalizedText(
                              'ยืนยัน',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapRoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 3,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(icon, color: Colors.black87),
      ),
    ),
  );
}

class _SuikaiMapPainter extends CustomPainter {
  const _SuikaiMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF2EFE8),
    );

    final park = Paint()..color = const Color(0xFFE0ECD8);
    final water = Paint()..color = const Color(0xFFD8EAF4);
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final minor = Paint()
      ..color = const Color(0xFFFFFDF9)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .03,
          size.height * .10,
          size.width * .30,
          size.height * .16,
        ),
        const Radius.circular(28),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .66,
          size.height * .48,
          size.width * .28,
          size.height * .17,
        ),
        const Radius.circular(28),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -20,
          size.height * .58,
          size.width * .27,
          size.height * .23,
        ),
        const Radius.circular(32),
      ),
      water,
    );

    canvas.drawPath(
      Path()
        ..moveTo(-10, size.height * .22)
        ..cubicTo(
          size.width * .22,
          size.height * .12,
          size.width * .58,
          size.height * .44,
          size.width + 10,
          size.height * .27,
        ),
      road,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .19, -10)
        ..cubicTo(
          size.width * .30,
          size.height * .25,
          size.width * .34,
          size.height * .63,
          size.width * .49,
          size.height + 20,
        ),
      road,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .75, -10)
        ..cubicTo(
          size.width * .64,
          size.height * .28,
          size.width * .83,
          size.height * .63,
          size.width * .70,
          size.height + 10,
        ),
      minor,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-10, size.height * .74)
        ..cubicTo(
          size.width * .30,
          size.height * .62,
          size.width * .65,
          size.height * .84,
          size.width + 10,
          size.height * .69,
        ),
      minor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _tab = 'ประกาศของฉัน';
  String _metric = 'all';
  String? _selectedStoreId;
  UserProfile? _profile;
  final Map<String, ProductStatus> _statusEdits = {
    for (final p in MockRepo.managedProducts) p.id: p.status,
  };
  List<MockStore> _myStores = [];

  @override
  void initState() {
    super.initState();
    _loadMyStores();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await SuikaiService.currentProfile();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const LocalizedText('ออกจากระบบ'),
        content: const LocalizedText('ต้องการออกจากระบบใช่หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const LocalizedText('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const LocalizedText('ออกจากระบบ'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await SuikaiService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, SuikaiRoutes.home, (_) => false);
  }

  Future<void> _loadMyStores() async {
    try {
      final rows = await SuikaiService.fetchMyStores();
      final stores = rows
          .map(
            (item) => MockStore(
              id: item['id'].toString(),
              name: item['name']?.toString() ?? '',
              type: item['category']?.toString() ?? '',
              city: item['city']?.toString() ?? '',
              distance: '',
              logo: item['logo_url']?.toString() ?? '',
              description: item['description']?.toString() ?? '',
              phone: item['phone']?.toString() ?? '',
              viber: item['viber_phone']?.toString() ?? '',
              hours:
                  '${item['opening_time'] ?? ''}-${item['closing_time'] ?? ''}',
              approved: item['status'] == 'approved',
              ownerId: item['owner_id']?.toString(),
              coverUrl: item['cover_url']?.toString(),
              email: item['email']?.toString(),
            ),
          )
          .toList();
      if (mounted)
        setState(() {
          _myStores = stores;
          _selectedStoreId ??= stores.firstOrNull?.id;
          MockRepo.cacheStores(stores);
        });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SuikaiService.currentUserId;
    final all = currentUserId == null
        ? <MockProduct>[]
        : MockRepo.products
              .where((product) => product.ownerId == currentUserId)
              .toList();
    final generalItems = all.where((p) => !p.isStoreProduct).toList();
    final scopedItems = _tab == 'ร้านของฉัน'
        ? all.where((p) => p.storeId == _selectedStoreId).toList()
        : generalItems;
    final items =
        scopedItems.where((product) {
          if (_metric == 'likes') return product.likeCount > 0;
          if (_metric == 'views') return product.viewCount > 0;
          return true;
        }).toList()..sort(
          (a, b) => _metric == 'likes'
              ? b.likeCount.compareTo(a.likeCount)
              : _metric == 'views'
              ? b.viewCount.compareTo(a.viewCount)
              : 0,
        );
    final likes = scopedItems.fold<int>(0, (sum, p) => sum + p.likeCount);
    final views = scopedItems.fold<int>(0, (sum, p) => sum + p.viewCount);

    return RootScaffold(
      selectedIndex: 4,
      body: Column(
        children: [
          const _SuikaiHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
              children: [
                const LocalizedText(
                  'จัดการของฉัน',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const LocalizedText(
                  'สำหรับผู้ลงประกาศและเจ้าของร้าน',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.orangeSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: ClipOval(
                          child: (_profile?.avatar ?? '').isEmpty
                              ? Container(
                                  color: Colors.white,
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: AppTheme.orange,
                                    size: 32,
                                  ),
                                )
                              : persistentImage(
                                  _profile!.avatar,
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.white,
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: AppTheme.orange,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _profile?.name.isNotEmpty == true
                                  ? _profile!.name
                                  : AppLocalizations.of(
                                      context,
                                    ).source('บัญชีผู้ขาย'),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const LocalizedText(
                              'ลูกค้าทั่วไปไม่จำเป็นต้องเข้าสู่ระบบ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileSettingsPage(),
                            ),
                          );
                          _loadProfile();
                        },
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'ประกาศ',
                        value: '${scopedItems.length}',
                        selected: _metric == 'all',
                        onTap: () => setState(() => _metric = 'all'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatBox(
                        label: 'ถูกใจ',
                        value: '$likes',
                        selected: _metric == 'likes',
                        onTap: () => setState(() => _metric = 'likes'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatBox(
                        label: 'เข้าชม',
                        value: '$views',
                        selected: _metric == 'views',
                        onTap: () => setState(() => _metric = 'views'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'ประกาศของฉัน',
                      label: LocalizedText('ประกาศของฉัน'),
                      icon: Icon(Icons.sell_outlined),
                    ),
                    ButtonSegment(
                      value: 'ร้านของฉัน',
                      label: LocalizedText('ร้านของฉัน'),
                      icon: Icon(Icons.store_outlined),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (v) => setState(() {
                    _tab = v.first;
                    _metric = 'all';
                  }),
                ),
                const SizedBox(height: 14),
                if ((_tab == 'ร้านของฉัน' && _myStores.isEmpty) ||
                    (_tab != 'ร้านของฉัน' && items.isEmpty))
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    alignment: Alignment.center,
                    child: LocalizedText(
                      _tab == 'ร้านของฉัน'
                          ? 'ยังไม่มีร้านค้า'
                          : 'ยังไม่มีประกาศ',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                if (_tab == 'ร้านของฉัน')
                  if (_myStores.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedStoreId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(
                            context,
                          ).source('เลือกร้านค้า'),
                        ),
                        items: _myStores
                            .map(
                              (store) => DropdownMenuItem(
                                value: store.id,
                                child: Text(
                                  store.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() {
                          _selectedStoreId = value;
                          _metric = 'all';
                        }),
                      ),
                    ),
                if (_tab == 'ร้านของฉัน')
                  for (final store in _myStores.where(
                    (store) => store.id == _selectedStoreId,
                  ))
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        minVerticalPadding: 10,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: store.logo.isEmpty
                              ? Container(
                                  width: 58,
                                  height: 58,
                                  color: AppTheme.orangeSoft,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    color: AppTheme.orange,
                                  ),
                                )
                              : persistentImage(
                                  store.logo,
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 58,
                                    height: 58,
                                    color: AppTheme.orangeSoft,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.storefront_rounded,
                                      color: AppTheme.orange,
                                    ),
                                  ),
                                ),
                        ),
                        title: LocalizedText(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _categoryLabel(context, 'store', store.type),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Text(' • '),
                            Flexible(
                              child: LocalizedText(
                                store.approved ? 'อนุมัติแล้ว' : 'รอการอนุมัติ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.pushNamed(
                          context,
                          SuikaiRoutes.storeDetail,
                          arguments: store.id,
                        ),
                      ),
                    ),
                if (_tab == 'ร้านของฉัน' &&
                    _myStores.isNotEmpty &&
                    items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: LocalizedText(
                        'ยังไม่มีสินค้าในร้าน',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: persistentImage(
                                  item.image,
                                  width: 66,
                                  height: 66,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 66,
                                    height: 66,
                                    color: AppTheme.orangeSoft,
                                    child: const Icon(Icons.image_outlined),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    LocalizedText(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LocalizedText(
                                      item.price,
                                      style: const TextStyle(
                                        color: AppTheme.orange,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    LocalizedText(
                                      '♥ ${item.likeCount}    👁 ${item.viewCount}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  SuikaiRoutes.productDetail,
                                  arguments: item.id,
                                ),
                                icon: const Icon(Icons.chevron_right_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          DropdownButtonFormField<ProductStatus>(
                            initialValue: _statusEdits[item.id] ?? item.status,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).source('สถานะสินค้า'),
                              isDense: true,
                            ),
                            items:
                                const [
                                      ProductStatus.available,
                                      ProductStatus.outOfStock,
                                      ProductStatus.deleted,
                                    ]
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _statusDot(status),
                                            const SizedBox(width: 8),
                                            LocalizedText(
                                              _statusLabel(context, status),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) async {
                              if (value == null ||
                                  item.ownerId != currentUserId)
                                return;
                              try {
                                await SuikaiService.updateListing(
                                  listingId: item.id,
                                  title: item.title,
                                  description: item.description,
                                  city: item.city,
                                  phone: item.phone,
                                  viber: item.viber,
                                  price: item.priceValue.toDouble(),
                                  currency: item.currencyCode,
                                  status: value == ProductStatus.outOfStock
                                      ? 'out_of_stock'
                                      : value.name,
                                );
                                MockRepo.setStatus(item.id, value);
                                if (mounted) {
                                  setState(() => _statusEdits[item.id] = value);
                                }
                              } catch (_) {
                                if (mounted)
                                  showInfo(context, 'อัปเดตสถานะไม่สำเร็จ');
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                if (SuikaiService.isLoggedIn) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const LocalizedText('ออกจากระบบ'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB3261E),
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool selected;
  const _StatBox({
    required this.label,
    required this.value,
    this.onTap,
    this.selected = false,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? AppTheme.orange : AppTheme.border),
      ),
      child: Column(
        children: [
          LocalizedText(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.orange,
            ),
          ),
          const SizedBox(height: 2),
          LocalizedText(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    ),
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<NotificationRecord>> _future =
      SuikaiService.fetchNotifications();

  String _label(String type) => switch (type) {
    'store_application_approved' => 'อนุมัติร้านแล้ว',
    'store_application_rejected' => 'ไม่อนุมัติร้าน',
    'store_edit_approved' => 'อนุมัติการแก้ไขร้านแล้ว',
    'store_edit_rejected' => 'ไม่อนุมัติการแก้ไขร้าน',
    'promotion_approved' => 'อนุมัติการโปรโมตร้านแล้ว',
    'promotion_rejected' => 'ไม่อนุมัติการโปรโมตร้าน',
    _ => type.replaceAll('_', ' '),
  };

  Future<void> _read(NotificationRecord value) async {
    if (!value.isRead) await SuikaiService.markNotificationRead(value.id);
    if (mounted) {
      setState(() => _future = SuikaiService.fetchNotifications());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const LocalizedText('การแจ้งเตือน')),
    body: FutureBuilder<List<NotificationRecord>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final values = snapshot.data ?? const [];
        if (values.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 58,
                    color: AppTheme.orange,
                  ),
                  SizedBox(height: 12),
                  LocalizedText(
                    'ยังไม่มีการแจ้งเตือนใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          );
        }
        final unread = values.where((value) => !value.isRead).length;
        return Column(
          children: [
            if (unread > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$unread',
                    style: const TextStyle(
                      color: AppTheme.orange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: values.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final value = values[index];
                  return ListTile(
                    leading: Icon(
                      value.isRead
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_rounded,
                      color: value.isRead
                          ? AppTheme.textMuted
                          : AppTheme.orange,
                    ),
                    title: LocalizedText(
                      _label(value.eventType),
                      style: TextStyle(
                        fontWeight: value.isRead
                            ? FontWeight.w500
                            : FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${value.payload['review_note'] ?? ''}\n${value.createdAt.toLocal()}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _read(value),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String _category = 'all';
  String _city = 'ทั้งหมด';
  int _maxPrice = 100000000;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initialCategory =
        ModalRoute.of(context)?.settings.arguments as String?;
    if (initialCategory != null && _category == 'all') {
      _category = SuikaiService.categoryIdForValue('listing', initialCategory);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>[
      'all',
      ...SuikaiService.categoryRecords('listing').map((value) => value.id),
    ];
    final cities = <String>{
      'ทั้งหมด',
      ...MockRepo.products.map((p) => p.city),
    }.toList();
    final query = _searchController.text.toLowerCase().trim();

    final results = MockRepo.feedProducts.where((product) {
      final p =
          int.tryParse(product.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final matchesQuery =
          query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      final matchesCategory =
          _category == 'all' ||
          SuikaiService.categoryIdForValue('listing', product.category) ==
              _category;
      final matchesCity = _city == 'ทั้งหมด' || product.city == _city;
      final matchesPrice = p <= _maxPrice;
      return matchesQuery && matchesCategory && matchesCity && matchesPrice;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const LocalizedText('ค้นหา')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).source('ค้นหาสินค้า'),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final categoryField = _categoryField(categories);
                final cityField = _cityField(cities);
                if (constraints.maxWidth < 340) {
                  return Column(
                    children: [
                      categoryField,
                      const SizedBox(height: 10),
                      cityField,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: categoryField),
                    const SizedBox(width: 10),
                    Expanded(child: cityField),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Flexible(
                  child: LocalizedText(
                    'ราคาไม่เกิน',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _maxPrice.toDouble(),
                    min: 1000,
                    max: 100000000,
                    divisions: 50,
                    label: _maxPrice.toString(),
                    onChanged: (value) =>
                        setState(() => _maxPrice = value.toInt()),
                  ),
                ),
                Flexible(
                  child: LocalizedText(
                    _maxPrice >= 100000000 ? '100 ล้าน+' : '฿$_maxPrice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final columns = width >= 1100
                    ? 4
                    : width >= 760
                    ? 3
                    : 2;
                final cardWidth = (width - 32 - (columns - 1) * 10) / columns;
                final textScale =
                    MediaQuery.textScalerOf(context).scale(12) / 12;
                final clampedTextScale = textScale.clamp(1.0, 1.6).toDouble();
                final baseRatio = cardWidth < 150
                    ? .58
                    : cardWidth < 180
                    ? .66
                    : .73;
                final responsiveRatio =
                    baseRatio / (1 + (clampedTextScale - 1) * .35);
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  itemCount: results.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                    childAspectRatio: width >= 760 ? .78 : responsiveRatio,
                  ),
                  itemBuilder: (context, index) =>
                      ProductCard(product: results[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryField(List<String> categories) =>
      DropdownButtonFormField<String>(
        initialValue: _category,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).source('หมวดหมู่'),
        ),
        items: categories
            .map(
              (category) => DropdownMenuItem(
                value: category,
                child: Text(
                  category == 'all'
                      ? AppLocalizations.of(context).source('ทั้งหมด')
                      : _categoryLabel(context, 'listing', category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _category = value ?? _category),
      );

  Widget _cityField(List<String> cities) => DropdownButtonFormField<String>(
    initialValue: _city,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: AppLocalizations.of(context).source('เมือง'),
    ),
    items: cities
        .map(
          (city) => DropdownMenuItem(
            value: city,
            child: LocalizedText(
              city,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: (value) => setState(() => _city = value ?? _city),
  );
}

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _imageIndex = 0;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    InteractionStore.trackView(widget.productId);
  }

  Future<void> _shareProduct(MockProduct product) async {
    final source = primaryProductImage(product);
    if (source == null) {
      showInfo(context, 'ไม่มีรูปสำหรับแชร์');
      return;
    }
    setState(() => _sharing = true);
    try {
      final opened = await SuikaiService.shareProductImage(
        imageSource: source,
        title: product.title,
        price: product.price,
      );
      if (!opened && mounted) showInfo(context, 'ไม่มีรูปสำหรับแชร์');
    } catch (_) {
      if (mounted) showInfo(context, 'เปิดการแชร์ไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _edit(MockProduct product) async {
    final title = TextEditingController(text: product.title);
    final price = TextEditingController(text: product.priceValue.toString());
    final description = TextEditingController(text: product.description);
    final city = TextEditingController(text: product.city);
    final phone = TextEditingController(text: product.phone);
    final viber = TextEditingController(text: product.viber);
    var currency = product.currencyCode;
    var status = product.status;
    final newImages = <SelectedImage>[];
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const LocalizedText('แก้ไขสินค้า'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).source('ชื่อสินค้า'),
                  ),
                ),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).source('ราคา'),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: currency,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).source('สกุลเงิน'),
                  ),
                  items: const ['MMK', 'THB', 'USD', 'CNY']
                      .map(
                        (v) =>
                            DropdownMenuItem(value: v, child: LocalizedText(v)),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => currency = v ?? currency),
                ),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).source('รายละเอียด'),
                  ),
                ),
                TextField(
                  controller: city,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).source('ตำแหน่ง/เมือง'),
                  ),
                ),
                TextField(
                  controller: phone,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(
                      context,
                    ).source('เบอร์ติดต่อ'),
                  ),
                ),
                TextField(
                  controller: viber,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).source('Viber'),
                  ),
                ),
                DropdownButtonFormField<ProductStatus>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).source('สถานะ'),
                  ),
                  items:
                      (product.isStoreProduct
                              ? const [
                                  ProductStatus.available,
                                  ProductStatus.outOfStock,
                                  ProductStatus.deleted,
                                ]
                              : const [
                                  ProductStatus.available,
                                  ProductStatus.reserved,
                                  ProductStatus.sold,
                                ])
                          .map(
                            (v) => DropdownMenuItem(
                              value: v,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _statusDot(v),
                                  const SizedBox(width: 8),
                                  LocalizedText(_statusLabel(context, v)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setDialogState(() => status = v ?? status),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final image = await SuikaiService.pickImage();
                    if (image != null)
                      setDialogState(() => newImages.add(image));
                  },
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: LocalizedText('เพิ่มรูป (${newImages.length})'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const LocalizedText('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(price.text);
                if (title.text.trim().isEmpty || amount == null || amount < 0) {
                  showInfo(context, 'กรุณากรอกชื่อและราคาให้ถูกต้อง');
                  return;
                }
                try {
                  await SuikaiService.updateListing(
                    listingId: product.id,
                    title: title.text.trim(),
                    description: description.text.trim(),
                    city: city.text.trim(),
                    phone: normalizePhone(phone.text),
                    viber: normalizePhone(viber.text),
                    price: amount,
                    currency: currency,
                    status: status == ProductStatus.outOfStock
                        ? 'out_of_stock'
                        : status.name,
                    newImages: newImages,
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (_) {
                  if (context.mounted)
                    showInfo(context, 'บันทึกการแก้ไขไม่สำเร็จ');
                }
              },
              child: const LocalizedText('บันทึก'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [title, price, description, city, phone, viber]) {
      controller.dispose();
    }
    if (saved == true && mounted) {
      showInfo(context, 'บันทึกการแก้ไขแล้ว');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = MockRepo.productById(widget.productId);
    if (product == null) {
      return const _MissingPage(title: 'ไม่พบสินค้า');
    }
    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('รายละเอียดสินค้า'),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).source('แชร์สินค้า'),
            onPressed: !_sharing && primaryProductImage(product) != null
                ? () => _shareProduct(product)
                : null,
            icon: _sharing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
          ),
          if (product.ownerId != null &&
              product.ownerId == SuikaiService.currentUserId) ...[
            TextButton.icon(
              onPressed: () async {
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditListingPage(productId: product.id),
                  ),
                );
                if (mounted) setState(() {});
              },
              icon: const Icon(Icons.edit_outlined),
              label: const LocalizedText('แก้ไข'),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).source('ลบประกาศ'),
              onPressed: () async {
                await SuikaiService.deleteListing(product.id);
                MockRepo.removeProduct(product.id);
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * .52,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: product.imageUrls.length,
                  onPageChanged: (index) => setState(() => _imageIndex = index),
                  itemBuilder: (context, index) => ColoredBox(
                    color: const Color(0xFFF5F5F5),
                    child: persistentImage(
                      product.imageUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: LocalizedText(
                      '${_imageIndex + 1}/${product.imageUrls.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LocalizedText(
            product.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          LocalizedText(
            product.price,
            style: const TextStyle(
              color: AppTheme.orange,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _statusChip(context, product.status),
          const SizedBox(height: 8),
          Row(
            children: [
              const LocalizedText('หมวดหมู่'),
              const Text(': '),
              Expanded(
                child: Text(
                  _categoryLabel(context, 'listing', product.category),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LocalizedText(product.description),
          const SizedBox(height: 10),
          LocalizedText('เมือง: ${product.city}'),
          const SizedBox(height: 4),
          LocalizedText(
            'Like ${product.likeCount} • View ${product.viewCount}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      await launchPhone(product.phone);
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }
                      showInfo(context, 'เปิดโทรศัพท์ไม่ได้');
                    }
                  },
                  icon: const Icon(Icons.phone),
                  label: const LocalizedText('โทร'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await launchViber(product.viber);
                    } catch (_) {
                      if (!context.mounted) {
                        return;
                      }
                      showInfo(context, 'เปิด Viber ไม่ได้');
                    }
                  },
                  icon: const Icon(Icons.call),
                  label: const LocalizedText('Viber'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              SuikaiRoutes.report,
              arguments: product.id,
            ),
            icon: const Icon(Icons.flag_outlined),
            label: const LocalizedText('Report'),
          ),
        ],
      ),
    );
  }
}

class ReportPage extends StatefulWidget {
  final String productId;

  const ReportPage({super.key, required this.productId});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _formKey = GlobalKey<FormState>();
  String _reason = 'ข้อมูลไม่ถูกต้อง';
  final _detailController = TextEditingController();

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const LocalizedText('Report')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            LocalizedText(
              widget.productId.startsWith('store:')
                  ? 'ร้าน: ${widget.productId.substring(6)}'
                  : 'สินค้า: ${widget.productId}',
            ),
            const SizedBox(height: 12),
            const LocalizedText(
              'เลือกเหตุผล',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            RadioGroup<String>(
              groupValue: _reason,
              onChanged: (value) => setState(() => _reason = value ?? _reason),
              child: Column(
                children: [
                  for (final reason in const [
                    'ข้อมูลไม่ถูกต้อง',
                    'สินค้าถูกขายไปแล้ว',
                    'เนื้อหาไม่เหมาะสม',
                    'อื่นๆ',
                  ])
                    RadioListTile<String>(
                      value: reason,
                      title: LocalizedText(reason),
                    ),
                ],
              ),
            ),
            TextFormField(
              controller: _detailController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(
                  context,
                ).source('รายละเอียดเพิ่มเติม'),
              ),
              validator: (value) => normalizeText(value).isEmpty
                  ? AppLocalizations.of(
                      context,
                    ).source('กรุณากรอกรายละเอียดเพิ่มเติม')
                  : null,
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                try {
                  await SuikaiService.submitReport(
                    reason: _reason,
                    details: normalizeText(_detailController.text),
                    listingId: widget.productId.startsWith('store:')
                        ? null
                        : widget.productId,
                    storeId: widget.productId.startsWith('store:')
                        ? widget.productId.substring(6)
                        : null,
                  );
                  if (!context.mounted) {
                    return;
                  }
                  showInfo(context, 'ส่งรายงานแล้ว');
                  Navigator.pop(context);
                } catch (_) {
                  if (!context.mounted) {
                    return;
                  }
                  showInfo(context, 'ส่งรายงานไม่สำเร็จ');
                }
              },
              child: const LocalizedText('ส่งรายงาน'),
            ),
          ],
        ),
      ),
    );
  }
}

class OpenShopPage extends StatefulWidget {
  const OpenShopPage({super.key});

  @override
  State<OpenShopPage> createState() => _OpenShopPageState();
}

class _OpenShopPageState extends State<OpenShopPage> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _viber = TextEditingController();
  final _email = TextEditingController();
  final _locationDetail = TextEditingController();
  String _shopType = '';
  String _hours = 'เปิดทุกวัน';
  bool _accepted = false;
  bool _submitting = false;
  SelectedImage? _logoImage;
  SelectedImage? _coverImage;
  Position? _storePosition;

  static const _steps = [
    'ข้อมูลร้านค้า',
    'ข้อมูลติดต่อ',
    'ที่อยู่ร้านค้า',
    'ยืนยันการเปิดร้าน',
  ];

  @override
  void initState() {
    super.initState();
    _shopType =
        SuikaiService.categoryRecords(
          'store',
          activeOnly: true,
        ).firstOrNull?.id ??
        '';
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _phone,
      _viber,
      _email,
      _locationDetail,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      if (_name.text.trim().isEmpty ||
          normalizeText(_description.text).isEmpty) {
        showInfo(context, 'กรุณากรอกข้อมูลร้านให้ครบถ้วน');
        return;
      }
      if (_logoImage == null) {
        showInfo(context, 'กรุณาเพิ่มรูปโลโก้ร้านค้า');
        return;
      }
    }
    if (_step == 1) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
      final phone = normalizePhone(_phone.text);
      if (phone.isEmpty) {
        showInfo(context, 'กรุณากรอกเบอร์โทร');
        return;
      }
      final email = normalizeText(_email.text);
      if (email.isNotEmpty && validateEmail(email) != null) {
        showInfo(context, 'กรุณากรอกอีเมลให้ถูกต้อง');
        return;
      }
    }
    if (_step == 2) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }
    if (_step < 3) {
      setState(() => _step++);
    }
  }

  Future<void> _captureStoreLocation() async {
    try {
      final position = await SuikaiService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _storePosition = position);
      showInfo(
        context,
        position == null
            ? 'ไม่สามารถใช้ตำแหน่ง GPS ได้'
            : 'บันทึกตำแหน่งสำหรับการค้นหาใกล้เคียงแล้ว',
      );
    } catch (_) {
      if (mounted) showInfo(context, 'ไม่สามารถใช้ตำแหน่ง GPS ได้');
    }
  }

  Future<void> _pickStoreImage({required bool logo}) async {
    try {
      final image = await SuikaiService.pickImage();
      if (!mounted || image == null) return;
      setState(() => logo ? _logoImage = image : _coverImage = image);
    } catch (_) {
      if (mounted) showInfo(context, 'ไม่สามารถเลือกรูปได้ กรุณาลองใหม่');
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _back,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.orange,
          ),
        ),
        title: const LocalizedText(
          'เปิดร้านค้า',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => showInfo(context, 'บันทึกฉบับร่างแล้ว (mock)'),
            child: const LocalizedText(
              'บันทึกฉบับร่าง',
              style: TextStyle(
                color: AppTheme.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _OpenShopStepper(current: _step, labels: _steps),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: [
                      _shopInfo(),
                      _contact(),
                      _address(),
                      _confirm(),
                    ][_step],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFEEEEEE)),
      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );

  Widget _sectionTitle(String title, {String? subtitle}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.orange,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 9),
          LocalizedText(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 9),
        LocalizedText(
          subtitle,
          style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
        ),
      ],
      const SizedBox(height: 20),
    ],
  );

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    bool required = false,
    int maxLines = 1,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocalizedText(
            '$label${required ? ' *' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: required ? Colors.black : const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: (value) {
              final error = validator?.call(value);
              if (error != null) {
                return AppLocalizations.of(context).source(error);
              }
              if (required && normalizeText(value).isEmpty) {
                return AppLocalizations.of(
                  context,
                ).source('กรุณากรอกข้อมูลที่จำเป็น');
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint == null
                  ? null
                  : AppLocalizations.of(context).source(hint),
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, color: AppTheme.textMuted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Color(0xFFE4E4E4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shopInfo() => Column(
    children: [
      _card([
        _sectionTitle('ข้อมูลร้านค้า', subtitle: 'กรอกข้อมูลร้านค้าของคุณ'),
        _field(
          'ชื่อร้านค้า',
          _name,
          hint: 'เช่น Suikai Phone Shop',
          required: true,
        ),
        const LocalizedText(
          'ประเภทร้านค้า *',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SuikaiService.categoryRecords('store', activeOnly: true)
              .map(
                (category) => ChoiceChip(
                  label: Text(
                    category.localizedName(
                      Localizations.localeOf(context).languageCode,
                    ),
                  ),
                  selected: _shopType == category.id,
                  selectedColor: AppTheme.orangeSoft,
                  side: BorderSide(
                    color: _shopType == category.id
                        ? AppTheme.orange
                        : const Color(0xFFE4E4E4),
                  ),
                  onSelected: (_) => setState(() => _shopType = category.id),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        _field(
          'คำอธิบายร้านค้า',
          _description,
          hint: 'แนะนำร้านค้าของคุณ บริการที่มี จุดเด่นของร้าน',
          required: true,
          maxLines: 5,
        ),
        const LocalizedText(
          'รูปภาพร้านค้า (โลโก้) *',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _UploadBox(
          icon: Icons.add_business_rounded,
          title: 'เพิ่มรูปโลโก้ร้านค้า',
          subtitle: 'ขนาดแนะนำ 1:1  •  JPG, PNG ไม่เกิน 5MB',
          selectedImage: _logoImage,
          onTap: () => _pickStoreImage(logo: true),
        ),
        const SizedBox(height: 18),
        const LocalizedText(
          'รูปภาพหน้าปกร้านค้า',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _UploadBox(
          icon: Icons.add_photo_alternate_outlined,
          title: 'เพิ่มรูปหน้าปกร้านค้า',
          subtitle: 'ขนาดแนะนำ 16:9  •  JPG, PNG ไม่เกิน 10MB',
          selectedImage: _coverImage,
          onTap: () => _pickStoreImage(logo: false),
        ),
      ]),
      const SizedBox(height: 18),
      _primaryButton('ถัดไป', _next),
      const SizedBox(height: 10),
      _secondaryButton('ยกเลิก', () => Navigator.pop(context)),
    ],
  );

  Widget _contact() => Column(
    children: [
      _card([
        _sectionTitle(
          'ข้อมูลติดต่อร้านค้า',
          subtitle:
              'ข้อมูลนี้จะแสดงให้ลูกค้าเห็นเพื่อใช้ติดต่อกับร้านค้าของคุณ',
        ),
        _field(
          'เบอร์โทรศัพท์ร้านค้า',
          _phone,
          hint: 'เช่น 09 1234 5678',
          required: true,
          icon: Icons.phone_outlined,
          validator: validatePhone,
          keyboardType: TextInputType.phone,
        ),
        _field(
          'เบอร์โทร Viber',
          _viber,
          hint: 'เช่น 09 1234 5678',
          icon: Icons.phone_in_talk_outlined,
        ),
        _field(
          'อีเมล (ถ้ามี)',
          _email,
          hint: 'เช่น suikai@gmail.com',
          icon: Icons.mail_outline_rounded,
          validator: validateEmail,
          keyboardType: TextInputType.emailAddress,
        ),
        const LocalizedText(
          'เวลาทำการร้านค้า',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['เปิดทุกวัน', 'กำหนดเวลา', 'ปิดชั่วคราว']
              .map(
                (e) => ChoiceChip(
                  label: LocalizedText(e),
                  selected: _hours == e,
                  selectedColor: AppTheme.orangeSoft,
                  onSelected: (_) => setState(() => _hours = e),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        _InfoBox(
          icon: Icons.info_outline_rounded,
          text: 'ข้อมูลติดต่อที่ชัดเจน จะช่วยให้ลูกค้าติดต่อคุณได้ง่ายขึ้น',
        ),
      ]),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(child: _secondaryButton('ย้อนกลับ', _back)),
          const SizedBox(width: 12),
          Expanded(child: _primaryButton('ถัดไป', _next)),
        ],
      ),
    ],
  );

  Widget _address() => Column(
    children: [
      _card([
        _sectionTitle(
          'ที่อยู่ร้านค้า',
          subtitle:
              'ระบุที่อยู่ของร้านค้า เพื่อให้ลูกค้าค้นหาร้านค้าของคุณได้ง่ายขึ้น',
        ),
        const LocalizedText(
          'ที่อยู่ร้านค้า *',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE4E4E4)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppTheme.orange),
              SizedBox(width: 10),
              Expanded(
                child: LocalizedText(
                  'บ้านน้ำจ๋าง, เมืองน้ำจ๋าง, รัฐฉาน\nใกล้ ตลาดสดน้ำจ๋าง',
                ),
              ),
              LocalizedText(
                'แก้ไข',
                style: TextStyle(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: CustomPaint(painter: _MiniMapPainter()),
              ),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppTheme.orange.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppTheme.orange,
                  size: 48,
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: FloatingActionButton.small(
                  heroTag: 'shopGps',
                  backgroundColor: Colors.white,
                  onPressed: _captureStoreLocation,
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _field(
          'รายละเอียดเพิ่มเติม',
          _locationDetail,
          hint: 'เช่น ใกล้ปั๊มน้ำมัน, ติดถนนใหญ่, อยู่ในหมู่บ้าน...',
          maxLines: 4,
        ),
        const _InfoBox(
          icon: Icons.info_outline_rounded,
          text:
              'ตำแหน่งร้านค้าจะช่วยให้ลูกค้าค้นหาร้านของคุณในพื้นที่ใกล้เคียงได้ง่ายขึ้น',
        ),
      ]),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(child: _secondaryButton('ย้อนกลับ', _back)),
          const SizedBox(width: 12),
          Expanded(child: _primaryButton('ถัดไป', _next)),
        ],
      ),
    ],
  );

  Widget _confirm() => Column(
    children: [
      _card([
        _sectionTitle(
          'ยืนยันการเปิดร้าน',
          subtitle: 'ตรวจสอบข้อมูลทั้งหมดก่อนยืนยันการเปิดร้านค้าของคุณ',
        ),
        _SummaryBox(
          icon: Icons.storefront_outlined,
          title: 'ข้อมูลร้านค้า',
          lines: [
            'ชื่อร้านค้า   ${_name.text.isEmpty ? 'Suikai Phone Shop' : _name.text}',
            'ประเภทร้านค้า   ' +
                (_shopType.isEmpty
                    ? '-'
                    : _categoryLabel(context, 'store', _shopType)),
          ],
          onEdit: () => setState(() => _step = 0),
        ),
        const SizedBox(height: 14),
        _SummaryBox(
          icon: Icons.phone_in_talk_outlined,
          title: 'ข้อมูลติดต่อ',
          lines: [
            'เบอร์โทรศัพท์   ${_phone.text.isEmpty ? '-' : _phone.text}',
            'Viber   ${_viber.text.isEmpty ? '-' : _viber.text}',
            if (_email.text.isNotEmpty) 'อีเมล   ${_email.text}',
          ],
          onEdit: () => setState(() => _step = 1),
        ),
        const SizedBox(height: 14),
        _SummaryBox(
          icon: Icons.location_on_outlined,
          title: 'ที่อยู่ร้านค้า',
          lines: const [
            'บ้านน้ำจ๋าง, เมืองน้ำจ๋าง, รัฐฉาน',
            'ใกล้ ตลาดสดน้ำจ๋าง',
          ],
          onEdit: () => setState(() => _step = 2),
        ),
        const SizedBox(height: 18),
        const _InfoBox(
          icon: Icons.verified_user_outlined,
          text:
              'เมื่อกดยืนยัน ร้านค้าของคุณจะถูกส่งให้ Admin ตรวจสอบก่อนเปิดใช้งาน',
          success: true,
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppTheme.orange,
          value: _accepted,
          onChanged: (v) => setState(() => _accepted = v ?? false),
          title: const LocalizedText(
            'ฉันยอมรับเงื่อนไขการใช้งานและนโยบายของ Suikai',
            style: TextStyle(fontSize: 14),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        _primaryButton(
          _submitting ? 'กำลังบันทึก...' : 'ยืนยันการเปิดร้าน',
          _accepted && !_submitting
              ? () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  final phone = normalizePhone(_phone.text);
                  if (phone.isEmpty) {
                    showInfo(context, 'กรุณากรอกเบอร์โทร');
                    return;
                  }
                  final email = normalizeText(_email.text);
                  if (email.isNotEmpty && validateEmail(email) != null) {
                    showInfo(context, 'กรุณากรอกอีเมลให้ถูกต้อง');
                    return;
                  }
                  if (_logoImage == null) {
                    showInfo(context, 'กรุณาเพิ่มรูปโลโก้ร้านค้า');
                    return;
                  }
                  setState(() => _submitting = true);
                  try {
                    await SuikaiService.createStore(
                      name: normalizeText(_name.text),
                      description: normalizeText(_description.text),
                      category: _shopType,
                      city: 'เมืองนาง',
                      phone: phone,
                      viber: normalizePhone(_viber.text),
                      hours: _hours == 'เปิดทุกวัน'
                          ? '09:00-18:00'
                          : '09:00-18:00',
                      logo: _logoImage!,
                      cover: _coverImage,
                      email: email.isEmpty ? null : email,
                      latitude: _storePosition?.latitude,
                      longitude: _storePosition?.longitude,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    showInfo(context, 'ส่งคำขอเปิดร้านแล้ว รอการอนุมัติ');
                    Navigator.pop(context, true);
                  } catch (_) {
                    if (!context.mounted) {
                      return;
                    }
                    showInfo(context, 'ส่งคำขอเปิดร้านไม่สำเร็จ');
                    setState(() => _submitting = false);
                  }
                }
              : null,
          icon: Icons.storefront_outlined,
        ),
        const SizedBox(height: 10),
        const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 15, color: AppTheme.textMuted),
              SizedBox(width: 5),
              LocalizedText(
                'ข้อมูลของคุณจะถูกเก็บเป็นความลับ',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ]),
    ],
  );

  Widget _primaryButton(
    String text,
    VoidCallback? onPressed, {
    IconData? icon,
  }) => SizedBox(
    width: double.infinity,
    height: 54,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon),
      label: LocalizedText(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.orange,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFFFB28F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  Widget _secondaryButton(String text, VoidCallback onPressed) => SizedBox(
    width: double.infinity,
    height: 54,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.orange,
        side: const BorderSide(color: AppTheme.orange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: LocalizedText(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _OpenShopStepper extends StatelessWidget {
  final int current;
  final List<String> labels;
  const _OpenShopStepper({required this.current, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(labels.length, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: i <= current
                              ? AppTheme.orange
                              : const Color(0xFFD7D7D7),
                        ),
                      ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? AppTheme.orange : Colors.white,
                        border: Border.all(
                          color: (done || active)
                              ? AppTheme.orange
                              : const Color(0xFFC8C8C8),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: done
                          ? const Icon(
                              Icons.check,
                              size: 18,
                              color: AppTheme.orange,
                            )
                          : LocalizedText(
                              '${i + 1}',
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : AppTheme.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                    if (i < labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: i < current
                              ? AppTheme.orange
                              : const Color(0xFFD7D7D7),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LocalizedText(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: active ? AppTheme.orange : AppTheme.textMuted,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _UploadBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final SelectedImage? selectedImage;
  const _UploadBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selectedImage,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      height: 145,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDADADA)),
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFFFFDFC),
      ),
      child: selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                selectedImage!.bytes,
                width: double.infinity,
                height: 145,
                fit: BoxFit.cover,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppTheme.orange, size: 38),
                const SizedBox(height: 8),
                LocalizedText(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                LocalizedText(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
    ),
  );
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool success;
  const _InfoBox({
    required this.icon,
    required this.text,
    this.success = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: success ? const Color(0xFFF1FAF4) : const Color(0xFFF0F7FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: success ? const Color(0xFF159447) : const Color(0xFF1672C4),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: LocalizedText(
            text,
            style: TextStyle(
              color: success
                  ? const Color(0xFF23753F)
                  : const Color(0xFF236397),
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SummaryBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> lines;
  final VoidCallback onEdit;
  const _SummaryBox({
    required this.icon,
    required this.title,
    required this.lines,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE7E7E7)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            color: AppTheme.orangeSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LocalizedText(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              ...lines.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: LocalizedText(
                    e,
                    style: const TextStyle(color: Color(0xFF555555)),
                  ),
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, size: 16),
          label: const LocalizedText('แก้ไข'),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.orange,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    ),
  );
}

class _MiniMapPainter extends CustomPainter {
  const _MiniMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = const Color(0xFFD9E0E5)
      ..strokeWidth = 3;
    final small = Paint()
      ..color = const Color(0xFFE7EBEE)
      ..strokeWidth = 1.4;
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y * .86), small);
    }
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6;
      canvas.drawLine(Offset(x, 0), Offset(x * .9, size.height), small);
    }
    canvas.drawLine(
      Offset(0, size.height * .7),
      Offset(size.width, size.height * .3),
      road,
    );
    canvas.drawLine(
      Offset(size.width * .2, 0),
      Offset(size.width * .75, size.height),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProductCard extends StatelessWidget {
  final MockProduct product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        SuikaiRoutes.productDetail,
        arguments: product.id,
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 55,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  persistentImage(
                    product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, stackTrace) =>
                        Container(color: const Color(0xFFF3F3F3)),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: GestureDetector(
                      onTap: () {
                        final added = InteractionStore.addLike(product.id);
                        showInfo(
                          context,
                          added ? 'ถูกใจแล้ว' : 'อุปกรณ์นี้เคยกด Like แล้ว',
                        );
                      },
                      child: ValueListenableBuilder<Set<String>>(
                        valueListenable: InteractionStore.likedIds,
                        builder: (context, liked, _) {
                          final isLiked = liked.contains(product.id);
                          return Icon(
                            isLiked
                                ? Icons.thumb_up
                                : Icons.thumb_up_alt_outlined,
                            color: Colors.white,
                            size: 21,
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    left: 7,
                    right: 7,
                    bottom: 7,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: LocalizedText(
                          product.price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 7,
                    top: 7,
                    child: _cardStatusMarker(product.status),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 45,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: LocalizedText(
                            product.location,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: LocalizedText(
                            product.time,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFFAAAAAA),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.thumb_up_alt_outlined,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 2),
                        LocalizedText(
                          '${product.likeCount + (InteractionStore.isLiked(product.id) ? 1 : 0)}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _statusChip(BuildContext context, ProductStatus status) {
  final label = _statusLabel(context, status);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: LocalizedText(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: status.color, fontWeight: FontWeight.w700),
    ),
  );
}

String _statusLabel(BuildContext context, ProductStatus status) {
  final l10n = AppLocalizations.of(context);
  return switch (status) {
    ProductStatus.available => l10n.available,
    ProductStatus.reserved => l10n.reserved,
    ProductStatus.sold => l10n.sold,
    ProductStatus.outOfStock => l10n.outOfStock,
    ProductStatus.deleted => l10n.deleted,
  };
}

Widget _statusDot(ProductStatus status, {double size = 10}) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
);

Widget _cardStatusMarker(ProductStatus status) => Container(
  width: 14,
  height: 14,
  padding: const EdgeInsets.all(3),
  decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    border: Border.all(color: status.color),
  ),
  child: _statusDot(status, size: 6),
);

class _PostIcon extends StatelessWidget {
  const _PostIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: AppTheme.orange,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 31),
    );
  }
}

class _MissingPage extends StatelessWidget {
  final String title;

  const _MissingPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const LocalizedText('Suikai')),
      body: Center(child: LocalizedText(title)),
    );
  }
}
