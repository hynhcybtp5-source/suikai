import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

class SuikaiRoutes {
  static const home = '/';
  static const stores = '/stores';
  static const post = '/post';
  static const map = '/map';
  static const profile = '/profile';
  static const search = '/search';
  static const storeDetail = '/store-detail';
  static const productDetail = '/product-detail';
  static const report = '/report';
  static const openShop = '/open-shop';

  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const HomePage(),
    stores: (_) => const StoreListPage(),
    post: (_) => const PostPage(),
    map: (_) => const MapPage(),
    profile: (_) => const ProfilePage(),
    search: (_) => const SearchPage(),
    openShop: (_) => const OpenShopPage(),
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

extension ProductStatusX on ProductStatus {
  String get label {
    switch (this) {
      case ProductStatus.available:
        return 'พร้อมขาย';
      case ProductStatus.reserved:
        return 'จอง';
      case ProductStatus.sold:
        return 'ขายแล้ว';
      case ProductStatus.outOfStock:
        return 'หมด';
      case ProductStatus.deleted:
        return 'ลบ';
    }
  }

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
  });
}

class MockProduct {
  final String id;
  final String title;
  final String price;
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

  const MockProduct({
    required this.id,
    required this.title,
    required this.price,
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
  });

  bool get isStoreProduct => storeId != null;
}

