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

  static const _categories = <_StoreCategoryData>[
    _StoreCategoryData('ร้านอาหาร', Icons.restaurant_rounded),
    _StoreCategoryData('ร้านกาแฟ', Icons.local_cafe_rounded),
    _StoreCategoryData('ร้านซ่อมรถ', Icons.car_repair_rounded),
    _StoreCategoryData('ร้านหมูกะทะ', Icons.soup_kitchen_rounded),
    _StoreCategoryData('ร้านปิ้งย่าง', Icons.outdoor_grill_rounded),
    _StoreCategoryData('ร้านซุปเปอร์มาร์เก็ต', Icons.shopping_basket_rounded),
    _StoreCategoryData('ร้านเสริมสวย', Icons.content_cut_rounded),
    _StoreCategoryData('สัตว์เลี้ยง', Icons.pets_rounded),
    _StoreCategoryData('ร้านขายยา', Icons.medical_services_rounded),
    _StoreCategoryData('ทั้งหมด', Icons.grid_view_rounded),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase().trim();
    final stores = MockRepo.approvedStores.where((store) {
      final matchesQuery =
          query.isEmpty ||
          store.name.toLowerCase().contains(query) ||
          store.type.toLowerCase().contains(query) ||
          store.city.toLowerCase().contains(query);
      final matchesType =
          _selectedType == 'ทั้งหมด' ||
          store.type.contains(_selectedType.replaceFirst('ร้าน', '')) ||
          store.type == _selectedType;
      return matchesQuery && matchesType;
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
                  child: Text(
                    'ไม่พบร้านค้าในหมวดนี้',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 104),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _StoreGridCard(store: stores[index]),
                  childCount: stores.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.55,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _storeHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 18, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suikai',
                  style: TextStyle(
                    color: AppTheme.orange,
                    fontSize: 38,
                    height: .95,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.8,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'ซื้อขายง่าย ใกล้คุณ',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          _CircleHeaderButton(
            icon: Icons.location_on_rounded,
            onTap: () => Navigator.pushNamed(context, SuikaiRoutes.map),
          ),
          const SizedBox(width: 10),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _CircleHeaderButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {},
              ),
              const Positioned(
                right: 2,
                top: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.orange,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 8, height: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'ค้นหาร้านค้า, ประเภทร้าน',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เลือกประเภทที่ต้องการ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StoreActionCard(
                    icon: Icons.shopping_bag_rounded,
                    title: 'ประกาศทั่วไป',
                    subtitle: 'ลงขายสินค้า\nได้ทันที',
                    onTap: () =>
                        Navigator.pushNamed(context, SuikaiRoutes.post),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StoreActionCard(
                    icon: Icons.storefront_rounded,
                    title: 'เปิดร้านค้า',
                    subtitle: 'สร้างร้านของคุณ\nรอแอดมินอนุมัติ',
                    onTap: () =>
                        Navigator.pushNamed(context, SuikaiRoutes.openShop),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorySection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'หมวดหมู่ร้านค้า',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedType = 'ทั้งหมด'),
                child: const Text('ดูทั้งหมด  ›'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 13,
              crossAxisSpacing: 4,
              childAspectRatio: .82,
            ),
            itemBuilder: (context, index) {
              final item = _categories[index];
              final selected = _selectedType == item.title;
              return InkWell(
                onTap: () => setState(() => _selectedType = item.title),
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.orange : AppTheme.orangeSoft,
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
                      item.title,
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
              );
            },
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
            child: Text(
              'ร้านค้าแนะนำ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              _selectedType = 'ทั้งหมด';
              _searchController.clear();
            }),
            child: const Text('ดูทั้งหมด  ›'),
          ),
        ],
      ),
    );
  }
}

class _StoreCategoryData {
  final String title;
  final IconData icon;
  const _StoreCategoryData(this.title, this.icon);
}

class _CircleHeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleHeaderButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.orangeSoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppTheme.orange, size: 23),
        ),
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
                  Text(
                    title,
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
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
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        SuikaiRoutes.storeDetail,
        arguments: store.id,
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
            ClipOval(
              child: Image.network(
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
                    size: 27,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
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
                    store.type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
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
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFFFA000),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        store.id.hashCode.isEven ? '4.9' : '4.8',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 25,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 9),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: const BorderSide(color: AppTheme.orange),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          child: const Text(
                            'ติดตาม',
                            style: TextStyle(fontSize: 9.5),
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
  bool _showGeneralWizard = false;
  int _step = 0;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _detailsController = TextEditingController();
  final _phoneController = TextEditingController(text: '09 9999 9999');
  final _viberController = TextEditingController(text: '09 8888 8888');
  final _locationNoteController = TextEditingController();

  String _category = 'เลือกหมวดหมู่สินค้า';
  String _condition = 'มือหนึ่ง';
  bool _negotiable = false;
  String _address = 'บ้านน้ำจ๋าง, เมืองน้ำจ๋าง, รัฐฉาน\nใกล้ ตลาดสดน้ำจ๋าง';

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
    if (_step == 0 && _nameController.text.trim().isEmpty) {
      showInfo(context, 'กรุณาใส่ชื่อสินค้า');
      return;
    }
    if (_step < 3) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      setState(() => _showGeneralWizard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showGeneralWizard) return _buildTypeChooser();
    return _buildWizard();
  }

  Widget _buildTypeChooser() {
    return RootScaffold(
      selectedIndex: 2,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suikai',
                        style: TextStyle(
                          fontSize: 42,
                          height: 1,
                          color: AppTheme.orange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ซื้อขายง่าย ใกล้คุณ',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                _softCircleIcon(Icons.location_on_rounded),
                const SizedBox(width: 10),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _softCircleIcon(Icons.notifications_none_rounded),
                    const Positioned(
                      right: 1,
                      top: 0,
                      child: CircleAvatar(
                        radius: 5,
                        backgroundColor: AppTheme.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 52),
            const Text(
              'ประกาศขาย',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'เลือกประเภทการประกาศที่คุณต้องการ',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 30),
            _sellTypeCard(
              title: 'ขายสินค้าทั่วไป',
              subtitle:
                  'ประกาศขายสินค้ามือสอง หรือสินค้าใหม่\nที่คุณมีได้อย่างรวดเร็ว',
              leadingIcon: Icons.shopping_bag_rounded,
              trailingIcon: Icons.inventory_2_rounded,
              onTap: () => setState(() {
                _showGeneralWizard = true;
                _step = 0;
              }),
            ),
            const SizedBox(height: 18),
            _sellTypeCard(
              title: 'ร้านค้า',
              subtitle:
                  'เปิดร้านค้าของคุณ บริการลูกค้า\nและจัดการสินค้าได้ง่ายขึ้น',
              leadingIcon: Icons.storefront_rounded,
              trailingIcon: Icons.store_mall_directory_rounded,
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
                        Text(
                          'ปลอดภัย มั่นใจ ได้ทุกการซื้อขาย',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                child: Text(
                  'ลงขายสินค้าทั่วไป',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton(
                onPressed: () => showInfo(context, 'บันทึกฉบับร่างแล้ว (mock)'),
                child: const Text(
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
                        : Text(
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
              Text(
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
            value: _category == 'เลือกหมวดหมู่สินค้า' ? null : _category,
            hint: const Text('เลือกหมวดหมู่สินค้า'),
            decoration: _inputDecoration(),
            items: const [
              'มือถือ & แท็บเล็ต',
              'ยานพาหนะ',
              'บ้าน & สวน',
              'แฟชั่น',
              'อิเล็กทรอนิกส์',
              'อื่นๆ',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
          ),
          const SizedBox(height: 18),
          const _FieldLabel('ชื่อสินค้า *'),
          TextField(
            controller: _nameController,
            maxLength: 100,
            decoration: _inputDecoration(
              hint: 'ใส่ชื่อสินค้าที่ต้องการขาย',
              counter: true,
            ),
          ),
          const SizedBox(height: 10),
          const _FieldLabel('ราคา *'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    hint: 'ระบุราคา',
                    prefixText: '฿  ',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Switch.adaptive(
                value: _negotiable,
                activeColor: AppTheme.orange,
                onChanged: (v) => setState(() => _negotiable = v),
              ),
              const Text(
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
          TextField(
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
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              hint: 'เบอร์โทรศัพท์',
              prefixIcon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'เบอร์โทรที่จะแสดงให้ผู้สนใจติดต่อคุณ',
            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _viberController,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              hint: 'เบอร์โทร Viber',
              prefixIcon: Icons.phone_in_talk_outlined,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
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
          const Text(
            'เพิ่มรูปสินค้าได้สูงสุด 8 รูป โดยรูปแรกจะเป็นรูปหน้าปก',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 18),
          Container(
            height: 210,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD3B8)),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFFFE7D8),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: AppTheme.orange,
                    size: 32,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'เพิ่มรูปสินค้า',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 5),
                Text(
                  'แตะเพื่อเลือกจากคลังรูปหรือถ่ายภาพ',
                  style: TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(
              4,
              (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 8),
                  height: 78,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Icon(
                    i == 0 ? Icons.add_rounded : Icons.image_outlined,
                    color: AppTheme.textMuted,
                  ),
                ),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      showInfo(context, 'ใช้ตำแหน่งปัจจุบัน (mock)'),
                  icon: const Icon(Icons.location_on_rounded),
                  label: const Text('ตำแหน่งปัจจุบัน'),
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
                  label: const Text('เลือกบนแผนที่'),
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
                  child: Text(_address, style: const TextStyle(height: 1.55)),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
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
                      Text(
                        'ข้อมูลตำแหน่งจะถูกเก็บเป็นความลับ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 3),
                      Text(
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
    final price = _priceController.text.trim().isEmpty
        ? '18,500 ฿'
        : '${_priceController.text.trim()} ฿';
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
                  child: const Icon(
                    Icons.phone_iphone_rounded,
                    size: 76,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 22,
                        color: AppTheme.orange,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '☎  มือสอง สภาพดี',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '◈  ${_category == 'เลือกหมวดหมู่สินค้า' ? 'มือถือ & แท็บเล็ต' : _category}',
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
          const Text(
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
                      Text(
                        'เมื่อยืนยันการลงขาย',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 5),
                      Text(
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
              'ยืนยันการลงขาย',
              () => showInfo(context, 'ลงประกาศสำเร็จ (mock)'),
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
    required String title,
    required String subtitle,
    required IconData leadingIcon,
    required IconData trailingIcon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 180,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5EC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: const Color(0xFFFFDDC5),
              child: Icon(leadingIcon, size: 38, color: AppTheme.orange),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(trailingIcon, size: 58, color: const Color(0xFFFFB77E)),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.orange,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _softCircleIcon(IconData icon) => CircleAvatar(
    radius: 24,
    backgroundColor: const Color(0xFFFFF4EC),
    child: Icon(icon, color: AppTheme.orange),
  );

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
      hintText: hint,
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
              Text(
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
            Text(subtitle, style: const TextStyle(color: AppTheme.textMuted)),
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
              Text(
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

  Widget _primaryButton(String text, VoidCallback onTap) => SizedBox(
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
      child: Text(
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
      child: Text(
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
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
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
        child: Text(title, style: const TextStyle(color: AppTheme.textMuted)),
      ),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    child: Text(
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: AppTheme.textMuted)),
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
  int _step = 0;
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _viber = TextEditingController();
  final _email = TextEditingController();
  final _locationDetail = TextEditingController();
  String _shopType = 'มือถือ แท็บเล็ต';
  String _hours = 'เปิดทุกวัน';
  bool _accepted = false;

  static const _steps = [
    'ข้อมูลร้านค้า',
    'ข้อมูลติดต่อ',
    'ที่อยู่ร้านค้า',
    'ยืนยันการเปิดร้าน',
  ];

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
    if (_step < 3) setState(() => _step++);
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
        title: const Text(
          'เปิดร้านค้า',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => showInfo(context, 'บันทึกฉบับร่างแล้ว (mock)'),
            child: const Text(
              'บันทึกฉบับร่าง',
              style: TextStyle(
                color: AppTheme.orange,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
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
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 9),
        Text(
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label${required ? ' *' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: required ? Colors.black : const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
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
        const Text(
          'ประเภทร้านค้า *',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                    'มือถือ แท็บเล็ต',
                    'อุปกรณ์อิเล็กทรอนิกส์',
                    'แฟชั่น เสื้อผ้า',
                    'บ้านและสวน',
                    'อื่นๆ',
                  ]
                  .map(
                    (e) => ChoiceChip(
                      label: Text(e),
                      selected: _shopType == e,
                      selectedColor: AppTheme.orangeSoft,
                      side: BorderSide(
                        color: _shopType == e
                            ? AppTheme.orange
                            : const Color(0xFFE4E4E4),
                      ),
                      onSelected: (_) => setState(() => _shopType = e),
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
        const Text(
          'รูปภาพร้านค้า (โลโก้) *',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _UploadBox(
          icon: Icons.add_business_rounded,
          title: 'เพิ่มรูปโลโก้ร้านค้า',
          subtitle: 'ขนาดแนะนำ 1:1  •  JPG, PNG ไม่เกิน 5MB',
          onTap: () => showInfo(context, 'เลือกรูปโลโก้ (mock)'),
        ),
        const SizedBox(height: 18),
        const Text(
          'รูปภาพหน้าปกร้านค้า',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _UploadBox(
          icon: Icons.add_photo_alternate_outlined,
          title: 'เพิ่มรูปหน้าปกร้านค้า',
          subtitle: 'ขนาดแนะนำ 16:9  •  JPG, PNG ไม่เกิน 10MB',
          onTap: () => showInfo(context, 'เลือกรูปหน้าปก (mock)'),
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
        ),
        const Text(
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
                  label: Text(e),
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
        const Text(
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
                child: Text(
                  'บ้านน้ำจ๋าง, เมืองน้ำจ๋าง, รัฐฉาน\nใกล้ ตลาดสดน้ำจ๋าง',
                ),
              ),
              Text(
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
                  onPressed: () =>
                      showInfo(context, 'ใช้ตำแหน่งปัจจุบัน (mock)'),
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
            'ประเภทร้านค้า   $_shopType',
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
          title: const Text(
            'ฉันยอมรับเงื่อนไขการใช้งานและนโยบายของ Suikai',
            style: TextStyle(fontSize: 14),
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        _primaryButton(
          'ยืนยันการเปิดร้าน',
          _accepted
              ? () {
                  showInfo(
                    context,
                    'ส่งคำขอเปิดร้านแล้ว • สถานะ: รออนุมัติ (mock)',
                  );
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
              Text(
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
      label: Text(
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
      child: Text(
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
                          : Text(
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
                Text(
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
  const _UploadBox({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.orange, size: 38),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
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
          child: Text(
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 7),
              ...lines.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
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
          label: const Text('แก้ไข'),
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