class MockRepo {
  static const stores = [
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

  static const products = [
    MockProduct(
      id: 'p1',
      title: 'Toyota Vios 2019',
      price: '325,000 ฿',
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
      price: '18,500 ฿',
      description: 'เครื่องศูนย์ แบตดี 88%',
      category: 'มือถือ & แท็บเล็ต',
      city: 'เมืองนาง',
      location: 'น้ำจ่าง, เมืองนาง',
      time: '3 ชั่วโมงที่แล้ว',
      image:
          'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?auto=format&fit=crop&w=700&q=80',
      phone: '0201110002',
      viber: '0201110002',
      likeCount: 27,
      viewCount: 530,
      status: ProductStatus.available,
    ),
    MockProduct(
      id: 'p3',
      title: 'โซฟา 3 ที่นั่ง สภาพดี',
      price: '4,200 ฿',
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
      price: '28,000 ฿',
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
      price: '21,500 ฿',
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
      price: '12,900 ฿',
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
      price: '7,800 ฿',
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
      price: '265,000 ฿',
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
  ];

  static List<MockStore> get approvedStores =>
      stores.where((store) => store.approved).toList();

  static List<MockProduct> get feedProducts {
    return products.where((product) {
      if (product.status == ProductStatus.sold ||
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
}

class InteractionStore {
  static final likedIds = ValueNotifier<Set<String>>(<String>{});

  static bool isLiked(String productId) => likedIds.value.contains(productId);

  static bool addLike(String productId) {
    if (isLiked(productId)) {
      return false;
    }
    final next = Set<String>.from(likedIds.value)..add(productId);
    likedIds.value = next;
    return true;
  }
}

Future<void> launchPhone(String phone) async {
  final uri = Uri.parse('tel:$phone');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('cannot launch phone');
  }
}

Future<void> launchViber(String number) async {
  final nativeUri = Uri.parse('viber://chat?number=$number');
  if (await canLaunchUrl(nativeUri)) {
    await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
    return;
  }
  final webUri = Uri.parse('https://invite.viber.com/?number=$number');
  if (!await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
    throw Exception('cannot launch viber');
  }
}

void showInfo(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
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
    Navigator.pushReplacementNamed(context, routeByIndex[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: selectedIndex,
        indicatorColor: Colors.transparent,
        backgroundColor: Colors.white,
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.orange),
            label: 'หน้าแรก',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(
              Icons.storefront_rounded,
              color: AppTheme.orange,
            ),
            label: 'ร้านค้า',
          ),
          NavigationDestination(
            icon: _PostIcon(),
            selectedIcon: _PostIcon(),
            label: '+ประกาศขาย',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded, color: AppTheme.orange),
            label: 'แผนที่',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.orange),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _language = 'ไทย';

  String _text(String th, String en, String my) {
    switch (_language) {
      case 'EN':
        return en;
      case 'မြန်မာ':
        return my;
      default:
        return th;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = MockRepo.feedProducts;
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
                    childAspectRatio: width >= 1024 ? .78 : .70,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Suikai',
                  style: TextStyle(
                    color: AppTheme.orange,
                    fontSize: 39,
                    height: .95,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _text(
                    'ซื้อขายง่าย ใกล้คุณ',
                    'Buy and sell easily nearby',
                    'အနီးအနားမှာ လွယ်လွယ်ကူကူ ဝယ်/ရောင်းနိုင်ပါတယ်',
                  ),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            initialValue: _language,
            onSelected: (value) => setState(() => _language = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'ไทย', child: Text('ไทย')),
              PopupMenuItem(value: 'EN', child: Text('English')),
              PopupMenuItem(value: 'မြန်မာ', child: Text('မြန်မာ')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.orangeSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _language,
                style: const TextStyle(color: AppTheme.orange),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _roundIcon(
            icon: Icons.location_on_rounded,
            onTap: () => Navigator.pushNamed(context, SuikaiRoutes.map),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _roundIcon(
                icon: Icons.notifications_none_rounded,
                onTap: () => showInfo(context, 'Mock notification'),
              ),
              Positioned(
                right: 2,
                top: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppTheme.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundIcon({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppTheme.orangeSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.orange, size: 27),
      ),
    );
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
          Text(
            _text(
              'ช่วงวงเงินที่ต้องการหา',
              'Price range',
              'ဈေးနှုန်းအပိုင်းအခြား',
            ),
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
                  child: const Row(
                    children: [
                      Text(
                        '฿',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text('0', style: TextStyle(fontSize: 16)),
                      Spacer(),
                      Text('-', style: TextStyle(fontSize: 16)),
                      Spacer(),
                      Text(
                        '100 ล้าน',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 20,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => Navigator.pushNamed(context, SuikaiRoutes.search),
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
            child: Image.network(
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
                Text(
                  _text(
                    'ขายไว ได้จริง',
                    'Fast and real sales',
                    'မြန်ဆန်ပြီးစစ်မှန်တဲ့ရောင်းဝယ်မှု',
                  ),
                  style: const TextStyle(
                    color: AppTheme.orangeDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 29,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _text(
                    'ลงประกาศกับ Suikai',
                    'Post with Suikai',
                    'Suikai နဲ့ ကြော်ငြာတင်လိုက်ပါ',
                  ),
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color(0xFF675A52),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => Navigator.pushNamed(context, SuikaiRoutes.post),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.orange,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      _text('ลงประกาศเลย', 'Post now', 'ယနေ့တင်လိုက်ပါ'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
    final categories = [
      (Icons.grid_view_rounded, _text('ทั้งหมด', 'All', 'အားလုံး')),
      (Icons.directions_car_rounded, _text('ยานพาหนะ', 'Vehicles', 'ယာဉ်')),
      (
        Icons.smartphone_rounded,
        _text('มือถือ & แท็บเล็ต', 'Phones & Tablets', 'ဖုန်း/တက်ဘ်လက်'),
      ),
      (
        Icons.chair_rounded,
        _text('บ้าน & สวน', 'Home & Garden', 'အိမ်/ဥယျာဉ်'),
      ),
      (Icons.checkroom_rounded, _text('แฟชั่น', 'Fashion', 'အဝတ်အစား')),
      (Icons.search_rounded, _text('ค้นหา', 'Search', 'ရှာဖွေ')),
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
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    SuikaiRoutes.search,
                    arguments: label == _text('ทั้งหมด', 'All', 'အားလုံး')
                        ? null
                        : label,
                  );
                },
                child: SizedBox(
                  width: 74,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: const BoxDecoration(
                          color: AppTheme.orangeSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.$1,
                          color: AppTheme.orange,
                          size: 23,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
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
          const Expanded(
            child: Text(
              'ประกาศล่าสุด',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
          InkWell(
            onTap: () => Navigator.pushNamed(context, SuikaiRoutes.search),
            child: Text(
              _text('ดูทั้งหมด  ›', 'View all  ›', 'အားလုံးကြည့်မယ်  ›'),
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
  String _selectedType = 'ทั้งหมด';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final types = <String>{
      'ทั้งหมด',
      ...MockRepo.approvedStores.map((s) => s.type),
    }.toList();
    final query = _searchController.text.toLowerCase().trim();
    final stores = MockRepo.approvedStores.where((store) {
      final matchesQuery =
          query.isEmpty ||
          store.name.toLowerCase().contains(query) ||
          store.city.toLowerCase().contains(query);
      final matchesType =
          _selectedType == 'ทั้งหมด' || store.type == _selectedType;
      return matchesQuery && matchesType;
    }).toList();

    return RootScaffold(
      selectedIndex: 1,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ร้านค้า',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'เลือกสิ่งที่ต้องการทำ',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _StoreActionCard(
                          icon: Icons.sell_outlined,
                          title: 'ประกาศทั่วไป',
                          subtitle: 'ลงขายได้ทันที',
                          onTap: () =>
                              Navigator.pushNamed(context, SuikaiRoutes.post),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StoreActionCard(
                          icon: Icons.add_business_outlined,
                          title: 'เปิดร้าน',
                          subtitle: 'ส่งคำขอเปิดร้าน',
                          onTap: () => Navigator.pushNamed(
                            context,
                            SuikaiRoutes.openShop,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ร้านค้าที่เปิดอยู่',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'ค้นหาชื่อร้าน',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final type = types[index];
                  return ChoiceChip(
                    label: Text(type),
                    selected: _selectedType == type,
                    onSelected: (_) => setState(() => _selectedType = type),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
            sliver: SliverList.separated(
              itemCount: stores.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final store = stores[index];
                return InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    SuikaiRoutes.storeDetail,
                    arguments: store.id,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            store.logo,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 68,
                              height: 68,
                              color: AppTheme.orangeSoft,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.storefront_rounded,
                                color: AppTheme.orange,
                                size: 30,
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
                                store.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                store.type,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 15,
                                    color: AppTheme.textMuted,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    store.city,
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
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textMuted,
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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.orangeSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.orange.withOpacity(.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.orange, size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreDetailPage extends StatelessWidget {
  final String storeId;

  const StoreDetailPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final store = MockRepo.storeById(storeId);
    if (store == null) {
      return const _MissingPage(title: 'ไม่พบร้าน');
    }
    final products = MockRepo.productsByStore(store.id);

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดร้าน')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
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
                    Text(
                      store.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(store.description),
                    const SizedBox(height: 4),
                    Text(
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
                  label: const Text('โทร'),
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
                  label: const Text('Viber'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
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
                        child: Image.network(
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
                            Text(
                              product.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.price,
                              style: const TextStyle(
                                color: AppTheme.orange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _statusChip(product.status),
                          ],
                        ),
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

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  String _postType = 'ประกาศทั่วไป';
  ProductStatus _generalStatus = ProductStatus.available;
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController(text: '0209990000');
  final _viberController = TextEditingController(text: '0209990000');
  String _city = 'เมืองนาง';
  String _category = 'ยานพาหนะ';
  String _imageUrl =
      'https://images.unsplash.com/photo-1515923256482-1c04580b477c?auto=format&fit=crop&w=800&q=80';

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _phoneController.dispose();
    _viberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RootScaffold(
      selectedIndex: 2,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ลงประกาศ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, SuikaiRoutes.openShop),
                child: const Text('เปิดร้าน'),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            initialValue: _postType,
            decoration: const InputDecoration(labelText: 'ประเภทประกาศ'),
            items: const [
              DropdownMenuItem(
                value: 'ประกาศทั่วไป',
                child: Text('ประกาศทั่วไป'),
              ),
              DropdownMenuItem(value: 'สินค้าร้าน', child: Text('สินค้าร้าน')),
            ],
            onChanged: (value) =>
                setState(() => _postType = value ?? _postType),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              setState(() {
                _imageUrl =
                    'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=800&q=80';
              });
              showInfo(context, 'เลือกภาพ mock แล้ว');
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 170,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(_imageUrl, fit: BoxFit.cover),
                  Container(
                    color: const Color(0x22000000),
                    alignment: Alignment.center,
                    child: const Text(
                      'แตะเพื่อเลือกรูปสินค้า',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'ชื่อสินค้า'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'รายละเอียด'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'หมวดหมู่'),
            items: const [
              'ยานพาหนะ',
              'มือถือ & แท็บเล็ต',
              'บ้าน & สวน',
              'แฟชั่น',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (value) =>
                setState(() => _category = value ?? _category),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'ราคา'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _city,
            decoration: const InputDecoration(labelText: 'เมือง'),
            items: const [
              'เมืองนาง',
              'หาดคำ',
              'หนองบัว',
            ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (value) => setState(() => _city = value ?? _city),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'เบอร์โทร'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _viberController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Viber'),
          ),
          if (_postType == 'ประกาศทั่วไป') ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<ProductStatus>(
              initialValue: _generalStatus,
              decoration: const InputDecoration(labelText: 'สถานะ'),
              items:
                  const [
                        ProductStatus.available,
                        ProductStatus.reserved,
                        ProductStatus.sold,
                      ]
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(
                () => _generalStatus = value ?? ProductStatus.available,
              ),
            ),
          ],
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) {
                showInfo(context, 'กรุณากรอกชื่อสินค้า');
                return;
              }
              if (_postType == 'ประกาศทั่วไป') {
                showInfo(context, 'ประกาศทั่วไปลงได้ทันที (mock)');
              } else {
                showInfo(context, 'สินค้าร้านบันทึกแล้ว (mock)');
              }
            },
            child: const Text('ลงประกาศ'),
          ),
        ],
      ),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  _MapMarker? _selected;

  @override
  Widget build(BuildContext context) {
    final markers = [
      for (final store in MockRepo.approvedStores)
        _MapMarker(
          id: store.id,
          title: store.name,
          subtitle: 'ร้านค้า • ${store.city}',
          route: SuikaiRoutes.storeDetail,
          argument: store.id,
        ),
      for (final product in MockRepo.feedProducts.take(5))
        _MapMarker(
          id: product.id,
          title: product.title,
          subtitle: 'ประกาศ • ${product.city}',
          route: SuikaiRoutes.productDetail,
          argument: product.id,
        ),
    ];

    return RootScaffold(
      selectedIndex: 3,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SuikaiMapPainter())),
          const Positioned(
            top: 18,
            left: 70,
            right: 70,
            child: Center(
              child: Text(
                'แผนที่',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 14,
            child: _MapRoundButton(
              icon: Icons.arrow_back_rounded,
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, SuikaiRoutes.home);
                }
              },
            ),
          ),
          Positioned(
            top: 12,
            right: 14,
            child: _MapRoundButton(
              icon: Icons.my_location_rounded,
              onTap: () => showInfo(
                context,
                'ค้นหาตำแหน่งปัจจุบัน (จะเชื่อม GPS ในขั้นระบบจริง)',
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                for (var i = 0; i < markers.length; i++)
                  Positioned(
                    left:
                        (34.0 +
                                ((i * 79.0) %
                                    ((c.maxWidth - 80).clamp(120.0, 1200.0))))
                            .toDouble(),
                    top:
                        (100.0 +
                                ((i * 113.0) %
                                    ((c.maxHeight - 250).clamp(180.0, 1200.0))))
                            .toDouble(),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = markers[i]),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.orange,
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
                          i < MockRepo.approvedStores.length
                              ? Icons.storefront_rounded
                              : Icons.sell_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_selected != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 5,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    _selected!.route,
                    arguments: _selected!.argument,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppTheme.orangeSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppTheme.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selected!.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _selected!.subtitle,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
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
        child: Icon(icon, color: AppTheme.orange),
      ),
    ),
  );
}

class _SuikaiMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFF4F3EE),
    );
    final green = Paint()..color = const Color(0xFFE5F0DF);
    final water = Paint()..color = const Color(0xFFDCEEF7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .05,
          size.height * .13,
          size.width * .28,
          size.height * .18,
        ),
        const Radius.circular(28),
      ),
      green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .70,
          size.height * .48,
          size.width * .26,
          size.height * .20,
        ),
        const Radius.circular(30),
      ),
      green,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .02,
          size.height * .63,
          size.width * .25,
          size.height * .15,
        ),
        const Radius.circular(30),
      ),
      water,
    );
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 13
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final smallRoad = Paint()
      ..color = const Color(0xFFFFFDF9)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-20, size.height * .30)
        ..cubicTo(
          size.width * .25,
          size.height * .22,
          size.width * .62,
          size.height * .48,
          size.width + 20,
          size.height * .35,
        ),
      road,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .20, -10)
        ..cubicTo(
          size.width * .28,
          size.height * .28,
          size.width * .38,
          size.height * .60,
          size.width * .52,
          size.height + 20,
        ),
      road,
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .72, -10)
        ..cubicTo(
          size.width * .64,
          size.height * .32,
          size.width * .80,
          size.height * .62,
          size.width * .70,
          size.height + 20,
        ),
      smallRoad,
    );
    canvas.drawPath(
      Path()
        ..moveTo(-10, size.height * .72)
        ..cubicTo(
          size.width * .32,
          size.height * .62,
          size.width * .60,
          size.height * .83,
          size.width + 20,
          size.height * .70,
        ),
      smallRoad,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapMarker {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final String argument;
  const _MapMarker({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.argument,
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _tab = 'ประกาศของฉัน';
  final Map<String, ProductStatus> _statusEdits = {
    for (final p in MockRepo.managedProducts) p.id: p.status,
  };

  @override
  Widget build(BuildContext context) {
    final all = MockRepo.managedProducts;
    final items = _tab == 'ร้านของฉัน'
        ? all.where((p) => p.isStoreProduct).toList()
        : all.where((p) => !p.isStoreProduct).toList();
    final likes = all.fold<int>(0, (sum, p) => sum + p.likeCount);
    final views = all.fold<int>(0, (sum, p) => sum + p.viewCount);

    return RootScaffold(
      selectedIndex: 4,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        children: [
          const Text(
            'จัดการของฉัน',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
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
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppTheme.orange,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'บัญชีผู้ขาย',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
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
                  onPressed: () =>
                      showInfo(context, 'ตั้งค่าบัญชีจะเชื่อมในขั้นระบบจริง'),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(label: 'ประกาศ', value: '${all.length}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(label: 'ถูกใจ', value: '$likes'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatBox(label: 'เข้าชม', value: '$views'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, SuikaiRoutes.post),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('ลงประกาศ'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, SuikaiRoutes.openShop),
                  icon: const Icon(Icons.storefront_rounded),
                  label: const Text('เปิดร้าน'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'ประกาศของฉัน',
                label: Text('ประกาศของฉัน'),
                icon: Icon(Icons.sell_outlined),
              ),
              ButtonSegment(
                value: 'ร้านของฉัน',
                label: Text('ร้านของฉัน'),
                icon: Icon(Icons.store_outlined),
              ),
            ],
            selected: {_tab},
            onSelectionChanged: (v) => setState(() => _tab = v.first),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Text(
                _tab == 'ร้านของฉัน' ? 'ยังไม่มีสินค้าร้าน' : 'ยังไม่มีประกาศ',
                style: const TextStyle(color: AppTheme.textMuted),
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
                          child: Image.network(
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
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.price,
                                style: const TextStyle(
                                  color: AppTheme.orange,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
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
                      decoration: const InputDecoration(
                        labelText: 'สถานะสินค้า',
                        isDense: true,
                      ),
                      items:
                          (item.isStoreProduct
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
                                  child: Text(status.label),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _statusEdits[item.id] = value);
                      },
                    ),
                  ],
                ),
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
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.orange,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    ),
  );
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  String _category = 'ทั้งหมด';
  String _city = 'ทั้งหมด';
  int _maxPrice = 100000000;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initialCategory =
        ModalRoute.of(context)?.settings.arguments as String?;
    if (initialCategory != null && _category == 'ทั้งหมด') {
      _category = initialCategory;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>{
      'ทั้งหมด',
      ...MockRepo.products.map((p) => p.category),
    }.toList();
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
          _category == 'ทั้งหมด' || product.category == _category;
      final matchesCity = _city == 'ทั้งหมด' || product.city == _city;
      final matchesPrice = p <= _maxPrice;
      return matchesQuery && matchesCategory && matchesCity && matchesPrice;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('ค้นหา')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'ค้นหาสินค้า',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'หมวดหมู่'),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _category = value ?? _category),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _city,
                    decoration: const InputDecoration(labelText: 'เมือง'),
                    items: cities
                        .map(
                          (city) =>
                              DropdownMenuItem(value: city, child: Text(city)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _city = value ?? _city),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Text('ราคาไม่เกิน'),
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
                Text(_maxPrice >= 100000000 ? '100 ล้าน+' : '฿$_maxPrice'),
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
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                  itemCount: results.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 12,
                    childAspectRatio: width >= 760 ? .78 : .73,
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
}

class ProductDetailPage extends StatelessWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final product = MockRepo.productById(productId);
    if (product == null) {
      return const _MissingPage(title: 'ไม่พบสินค้า');
    }
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดสินค้า')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                product.image,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stackTrace) =>
                    Container(color: const Color(0xFFF1F1F1)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            product.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            product.price,
            style: const TextStyle(
              color: AppTheme.orange,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _statusChip(product.status),
          const SizedBox(height: 8),
          Text(product.description),
          const SizedBox(height: 10),
          Text('เมือง: ${product.city}'),
          const SizedBox(height: 4),
          Text('Like ${product.likeCount} • View ${product.viewCount}'),
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
                  label: const Text('โทร'),
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
                  label: const Text('Viber'),
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
            label: const Text('Report'),
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
      appBar: AppBar(title: const Text('Report')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          Text('สินค้า: ${widget.productId}'),
          const SizedBox(height: 12),
          const Text(
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
                  RadioListTile<String>(value: reason, title: Text(reason)),
              ],
            ),
          ),
          TextField(
            controller: _detailController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'รายละเอียดเพิ่มเติม'),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              showInfo(context, 'ส่งรายงานแล้ว (mock)');
              Navigator.pop(context);
            },
            child: const Text('ส่งรายงาน'),
          ),
        ],
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
  final _nameController = TextEditingController();
  final _detailController = TextEditingController();
  final _phoneController = TextEditingController(text: '0207770000');
  final _viberController = TextEditingController(text: '0207770000');
  final _hoursController = TextEditingController(text: '09:00 - 18:00');
  String _type = 'ยานพาหนะ';
  String _location = 'เมืองนาง';
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    _phoneController.dispose();
    _viberController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เปิดร้าน')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'ชื่อร้าน'),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => showInfo(context, 'เลือกโลโก้ mock แล้ว'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.orangeSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              alignment: Alignment.center,
              child: const Text('แตะเพื่อเลือกโลโก้ร้าน'),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'ประเภทร้าน'),
            items:
                const ['ยานพาหนะ', 'มือถือ & แท็บเล็ต', 'บ้าน & สวน', 'แฟชั่น']
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _detailController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'รายละเอียดร้าน'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'เบอร์โทร'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _viberController,
            decoration: const InputDecoration(labelText: 'Viber'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _hoursController,
            decoration: const InputDecoration(labelText: 'เวลาเปิดปิด'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _location,
            decoration: const InputDecoration(labelText: 'Location (mock)'),
            items: const ['เมืองนาง', 'หาดคำ', 'หนองบัว']
                .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                .toList(),
            onChanged: (value) =>
                setState(() => _location = value ?? _location),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              setState(() => _submitted = true);
              showInfo(context, 'ส่งคำขอเปิดร้านแล้ว (mock)');
            },
            child: const Text('ส่งคำขอเปิดร้าน'),
          ),
          if (_submitted)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.orangeSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'สถานะ: รออนุมัติ',
                style: TextStyle(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
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
                  Image.network(
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
                    bottom: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.price,
                        style: const TextStyle(
                          color: AppTheme.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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
                    Text(
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
                          child: Text(
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
                          child: Text(
                            product.time,
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
                        Text(
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

Widget _statusChip(ProductStatus status) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: status.color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      status.label,
      style: TextStyle(color: status.color, fontWeight: FontWeight.w700),
    ),
  );
}

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
      appBar: AppBar(title: const Text('Suikai')),
      body: Center(child: Text(title)),
    );
  }
}
