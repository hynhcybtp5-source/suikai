import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:latlong2/latlong.dart' as latlng;
import 'package:url_launcher/url_launcher.dart';

import '../../core/locale_controller.dart';
import '../../core/app_route_observer.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mobile_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/category_icons.dart';
import '../../services/suikai_service.dart';
import '../../services/fx_service.dart';
import '../../data/models.dart';
import '../../widgets/tiktok_embed_player.dart';
import '../../widgets/location_picker_map.dart';
import '../admin/admin_dashboard.dart';
import '../auth/auth_page.dart';

class SuikaiRoutes {
  static const home = '/';
  static const stores = '/stores';
  static const post = '/post';
  static const map = '/map';
  static const shortVideos = '/short-videos';
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
      SuikaiService.hasValidSession ? child : LoginPage(pendingRoute: route);

  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const HomePage(),
    stores: (_) => const StoreListPage(),
    post: (_) => _protected(post, const PostPage()),
    map: (_) => const MapPage(),
    shortVideos: (_) => const ShortVideoFeedPage(),
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

class StoreViewModel {
  final String id;
  final String name;
  final String type;
  final String city;
  final String? cityId;
  final CityRecord? cityRecord;
  final String distance;
  final String logo;
  final String description;
  final String phone;
  final String viber;
  final String hours;
  final bool approved;
  final String status;
  final String searchableProducts;
  final String? ownerId;
  final String? coverUrl;
  final String? email;
  final bool isPromoted;
  final DateTime? promotionStartAt;
  final DateTime? promotionEndAt;
  final double? latitude;
  final double? longitude;

  const StoreViewModel({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    this.cityId,
    this.cityRecord,
    required this.distance,
    required this.logo,
    required this.description,
    required this.phone,
    required this.viber,
    required this.hours,
    required this.approved,
    this.status = '',
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

  String get effectiveStatus =>
      status.isEmpty ? (approved ? 'approved' : 'pending') : status;

  String localizedCity(String localeCode, {String fallback = ''}) {
    if (city.trim().isNotEmpty) return city.trim();
    final translated = cityRecord?.localizedName(localeCode) ?? '';
    if (translated.trim().isNotEmpty) return translated.trim();
    return fallback;
  }

  bool get promotionIsActive {
    if (!isPromoted) return false;
    final now = DateTime.now();
    return (promotionStartAt == null || !now.isBefore(promotionStartAt!)) &&
        (promotionEndAt == null || !now.isAfter(promotionEndAt!));
  }
}

IconData _categoryIcon(String value) {
  final category = [
    ...SuikaiService.categoryRecords('store'),
    ...SuikaiService.categoryRecords('listing'),
  ].where((item) => item.matches(value)).firstOrNull;
  return categoryIconData(category?.iconKey);
}

String _categoryLabel(BuildContext context, String type, String value) =>
    SuikaiService.categoryLabel(
      type,
      value,
      Localizations.localeOf(context).languageCode,
    );

bool mapCategoryMatches(String categoryId, String selectedCategoryId) =>
    selectedCategoryId == 'all' || categoryId == selectedCategoryId;

Uri storeNavigationUri(double latitude, double longitude) => Uri.https(
  'www.google.com',
  '/maps/dir/',
  {'api': '1', 'destination': '$latitude,$longitude', 'travelmode': 'driving'},
);

class ProductViewModel {
  final String id;
  final String title;
  final int priceValue;
  final String currencyCode;
  final String description;
  final String category;
  final String city;
  final String? cityId;
  final CityRecord? cityRecord;
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

  const ProductViewModel({
    required this.id,
    required this.title,
    required this.priceValue,
    this.currencyCode = 'THB',
    required this.description,
    required this.category,
    required this.city,
    this.cityId,
    this.cityRecord,
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
  String localizedCity(String localeCode, {String fallback = ''}) {
    if (city.trim().isNotEmpty) return city.trim();
    final translated = cityRecord?.localizedName(localeCode) ?? '';
    if (translated.trim().isNotEmpty) return translated.trim();
    return fallback;
  }

  double? get publicLatitude => isLocationVisible ? latitude : null;
  double? get publicLongitude => isLocationVisible ? longitude : null;

  List<String> get imageUrls {
    final values = (images.isEmpty ? [image] : images)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    return values;
  }
}

String? primaryProductImage(ProductViewModel product) {
  final source = product.images.firstOrNull ?? product.image;
  return source.trim().isEmpty ? null : source;
}

String? validateRequiredCity(String? value) =>
    normalizeText(value).isEmpty ? 'กรุณากรอกชื่อเมือง' : null;

String productCityLabel(BuildContext context, ProductViewModel product) =>
    product.localizedCity(
      Localizations.localeOf(context).languageCode,
      fallback: AppLocalizations.of(context).source('ไม่ระบุเมือง'),
    );

String storeCityLabel(BuildContext context, StoreViewModel store) =>
    store.localizedCity(
      Localizations.localeOf(context).languageCode,
      fallback: AppLocalizations.of(context).source('ไม่ระบุเมือง'),
    );

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

class _ThousandsInputFormatter extends TextInputFormatter {
  const _ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    digits = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final formatted = digits.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _NumericPriceRange extends StatelessWidget {
  final TextEditingController minimum, maximum;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback onChanged;

  const _NumericPriceRange({
    required this.minimum,
    required this.maximum,
    required this.currency,
    required this.onCurrencyChanged,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final min = parsePriceValue(minimum.text);
    final max = parsePriceValue(maximum.text);
    final invalid = min != null && max != null && min > max;
    Widget amountField(TextEditingController controller, String label) =>
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: const [_ThousandsInputFormatter()],
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).source(label),
            hintText: label == 'ราคาต่ำสุด' ? '100,000' : '5,000,000',
            errorText: invalid ? ' ' : null,
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              Expanded(child: amountField(minimum, 'ราคาต่ำสุด')),
              const SizedBox(width: 10),
              Expanded(child: amountField(maximum, 'ราคาสูงสุด')),
              const SizedBox(width: 10),
              SizedBox(
                width: 92,
                child: DropdownButtonFormField<String>(
                  initialValue: currency,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).source('สกุลเงิน'),
                  ),
                  items: const ['MMK', 'THB', 'USD', 'CNY']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onCurrencyChanged(value);
                  },
                ),
              ),
            ];
            if (constraints.maxWidth >= 390) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: fields,
              );
            }
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: fields.take(3).toList(),
                ),
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerLeft, child: fields.last),
              ],
            );
          },
        ),
        if (invalid)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: LocalizedText(
              'ราคาต่ำสุดต้องไม่เกินราคาสูงสุด',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
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

class MarketplaceCache {
  static final stores = <StoreViewModel>[];
  static final products = <ProductViewModel>[];
  static final productsRevision = ValueNotifier<int>(0);

  static List<StoreViewModel> get approvedStores =>
      stores.where((store) => store.approved).toList();

  static List<ProductViewModel> get feedProducts {
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

  static StoreViewModel? storeById(String id) {
    for (final store in stores) {
      if (store.id == id) {
        return store;
      }
    }
    return null;
  }

  static ProductViewModel? productById(String id) {
    for (final product in products) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  static void cacheProducts(Iterable<ProductViewModel> remote) {
    for (final product in remote) {
      final index = products.indexWhere((item) => item.id == product.id);
      if (index < 0)
        products.add(product);
      else
        products[index] = product;
    }
  }

  static void syncRemoteProducts(Iterable<ProductViewModel> values) {
    products.removeWhere((item) => item.ownerId != null);
    for (final product in values.toList().reversed) {
      products.removeWhere((item) => item.id == product.id);
      products.insert(0, product);
    }
    productsRevision.value++;
  }

  static void cacheStores(Iterable<StoreViewModel> remote) {
    for (final store in remote) {
      final index = stores.indexWhere((item) => item.id == store.id);
      if (index < 0)
        stores.add(store);
      else
        stores[index] = store;
    }
  }

  static void syncRemoteStores(Iterable<StoreViewModel> values) {
    stores.removeWhere((item) => item.ownerId != null);
    cacheStores(values);
  }

  static List<ProductViewModel> productsByStore(String storeId) {
    return products.where((product) => product.storeId == storeId).toList();
  }

  static void replaceProductsForStore(
    String storeId,
    Iterable<ProductViewModel> remote,
  ) {
    products.removeWhere((product) => product.storeId == storeId);
    products.insertAll(0, remote);
  }

  static List<ProductViewModel> get managedProducts {
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
    products[index] = ProductViewModel(
      id: current.id,
      title: current.title,
      priceValue: current.priceValue,
      currencyCode: current.currencyCode,
      description: current.description,
      category: current.category,
      city: current.city,
      cityId: current.cityId,
      cityRecord: current.cityRecord,
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
    products[index] = ProductViewModel(
      id: p.id,
      title: p.title,
      priceValue: p.priceValue,
      currencyCode: p.currencyCode,
      description: p.description,
      category: p.category,
      city: p.city,
      cityId: p.cityId,
      cityRecord: p.cityRecord,
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
  Key? key,
  double? width,
  double? height,
  BoxFit? fit,
  Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
}) {
  if (source.isNotEmpty && !source.startsWith('http')) {
    return Image.file(
      key: key ?? ValueKey('file-image-$source'),
      File(source),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
  return Image.network(
    key: key ?? ValueKey('network-image-$source'),
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
      SuikaiRoutes.shortVideos,
      SuikaiRoutes.profile,
    ];
    Navigator.pushNamed(context, routeByIndex[index]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      drawer: const _SuikaiDrawer(),
      drawerEnableOpenDragGesture: true,
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
            icon: const Icon(Icons.play_circle_outline_rounded),
            selectedIcon: const Icon(
              Icons.play_circle_fill_rounded,
              color: AppTheme.orange,
            ),
            label: AppLocalizations.of(context).source('วิดีโอสั้น'),
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
          Builder(
            builder: (context) => IconButton(
              tooltip: AppLocalizations.of(context).source('เมนู'),
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(
                Icons.menu_rounded,
                color: AppTheme.orange,
                size: 25,
              ),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.orangeSoft,
                fixedSize: Size.square(buttonSize),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuikaiDrawer extends StatelessWidget {
  const _SuikaiDrawer();

  Future<void> _language(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await Future<void>.delayed(Duration.zero);
    if (!navigator.mounted) return;
    await showDialog<void>(
      context: navigator.context,
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
  }

  void _route(BuildContext context, String route) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.pushNamed(route);
  }

  Future<void> _logout(BuildContext context) async {
    final navigator = Navigator.of(context);
    navigator.pop();
    await Future<void>.delayed(Duration.zero);
    if (!navigator.mounted) return;
    final confirmed = await showDialog<bool>(
      context: navigator.context,
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
    if (navigator.mounted) {
      navigator.pushNamedAndRemoveUntil(SuikaiRoutes.home, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) => Drawer(
    width: MediaQuery.sizeOf(context).width.clamp(280, 340).toDouble(),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 18),
              child: LocalizedText(
                'Suikai',
                style: TextStyle(
                  color: AppTheme.orange,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _DrawerItem(
              icon: Icons.language_rounded,
              label: 'เปลี่ยนภาษา',
              onTap: () => _language(context),
            ),
            _DrawerItem(
              icon: Icons.map_outlined,
              label: 'แผนที่',
              onTap: () => _route(context, SuikaiRoutes.map),
            ),
            _DrawerItem(
              icon: Icons.search_rounded,
              label: 'ค้นหา',
              onTap: () => _route(context, SuikaiRoutes.search),
            ),
            _DrawerItem(
              icon: Icons.notifications_none_rounded,
              label: 'การแจ้งเตือน',
              onTap: () => _route(context, SuikaiRoutes.notifications),
            ),
            const Spacer(),
            const Divider(),
            if (SuikaiService.isLoggedIn)
              _DrawerItem(
                icon: Icons.logout_rounded,
                label: 'ออกจากระบบ',
                destructive: true,
                onTap: () => _logout(context),
              )
            else
              _DrawerItem(
                icon: Icons.login_rounded,
                label: 'เข้าสู่ระบบ',
                onTap: () => _route(context, SuikaiRoutes.login),
              ),
          ],
        ),
      ),
    ),
  );
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    leading: Icon(icon, color: destructive ? Colors.red : AppTheme.orange),
    title: LocalizedText(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: destructive ? Colors.red : null,
        fontWeight: FontWeight.w700,
      ),
    ),
    onTap: onTap,
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

class _AdvertisementSlider extends StatefulWidget {
  final EdgeInsetsGeometry margin;
  final ValueChanged<String> onCategoryTarget;
  const _AdvertisementSlider({
    required this.margin,
    required this.onCategoryTarget,
  });

  @override
  State<_AdvertisementSlider> createState() => _AdvertisementSliderState();
}

class _AdvertisementSliderState extends State<_AdvertisementSlider>
    with WidgetsBindingObserver, RouteAware {
  static const _interval = Duration(seconds: 5);
  final PageController _controller = PageController();
  Timer? _timer;
  List<AdvertisementRecord> _items = [];
  int _index = 0;
  bool _appActive = true;
  bool _routeActive = true;
  ModalRoute<void>? _route;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await SuikaiService.fetchActiveAdvertisements();
      if (!mounted) return;
      setState(() {
        _items = values;
        _index = 0;
      });
      _schedule();
    } catch (error, stackTrace) {
      debugPrint('Supabase advertisements query failed: $error\n$stackTrace');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    if (_appActive) {
      _schedule();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextRoute = ModalRoute.of(context);
    if (nextRoute == _route) return;
    if (_route != null) appRouteObserver.unsubscribe(this);
    _route = nextRoute;
    if (nextRoute != null) appRouteObserver.subscribe(this, nextRoute);
  }

  @override
  void didPushNext() {
    _routeActive = false;
    _timer?.cancel();
  }

  @override
  void didPopNext() {
    _routeActive = true;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (!_appActive || !_routeActive || _items.length < 2) return;
    _timer = Timer(_interval, _advance);
  }

  void _advance() {
    if (!mounted ||
        !_appActive ||
        !_routeActive ||
        !_controller.hasClients ||
        _items.length < 2) {
      _schedule();
      return;
    }
    final next = (_index + 1) % _items.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOut,
    );
  }

  void _changed(int index) {
    if (mounted) setState(() => _index = index);
    _schedule();
  }

  Future<void> _open(AdvertisementRecord value) async {
    _timer?.cancel();
    switch (value.targetType) {
      case 'shop':
        if (value.targetId != null && mounted) {
          await Navigator.pushNamed(
            context,
            SuikaiRoutes.storeDetail,
            arguments: value.targetId,
          );
        }
      case 'product':
        if (value.targetId != null && mounted) {
          await Navigator.pushNamed(
            context,
            SuikaiRoutes.productDetail,
            arguments: value.targetId,
          );
        }
      case 'category':
        if (value.targetId != null) widget.onCategoryTarget(value.targetId!);
      case 'external':
        final uri = Uri.tryParse(value.externalUrl ?? '');
        if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
    }
    if (mounted) _schedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = (constraints.maxWidth * .36).clamp(140.0, 170.0);
        return Container(
          height: height,
          margin: widget.margin,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.orangeSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              NotificationListener<ScrollStartNotification>(
                onNotification: (notification) {
                  if (notification.dragDetails != null) _schedule();
                  return false;
                },
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _items.length,
                  onPageChanged: _changed,
                  itemBuilder: (context, index) {
                    final banner = _items[index];
                    return InkWell(
                      onTap: () => _open(banner),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          persistentImage(
                            banner.imageUrl,
                            key: ValueKey('advertisement-${banner.id}'),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const ColoredBox(
                              color: AppTheme.orangeSoft,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: AppTheme.orange,
                              ),
                            ),
                          ),
                          if (banner.title.trim().isNotEmpty)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  24,
                                  14,
                                  20,
                                ),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  banner.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_items.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < _items.length; index++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: index == _index ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: index == _index
                                ? AppTheme.orange
                                : Colors.white70,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HomePageState extends State<HomePage> {
  String _filterCurrency = 'THB';
  String _appliedCurrency = 'THB';
  String _selectedCategory = 'all';
  String _draftCategory = 'all';
  String _appliedKeyword = '';
  int? _appliedMinimum;
  int? _appliedMaximum;
  bool _searchExpanded = false;
  final _keyword = TextEditingController();
  final _minimumPrice = TextEditingController();
  final _maximumPrice = TextEditingController();
  FxSnapshot? _fx;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    debugPrint('ROOT initState');
    _loadListings();
    _loadFx();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_completeDeferredStartup());
      _initializeNearby();
    });
  }

  Future<void> _completeDeferredStartup() async {
    await localeController.load();
    await InteractionStore.restore();
    await SuikaiService.warmUpAfterFirstFrame();
    if (mounted) setState(() {});
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
    });
  }

  void _changeCurrency(String currency) {
    setState(() => _filterCurrency = currency);
  }

  @override
  void dispose() {
    _keyword.dispose();
    _minimumPrice.dispose();
    _maximumPrice.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    try {
      final data = await SuikaiService.fetchListings();
      final next = <ProductViewModel>[];
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
          ProductViewModel(
            id: item['id'].toString(),
            title: item['title']?.toString() ?? '',
            priceValue: (item['price'] as num?)?.toInt() ?? 0,
            currencyCode: item['currency']?.toString() ?? 'MMK',
            description: item['description']?.toString() ?? '',
            category: item['category']?.toString() ?? 'อื่นๆ',
            city: item['city']?.toString() ?? '',
            cityId: item['city_id']?.toString(),
            cityRecord: item['cities'] is Map
                ? CityRecord.fromJson(
                    Map<String, dynamic>.from(item['cities'] as Map),
                  )
                : null,
            location: item['city']?.toString() ?? '',
            time: item['created_at']?.toString() ?? '',
            image: image,
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
        MarketplaceCache.syncRemoteProducts(next);
        setState(() {});
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('ROOT build');
    final source = MarketplaceCache.feedProducts;
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
      final keyword = _appliedKeyword.toLowerCase();
      final matchesKeyword =
          keyword.isEmpty ||
          product.title.toLowerCase().contains(keyword) ||
          product.description.toLowerCase().contains(keyword);
      final productPrice = _fx == null
          ? product.priceValue.toDouble()
          : FxService().convert(
              product.priceValue.toDouble(),
              product.currencyCode,
              _appliedCurrency,
              _fx!,
            );
      final matchesPrice =
          productPrice.isFinite &&
          (_appliedMinimum == null || productPrice >= _appliedMinimum!) &&
          (_appliedMaximum == null || productPrice <= _appliedMaximum!);
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
      return matchesKeyword && matchesCategory && matchesPrice && matchesNearby;
    }).toList();
    return RootScaffold(
      selectedIndex: 0,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _homeHeader(context)),
          SliverToBoxAdapter(child: _priceFilter(context)),
          SliverToBoxAdapter(child: _categories(context)),
          SliverToBoxAdapter(child: _banner(context)),
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
    final locale = Localizations.localeOf(context).languageCode;
    final categories = SuikaiService.categoryRecords(
      'listing',
      activeOnly: true,
    );
    return TapRegion(
      onTapOutside: (_) {
        if (_searchExpanded) {
          FocusScope.of(context).unfocus();
          setState(() => _searchExpanded = false);
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
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
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _searchExpanded = !_searchExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppTheme.orange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _appliedKeyword.isEmpty
                            ? AppLocalizations.of(context).source('ค้นหาสินค้า')
                            : _appliedKeyword,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _appliedKeyword.isEmpty
                              ? AppTheme.textMuted
                              : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      _searchExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: !_searchExpanded
                  ? const SizedBox.shrink()
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppTheme.border)),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          TextField(
                            controller: _keyword,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).source('ค้นหาสินค้า'),
                              prefixIcon: const Icon(Icons.search_rounded),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            initialValue: _draftCategory,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              ).source('หมวดหมู่'),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).source('ทั้งหมด'),
                                ),
                              ),
                              for (final category in categories)
                                DropdownMenuItem(
                                  value: category.id,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _categoryIcon(category.id),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          category.localizedName(locale),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            onChanged: (value) =>
                                _draftCategory = value ?? 'all',
                          ),
                          const SizedBox(height: 10),
                          _NumericPriceRange(
                            minimum: _minimumPrice,
                            maximum: _maximumPrice,
                            currency: _filterCurrency,
                            onCurrencyChanged: _changeCurrency,
                            onChanged: () {},
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _applyHomeSearch,
                              icon: const Icon(Icons.search_rounded),
                              label: const LocalizedText('ค้นหา'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
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

  void _applyHomeSearch() {
    final minimum = parsePriceValue(_minimumPrice.text);
    final maximum = parsePriceValue(_maximumPrice.text);
    if (minimum != null && maximum != null && minimum > maximum) {
      showInfo(context, 'ราคาต่ำสุดต้องไม่เกินราคาสูงสุด');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _appliedKeyword = normalizeText(_keyword.text).toLowerCase();
      _selectedCategory = _draftCategory;
      _appliedMinimum = minimum;
      _appliedMaximum = maximum;
      _appliedCurrency = _filterCurrency;
      _searchExpanded = false;
    });
  }

  Widget _banner(BuildContext context) {
    return _AdvertisementSlider(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      onCategoryTarget: (categoryId) => setState(() {
        _selectedCategory = categoryId;
        _draftCategory = categoryId;
      }),
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
          _categoryIcon(category.id),
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
                onTap: () => setState(() {
                  _selectedCategory = category.$3;
                  _draftCategory = category.$3;
                }),
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
              _draftCategory = 'all';
              _appliedKeyword = '';
              _appliedMinimum = null;
              _appliedMaximum = null;
              _keyword.clear();
              _minimumPrice.clear();
              _maximumPrice.clear();
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
        return StoreViewModel(
          id: item['id'].toString(),
          name: item['name']?.toString() ?? '',
          type: item['category']?.toString() ?? 'ร้านค้า',
          city: item['city']?.toString() ?? '',
          cityId: item['city_id']?.toString(),
          cityRecord: item['cities'] is Map
              ? CityRecord.fromJson(
                  Map<String, dynamic>.from(item['cities'] as Map),
                )
              : null,
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
        MarketplaceCache.syncRemoteStores(next);
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
    final source = MarketplaceCache.approvedStores;
    final stores = source.where((store) {
      final matchesQuery =
          query.isEmpty ||
          store.name.toLowerCase().contains(query) ||
          _categoryLabel(
            context,
            'store',
            store.type,
          ).toLowerCase().contains(query) ||
          storeCityLabel(context, store).toLowerCase().contains(query);
      final matchesStoreProduct =
          store.searchableProducts.toLowerCase().contains(query) ||
          MarketplaceCache.productsByStore(store.id).any(
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
    return _AdvertisementSlider(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      onCategoryTarget: (categoryId) => setState(() {
        _selectedType = categoryId;
      }),
    );
  }

  Widget _categorySection() {
    final categories = <_StoreCategoryData>[
      for (final category in SuikaiService.categoryRecords('store'))
        _StoreCategoryData(category.id, _categoryIcon(category.id)),
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
  final StoreViewModel store;
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
                          storeCityLabel(context, store),
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
  Future<void> _refreshStoreProducts() async {
    final rows = await SuikaiService.fetchListingsForStore(widget.storeId);
    final products = rows.map((item) {
      final images = (item['listing_images'] as List? ?? const [])
          .map((entry) => '${(entry as Map)['image_url'] ?? ''}')
          .where((url) => url.isNotEmpty)
          .toList();
      return ProductViewModel(
        id: '${item['id']}',
        title: '${item['title'] ?? ''}',
        priceValue: (item['price'] as num?)?.toInt() ?? 0,
        currencyCode: '${item['currency'] ?? 'MMK'}',
        description: '${item['description'] ?? ''}',
        category: '${item['category'] ?? ''}',
        city: '${item['city'] ?? ''}',
        cityId: item['city_id']?.toString(),
        cityRecord: item['cities'] is Map
            ? CityRecord.fromJson(
                Map<String, dynamic>.from(item['cities'] as Map),
              )
            : null,
        location: '${item['city'] ?? ''}',
        time: '${item['created_at'] ?? ''}',
        image: images.firstOrNull ?? '',
        phone: '${item['phone'] ?? ''}',
        viber: '${item['viber_phone'] ?? ''}',
        likeCount: 0,
        viewCount: 0,
        status: _productStatus('${item['status']}'),
        storeId: '${item['store_id']}',
        ownerId: '${item['owner_id']}',
        images: images,
        latitude: (item['latitude'] as num?)?.toDouble(),
        longitude: (item['longitude'] as num?)?.toDouble(),
        isLocationVisible: item['is_location_visible'] != false,
      );
    }).toList();
    MarketplaceCache.replaceProductsForStore(widget.storeId, products);
    if (mounted) setState(() {});
  }

  Future<void> _manageProduct(ProductViewModel product, String action) async {
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
      MarketplaceCache.removeProduct(product.id);
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
      MarketplaceCache.setStatus(product.id, status);
    }
    if (mounted) setState(() {});
  }

  Future<void> _ownerAction(StoreViewModel store, String action) async {
    if (action == 'edit') {
      await _editStore(context, store);
      return;
    }
    if (action == 'delete') {
      if (store.approved) {
        showInfo(context, 'ลบได้เฉพาะร้านที่รออนุมัติหรือไม่ผ่านการอนุมัติ');
        return;
      }
      await SuikaiService.deleteStore(store.id);
      MarketplaceCache.stores.removeWhere((value) => value.id == store.id);
      if (mounted) Navigator.pop(context, true);
      return;
    }
    if (!store.approved) {
      showInfo(
        context,
        store.effectiveStatus == 'rejected'
            ? 'ร้านไม่ผ่านการอนุมัติ'
            : 'ร้านกำลังรอการอนุมัติ',
      );
      return;
    }
    if (action == 'add') {
      final added = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => PostPage(storeId: store.id)),
      );
      if (added == true) await _refreshStoreProducts();
    } else if (action == 'promote') {
      try {
        await SuikaiService.submitPromotionRequest(store.id);
        if (mounted) showInfo(context, 'ส่งคำขอโปรโมตร้านแล้ว');
      } catch (_) {
        if (mounted) showInfo(context, 'มีคำขอโปรโมตร้านที่รอตรวจสอบอยู่แล้ว');
      }
    }
  }

  Future<void> _editStore(BuildContext context, StoreViewModel store) async {
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
                    labelText: AppLocalizations.of(context).source('เมือง'),
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
                    validateEmail(email.text) != null ||
                    normalizeText(city.text).isEmpty) {
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
                      'city': normalizeText(city.text),
                      'city_id': store.cityId,
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
    final store = MarketplaceCache.storeById(widget.storeId);
    if (store == null) {
      return const _MissingPage(title: 'ไม่พบร้าน');
    }
    final products = MarketplaceCache.productsByStore(store.id);

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
              itemBuilder: (_) => [
                if (store.approved)
                  const PopupMenuItem(
                    value: 'add',
                    child: LocalizedText('เพิ่มสินค้า'),
                  ),
                const PopupMenuItem(
                  value: 'edit',
                  child: LocalizedText('แก้ไขร้าน'),
                ),
                if (store.approved)
                  const PopupMenuItem(
                    value: 'promote',
                    child: LocalizedText('ขอโปรโมตร้าน'),
                  ),
                if (!store.approved)
                  const PopupMenuItem(
                    value: 'delete',
                    child: LocalizedText('ลบร้าน'),
                  ),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        children: [
          if (!store.approved) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: store.effectiveStatus == 'rejected'
                    ? const Color(0xFFFFEBEE)
                    : AppTheme.orangeSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: LocalizedText(
                store.effectiveStatus == 'rejected'
                    ? 'ไม่ผ่านการอนุมัติ'
                    : 'รออนุมัติ',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
          ],
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
                      if (store.approved &&
                          store.ownerId == SuikaiService.currentUserId)
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
  late final ProductViewModel? _original;
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
  latlng.LatLng? _editLocation;

  @override
  void initState() {
    super.initState();
    _original = MarketplaceCache.productById(widget.productId);
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
    if (product?.latitude != null && product?.longitude != null) {
      _editLocation = latlng.LatLng(product!.latitude!, product.longitude!);
    }
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
    final selected = await SuikaiService.pickImages(
      maxCount: replaceIndex == null ? 5 - _images.length : 1,
    );
    if (!mounted || selected.isEmpty) return;
    setState(() {
      if (replaceIndex == null) {
        _images.addAll(selected.map(_ProductImageDraft.selected));
      } else {
        _images[replaceIndex] = _ProductImageDraft.selected(selected.first);
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
                      Flexible(
                        flex: 2,
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
                    validator: (value) => normalizeText(value).isEmpty
                        ? AppLocalizations.of(
                            context,
                          ).source('กรุณากรอกชื่อเมือง')
                        : null,
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
                  if (!product.isStoreProduct && _isLocationVisible) ...[
                    const SizedBox(height: 10),
                    LocationPickerMap(
                      value: _editLocation,
                      onChanged: (point) =>
                          setState(() => _editLocation = point),
                      currentLocation: () async {
                        final position =
                            await SuikaiService.getCurrentPosition();
                        return position == null
                            ? null
                            : latlng.LatLng(
                                position.latitude,
                                position.longitude,
                              );
                      },
                      height: 240,
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
      final cityName = normalizeText(_city.text);
      if (cityName.isEmpty) throw StateError('listing_city_required');
      await SuikaiService.updateListing(
        listingId: product.id,
        title: normalizeText(_name.text),
        description: normalizeText(_description.text),
        city: cityName,
        cityId: product.cityId,
        phone: normalizePhone(_phone.text),
        viber: normalizePhone(_viber.text),
        price: amount.toDouble(),
        currency: _currency,
        status: _status.name,
        category: category,
        images: finalImages,
        latitude: _editLocation?.latitude,
        longitude: _editLocation?.longitude,
        isLocationVisible: product.isStoreProduct
            ? product.isLocationVisible
            : _isLocationVisible,
      );
      MarketplaceCache.cacheProducts([
        ProductViewModel(
          id: product.id,
          title: normalizeText(_name.text),
          priceValue: amount,
          currencyCode: _currency,
          description: normalizeText(_description.text),
          category: category,
          city: cityName,
          cityId: product.cityId,
          cityRecord: product.cityRecord,
          location: cityName,
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
              ? (_editLocation?.latitude ?? product.latitude)
              : null,
          longitude: _isLocationVisible
              ? (_editLocation?.longitude ?? product.longitude)
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
  final _basicStepFormKey = GlobalKey<FormState>();
  final _locationStepFormKey = GlobalKey<FormState>();
  bool _showGeneralWizard = false;
  int _step = 0;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _detailsController = TextEditingController();
  final _phoneController = TextEditingController(text: '09 9999 9999');
  final _viberController = TextEditingController(text: '09 8888 8888');
  final _locationNoteController = TextEditingController();
  final _cityController = TextEditingController();

  String _category = '';
  String _currency = 'MMK';
  String _condition = 'มือหนึ่ง';
  bool _isLocationVisible = true;
  bool _submitting = false;
  latlng.LatLng? _listingPosition;
  ProductStatus _listingStatus = ProductStatus.available;
  final List<SelectedImage> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _showGeneralWizard = widget.startGeneral || widget.storeId != null;
    _category = widget.storeId == null
        ? ''
        : SuikaiService.categoryRecords(
                'listing',
                activeOnly: true,
              ).firstOrNull?.id ??
              '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _detailsController.dispose();
    _phoneController.dispose();
    _viberController.dispose();
    _locationNoteController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (!(_basicStepFormKey.currentState?.validate() ?? false)) {
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
    if (_step == 2 &&
        !(_locationStepFormKey.currentState?.validate() ?? false)) {
      showInfo(context, 'กรุณากรอกชื่อเมือง');
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
      if (position != null) {
        setState(
          () => _listingPosition = latlng.LatLng(
            position.latitude,
            position.longitude,
          ),
        );
      }
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
      final images = replaceIndex == null
          ? await SuikaiService.pickImages(
              maxCount: limit - _selectedImages.length,
            )
          : await SuikaiService.pickImages(maxCount: 1);
      if (!mounted || images.isEmpty) return;
      setState(() {
        if (replaceIndex == null) {
          _selectedImages.addAll(images);
        } else {
          _selectedImages[replaceIndex] = images.first;
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
            DropdownButtonFormField<String>(
              initialValue: _category.isEmpty ? null : _category,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.category),
              items: SuikaiService.categoryRecords('listing', activeOnly: true)
                  .map(
                    (category) => DropdownMenuItem(
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
              validator: (value) => value == null || value.isEmpty
                  ? AppLocalizations.of(
                      context,
                    ).source('กรุณาเลือกหมวดหมู่สินค้า')
                  : null,
              onChanged: (value) => setState(() => _category = value ?? ''),
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
                Flexible(
                  flex: 2,
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
      final store = (await SuikaiService.fetchStores())
          .where((value) => '${value['id']}' == widget.storeId)
          .firstOrNull;
      final storeCityId = store?['city_id']?.toString();
      final storeCity = normalizeText(store?['city']?.toString());
      if (storeCity.isEmpty) throw StateError('store_city_required');
      await SuikaiService.createListing(
        title: normalizeText(_nameController.text),
        description: normalizeText(_detailsController.text),
        category: _category,
        city: storeCity,
        cityId: storeCityId,
        phone: normalizePhone(_phoneController.text),
        viber: normalizePhone(_viberController.text),
        price: price.toDouble(),
        currency: _currency,
        listingType: 'store',
        storeId: widget.storeId,
        status: _listingStatus.name,
        images: _selectedImages,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error, stackTrace) {
      debugPrint('Save store product failed: $error\n$stackTrace');
      if (mounted) {
        showInfo(context, '${l10n.saveFailed}: $error');
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
                onPressed: () => showInfo(context, 'บันทึกฉบับร่างแล้ว'),
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
    return Form(
      key: _basicStepFormKey,
      child: _stepScroll([
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
              validator: (value) => value == null || value.isEmpty
                  ? AppLocalizations.of(
                      context,
                    ).source('กรุณาเลือกหมวดหมู่สินค้า')
                  : null,
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
                Flexible(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _currency,
                    isExpanded: true,
                    decoration: _inputDecoration(),
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
        KeyedSubtree(
          key: const ValueKey('general-basic-next'),
          child: _primaryButton('ถัดไป', _next),
        ),
      ]),
    );
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
    return Form(
      key: _locationStepFormKey,
      child: _stepScroll([
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
            if (_isLocationVisible)
              LocationPickerMap(
                value: _listingPosition,
                onChanged: (point) => setState(() => _listingPosition = point),
                currentLocation: () async {
                  final position = await SuikaiService.getCurrentPosition();
                  return position == null
                      ? null
                      : latlng.LatLng(position.latitude, position.longitude);
                },
                height: 285,
              ),
            const SizedBox(height: 18),
            const _FieldLabel('เมือง'),
            TextFormField(
              controller: _cityController,
              decoration: _inputDecoration(hint: 'กรอกชื่อเมือง'),
              validator: (value) {
                final error = validateRequiredCity(value);
                return error == null
                    ? null
                    : AppLocalizations.of(context).source(error);
              },
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
      ]),
    );
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
            normalizeText(_cityController.text).isEmpty
                ? AppLocalizations.of(context).source('ไม่ระบุเมือง')
                : normalizeText(_cityController.text),
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
                      final basicValid =
                          _basicStepFormKey.currentState?.validate() ?? false;
                      final locationValid =
                          _locationStepFormKey.currentState?.validate() ??
                          false;
                      if (!basicValid || !locationValid) {
                        showInfo(context, 'กรุณาตรวจสอบข้อมูลที่จำเป็น');
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
                      if (normalizeText(_cityController.text).isEmpty) {
                        showInfo(context, 'กรุณากรอกชื่อเมือง');
                        return;
                      }
                      setState(() => _submitting = true);
                      try {
                        await SuikaiService.createListing(
                          title: normalizeText(_nameController.text),
                          description: normalizeText(_detailsController.text),
                          category: _category,
                          city: normalizeText(_cityController.text),
                          cityId: null,
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
                      } catch (error, stackTrace) {
                        debugPrint(
                          'Submit listing failed: $error\n$stackTrace',
                        );
                        if (!context.mounted) {
                          return;
                        }
                        showInfo(context, 'ลงประกาศไม่สำเร็จ: $error');
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

class ShortVideoFeedPage extends StatefulWidget {
  const ShortVideoFeedPage({super.key});

  @override
  State<ShortVideoFeedPage> createState() => _ShortVideoFeedPageState();
}

class _ShortVideoFeedPageState extends State<ShortVideoFeedPage>
    with RouteAware, WidgetsBindingObserver {
  late final Future<List<ShortVideoRecord>> _videos =
      SuikaiService.fetchActiveShortVideos();
  int _currentIndex = 0;
  bool _isMuted = false;
  bool _routeVisible = true;
  bool _appActive = true;
  ModalRoute<void>? _route;

  bool get _playbackActive => _routeVisible && _appActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route == route) return;
    if (_route != null) appRouteObserver.unsubscribe(this);
    _route = route;
    if (route != null) appRouteObserver.subscribe(this, route);
  }

  void _setRouteVisible(bool value) {
    if (mounted && _routeVisible != value) {
      setState(() => _routeVisible = value);
    }
  }

  @override
  void didPush() => _setRouteVisible(true);

  @override
  void didPopNext() => _setRouteVisible(true);

  @override
  void didPushNext() => _setRouteVisible(false);

  @override
  void didPop() => _setRouteVisible(false);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    if (mounted && _appActive != active) {
      setState(() => _appActive = active);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RootScaffold(
    selectedIndex: 3,
    body: FutureBuilder<List<ShortVideoRecord>>(
      future: _videos,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final videos = snapshot.data ?? const [];
        if (videos.isEmpty) {
          return const Center(
            child: LocalizedText(
              'ยังไม่มีวิดีโอสั้น',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          );
        }
        return SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: PageView.builder(
                scrollDirection: Axis.vertical,
                physics: const PageScrollPhysics(),
                itemCount: videos.length,
                onPageChanged: (index) => setState(() {
                  _currentIndex = index;
                  _isMuted = false;
                }),
                itemBuilder: (_, index) {
                  final video = videos[index];
                  if (index != _currentIndex) {
                    return ColoredBox(
                      key: ValueKey('short-video-placeholder-${video.id}'),
                      color: Colors.black,
                    );
                  }
                  return _TikTokVideoPage(
                    key: ValueKey('short-video-${video.id}'),
                    video: video,
                    active: _playbackActive,
                    muted: _isMuted,
                    onMutedChanged: (value) => setState(() => _isMuted = value),
                  );
                },
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _TikTokVideoPage extends StatefulWidget {
  final ShortVideoRecord video;
  final bool active;
  final bool muted;
  final ValueChanged<bool> onMutedChanged;
  const _TikTokVideoPage({
    super.key,
    required this.video,
    required this.active,
    required this.muted,
    required this.onMutedChanged,
  });

  @override
  State<_TikTokVideoPage> createState() => _TikTokVideoPageState();
}

class _TikTokVideoPageState extends State<_TikTokVideoPage> {
  bool _failed = false;

  String? get _videoId {
    final uri = Uri.tryParse(widget.video.tiktokUrl);
    if (uri == null) return null;
    final videoIndex = uri.pathSegments.indexOf('video');
    if (videoIndex >= 0 && videoIndex + 1 < uri.pathSegments.length) {
      final id = uri.pathSegments[videoIndex + 1];
      if (RegExp(r'^\d+$').hasMatch(id)) return id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _videoId;
    final unavailable = _failed || videoId == null;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (!unavailable)
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: TikTokEmbedPlayer(
                  key: ValueKey('tiktok-player-$videoId'),
                  videoId: videoId,
                  active: widget.active,
                  muted: widget.muted,
                  onFailed: () {
                    if (mounted) setState(() => _failed = true);
                  },
                ),
              ),
            ),
          if (unavailable)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.video_file_outlined,
                      color: AppTheme.orange,
                      size: 58,
                    ),
                    const SizedBox(height: 12),
                    const LocalizedText('ไม่สามารถเล่นวิดีโอนี้ได้'),
                  ],
                ),
              ),
            ),
          if (widget.video.title.isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .62),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Text(
                    widget.video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.black.withValues(alpha: .68),
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: AppLocalizations.of(
                  context,
                ).source(widget.muted ? 'เปิดเสียง' : 'ปิดเสียง'),
                onPressed: () => widget.onMutedChanged(!widget.muted),
                color: Colors.white,
                icon: Icon(
                  widget.muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                ),
              ),
            ),
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
  final fmap.MapController _mapController = fmap.MapController();
  final TextEditingController _mapSearch = TextEditingController();
  StoreViewModel? _selected;
  ProductViewModel? _selectedProduct;
  bool _showFilter = false;
  bool _loading = true;
  String _category = 'all';
  String _distance = '25 เมตร';
  List<StoreViewModel> _stores = [];
  List<ProductViewModel> _mapProducts = [];
  bool _filterApplied = false;
  Position? _currentPosition;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  @override
  void dispose() {
    _mapSearch.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _requestLocation() async {
    try {
      final position = await SuikaiService.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = position);
      if (position != null) {
        _mapController.move(
          latlng.LatLng(position.latitude, position.longitude),
          16,
        );
      }
    } on LocationFailure catch (error) {
      if (mounted) {
        showInfo(context, error.userMessage);
      }
    } catch (error, stackTrace) {
      debugPrint('Map current location failed: $error\n$stackTrace');
      if (mounted) showInfo(context, 'ไม่สามารถอ่านตำแหน่งปัจจุบันได้');
    }
  }

  Future<void> _loadMapData() async {
    try {
      final results = await Future.wait([
        SuikaiService.fetchStores(),
        SuikaiService.fetchMapListings(),
      ]);
      final next = results[0].map((item) {
        return StoreViewModel(
          id: item['id'].toString(),
          name: item['name']?.toString() ?? '',
          type: item['category']?.toString() ?? 'ร้านค้า',
          city: item['city']?.toString() ?? '',
          cityId: item['city_id']?.toString(),
          cityRecord: item['cities'] is Map
              ? CityRecord.fromJson(
                  Map<String, dynamic>.from(item['cities'] as Map),
                )
              : null,
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
      final products = results[1].map((item) {
        final images = (item['listing_images'] as List? ?? const [])
            .map((entry) => '${(entry as Map)['image_url'] ?? ''}')
            .where((url) => url.isNotEmpty)
            .toList();
        return ProductViewModel(
          id: '${item['id']}',
          title: '${item['title'] ?? ''}',
          priceValue: (item['price'] as num?)?.toInt() ?? 0,
          currencyCode: '${item['currency'] ?? 'MMK'}',
          description: '${item['description'] ?? ''}',
          category: '${item['category'] ?? ''}',
          city: '${item['city'] ?? ''}',
          cityId: item['city_id']?.toString(),
          cityRecord: item['cities'] is Map
              ? CityRecord.fromJson(
                  Map<String, dynamic>.from(item['cities'] as Map),
                )
              : null,
          location: '${item['city'] ?? ''}',
          time: '${item['created_at'] ?? ''}',
          image: images.firstOrNull ?? '',
          phone: '${item['phone'] ?? ''}',
          viber: '${item['viber_phone'] ?? ''}',
          likeCount: 0,
          viewCount: 0,
          status: _productStatus('${item['status']}'),
          storeId: item['store_id']?.toString(),
          ownerId: item['owner_id']?.toString(),
          images: images,
          latitude: (item['latitude'] as num?)?.toDouble(),
          longitude: (item['longitude'] as num?)?.toDouble(),
          isLocationVisible: item['is_location_visible'] == true,
        );
      }).toList();
      if (mounted) {
        setState(() {
          _stores = next;
          _mapProducts = products;
          MarketplaceCache.cacheProducts(products);
          _loading = false;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Supabase map data query failed: $error\n$stackTrace');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<ProductViewModel> get _productsForView {
    final categoryFiltered = _category == 'all'
        ? _mapProducts
        : _mapProducts
              .where(
                (product) => mapCategoryMatches(product.category, _category),
              )
              .toList();
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return categoryFiltered;
    return categoryFiltered
        .where(
          (product) =>
              product.title.toLowerCase().contains(query) ||
              _categoryLabel(
                context,
                'listing',
                product.category,
              ).toLowerCase().contains(query),
        )
        .toList();
  }

  List<StoreViewModel> get _storesForView {
    final categoryFiltered = _stores
        .where(
          (store) =>
              store.approved && mapCategoryMatches(store.type, _category),
        )
        .toList();
    final normalizedQuery = _query.trim().toLowerCase();
    final searched = normalizedQuery.isEmpty
        ? categoryFiltered
        : categoryFiltered
              .where(
                (store) =>
                    store.name.toLowerCase().contains(normalizedQuery) ||
                    store.type.toLowerCase().contains(normalizedQuery) ||
                    _categoryLabel(
                      context,
                      'store',
                      store.type,
                    ).toLowerCase().contains(normalizedQuery),
              )
              .toList();
    final position = _currentPosition;
    if (position == null || !_filterApplied) return searched;
    return searched.where((store) {
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
    final products = _productsForView;

    return RootScaffold(
      selectedIndex: 3,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0xFFF2F1EC))),
          SafeArea(
            child: Column(
              children: [
                _mapTopBar(),
                _categoryStrip(),
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: _mapMarkers(stores, products)),
                      if (!_loading && stores.isEmpty && products.isEmpty)
                        const Positioned(
                          left: 16,
                          right: 16,
                          top: 16,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                child: LocalizedText(
                                  'ไม่พบรายการในหมวดหมู่นี้',
                                ),
                              ),
                            ),
                          ),
                        ),
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
                      if (_selectedProduct != null)
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 12,
                          child: _selectedProductCard(_selectedProduct!),
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
                  controller: _mapSearch,
                  onChanged: (value) => setState(() {
                    _query = value;
                    _selected = null;
                    _selectedProduct = null;
                  }),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(
                      context,
                    ).source('ค้นหาร้านค้า สินค้า หรือหมวดหมู่'),
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
        if (_query.trim().isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: _storesForView.isEmpty && _productsForView.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: LocalizedText('ไม่พบร้านค้าหรือสินค้า'),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    itemCount: _storesForView.length + _productsForView.length,
                    itemBuilder: (context, index) {
                      if (index >= _storesForView.length) {
                        final product =
                            _productsForView[index - _storesForView.length];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.sell_outlined,
                            color: Colors.blue,
                          ),
                          title: Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(product.price),
                          onTap: () {
                            _mapSearch.text = product.title;
                            setState(() => _query = '');
                            _selectProduct(product);
                          },
                        );
                      }
                      final store = _storesForView[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.storefront_outlined,
                          color: AppTheme.orange,
                        ),
                        title: Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _categoryLabel(context, 'store', store.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          _mapSearch.text = store.name;
                          setState(() => _query = '');
                          _selectStore(store);
                        },
                      );
                    },
                  ),
          ),
      ],
    ),
  );

  Widget _categoryStrip() {
    final items = <(String, String, IconData)>[
      const ('all', 'all', Icons.grid_view_rounded),
      for (final category in [
        ...SuikaiService.categoryRecords('store', activeOnly: true),
        ...SuikaiService.categoryRecords('listing', activeOnly: true),
      ])
        (category.id, category.type, _categoryIcon(category.id)),
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
              _selectedProduct = null;
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
                    child: Icon(item.$3, size: 20, color: AppTheme.orange),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$1 == 'all'
                        ? AppLocalizations.of(context).source('ทั้งหมด')
                        : _categoryLabel(context, item.$2, item.$1),
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

  Widget _mapMarkers(
    List<StoreViewModel> stores,
    List<ProductViewModel> products,
  ) {
    final located = stores
        .where((store) => store.latitude != null && store.longitude != null)
        .toList();
    final initial = _currentPosition == null
        ? const latlng.LatLng(20.8907, 97.1815)
        : latlng.LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
    return fmap.FlutterMap(
      mapController: _mapController,
      options: fmap.MapOptions(initialCenter: initial, initialZoom: 12),
      children: [
        fmap.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.suikai.app',
        ),
        fmap.MarkerLayer(
          markers: [
            if (_currentPosition != null)
              fmap.Marker(
                point: initial,
                width: 30,
                height: 30,
                child: const Icon(Icons.my_location, color: Colors.blue),
              ),
            for (final store in located)
              fmap.Marker(
                point: latlng.LatLng(store.latitude!, store.longitude!),
                width: 104,
                height: 76,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  key: ValueKey('map-store-${store.id}'),
                  onTap: () => _selectStore(store),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selected?.id == store.id
                                ? AppTheme.orange
                                : Colors.white,
                            width: 3,
                          ),
                          boxShadow: const [BoxShadow(blurRadius: 5)],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: store.logo.trim().isEmpty
                            ? const Icon(
                                Icons.storefront_rounded,
                                color: AppTheme.orange,
                              )
                            : persistentImage(
                                store.logo,
                                key: ValueKey(
                                  'map-store-logo-${store.id}-${store.logo}',
                                ),
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.storefront_rounded,
                                  color: AppTheme.orange,
                                ),
                              ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 100),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .92),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            for (final product in products)
              if (product.isLocationVisible &&
                  product.latitude != null &&
                  product.longitude != null)
                fmap.Marker(
                  point: latlng.LatLng(product.latitude!, product.longitude!),
                  width: 104,
                  height: 76,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    key: ValueKey('map-product-${product.id}'),
                    onTap: () => _selectProduct(product),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedProduct?.id == product.id
                                  ? Colors.blue.shade700
                                  : Colors.white,
                              width: 3,
                            ),
                            boxShadow: const [BoxShadow(blurRadius: 5)],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: product.image.trim().isEmpty
                              ? const Icon(
                                  Icons.sell_outlined,
                                  color: Colors.blue,
                                )
                              : persistentImage(
                                  product.image,
                                  key: ValueKey(
                                    'map-product-image-${product.id}-${product.image}',
                                  ),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.blue,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 100),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .92),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
        const fmap.RichAttributionWidget(
          attributions: [
            fmap.TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  void _selectStore(StoreViewModel store) {
    setState(() {
      _selected = store;
      _selectedProduct = null;
    });
    if (store.latitude != null && store.longitude != null) {
      _mapController.move(latlng.LatLng(store.latitude!, store.longitude!), 16);
    }
  }

  void _selectProduct(ProductViewModel product) {
    setState(() {
      _selectedProduct = product;
      _selected = null;
    });
    _mapController.move(
      latlng.LatLng(product.latitude!, product.longitude!),
      16,
    );
  }

  Future<void> _navigateToStore(StoreViewModel store) async {
    final latitude = store.latitude;
    final longitude = store.longitude;
    if (latitude == null || longitude == null) {
      if (mounted) showInfo(context, 'ร้านนี้ไม่มีข้อมูลตำแหน่ง');
      return;
    }
    final destination = '$latitude,$longitude';
    final uri = storeNavigationUri(latitude, longitude);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('maps_launch_failed');
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Open navigation failed: $error destination=$destination\n$stackTrace',
      );
      if (mounted) showInfo(context, 'ไม่สามารถเปิดแอปแผนที่ได้');
    }
  }

  Widget _selectedProductCard(ProductViewModel product) => Material(
    color: Colors.white,
    elevation: 5,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.pushNamed(
        context,
        SuikaiRoutes.productDetail,
        arguments: product.id,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: persistentImage(
                product.image,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  width: 68,
                  height: 68,
                  child: Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    product.price,
                    style: const TextStyle(
                      color: AppTheme.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _statusChip(context, product.status),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );

  Widget _selectedStoreCard(StoreViewModel store) => Material(
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
            ],
          ),
          Row(
            children: [
              Expanded(
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
                    'ดูร้าน',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: store.latitude == null || store.longitude == null
                      ? () => showInfo(context, 'ร้านนี้ไม่มีข้อมูลตำแหน่ง')
                      : () => _navigateToStore(store),
                  icon: const Icon(Icons.navigation_rounded),
                  label: const LocalizedText('นำทาง'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  String _distanceLabel(StoreViewModel store) {
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
    final categories = <(String, String, IconData)>[
      const ('all', 'all', Icons.grid_view_rounded),
      for (final category in [
        ...SuikaiService.categoryRecords('store', activeOnly: true),
        ...SuikaiService.categoryRecords('listing', activeOnly: true),
      ])
        (category.id, category.type, _categoryIcon(category.id)),
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
                          onTap: () => setState(() {
                            _category = item.$1;
                            _selected = null;
                            _selectedProduct = null;
                          }),
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
                                Icon(item.$3, size: 20, color: AppTheme.orange),
                                const SizedBox(height: 5),
                                Text(
                                  item.$1 == 'all'
                                      ? AppLocalizations.of(
                                          context,
                                        ).source('ทั้งหมด')
                                      : _categoryLabel(
                                          context,
                                          item.$2,
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
                              _selectedProduct = null;
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
                              _selectedProduct = null;
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
    for (final p in MarketplaceCache.managedProducts) p.id: p.status,
  };
  List<StoreViewModel> _myStores = [];

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

  Future<void> _loadMyStores() async {
    try {
      final rows = await SuikaiService.fetchMyStores();
      final stores = rows
          .map(
            (item) => StoreViewModel(
              id: item['id'].toString(),
              name: item['name']?.toString() ?? '',
              type: item['category']?.toString() ?? '',
              city: item['city']?.toString() ?? '',
              cityId: item['city_id']?.toString(),
              cityRecord: item['cities'] is Map
                  ? CityRecord.fromJson(
                      Map<String, dynamic>.from(item['cities'] as Map),
                    )
                  : null,
              distance: '',
              logo: item['logo_url']?.toString() ?? '',
              description: item['description']?.toString() ?? '',
              phone: item['phone']?.toString() ?? '',
              viber: item['viber_phone']?.toString() ?? '',
              hours:
                  '${item['opening_time'] ?? ''}-${item['closing_time'] ?? ''}',
              approved: item['status'] == 'approved',
              status: item['status']?.toString() ?? 'pending',
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
          MarketplaceCache.cacheStores(stores);
        });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SuikaiService.currentUserId;
    final all = currentUserId == null
        ? <ProductViewModel>[]
        : MarketplaceCache.products
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
                                store.effectiveStatus == 'approved'
                                    ? 'อนุมัติแล้ว'
                                    : store.effectiveStatus == 'rejected'
                                    ? 'ไม่ผ่านการอนุมัติ'
                                    : 'รอการอนุมัติ',
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
                                MarketplaceCache.setStatus(item.id, value);
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
  final _minimumPrice = TextEditingController();
  final _maximumPrice = TextEditingController();
  String _category = 'all';
  String _city = 'all';
  String _currency = 'MMK';
  FxSnapshot? _fx;

  @override
  void initState() {
    super.initState();
    FxService().latest().then((value) {
      if (mounted) setState(() => _fx = value);
    });
  }

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
    _minimumPrice.dispose();
    _maximumPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>[
      'all',
      ...SuikaiService.categoryRecords('listing').map((value) => value.id),
    ];
    final cities = <String, String>{
      'all': AppLocalizations.of(context).source('ทั้งหมด'),
    };
    for (final product in MarketplaceCache.products) {
      final key = product.city.trim();
      if (key.isNotEmpty) cities[key] = productCityLabel(context, product);
    }
    final query = _searchController.text.toLowerCase().trim();

    final results = MarketplaceCache.feedProducts.where((product) {
      final price = _fx == null
          ? product.priceValue.toDouble()
          : FxService().convert(
              product.priceValue.toDouble(),
              product.currencyCode,
              _currency,
              _fx!,
            );
      final matchesQuery =
          query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query);
      final matchesCategory =
          _category == 'all' ||
          SuikaiService.categoryIdForValue('listing', product.category) ==
              _category;
      final productCityKey = product.city.trim();
      final matchesCity = _city == 'all' || productCityKey == _city;
      final minimum = parsePriceValue(_minimumPrice.text);
      final maximum = parsePriceValue(_maximumPrice.text);
      final matchesPrice =
          (minimum == null || maximum == null || minimum <= maximum) &&
          (minimum == null || price >= minimum) &&
          (maximum == null || price <= maximum);
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
            child: _NumericPriceRange(
              minimum: _minimumPrice,
              maximum: _maximumPrice,
              currency: _currency,
              onCurrencyChanged: (value) => setState(() => _currency = value),
              onChanged: () => setState(() {}),
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
                child: Row(
                  children: [
                    Icon(
                      category == 'all'
                          ? Icons.grid_view_rounded
                          : _categoryIcon(category),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category == 'all'
                            ? AppLocalizations.of(context).source('ทั้งหมด')
                            : _categoryLabel(context, 'listing', category),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: (value) => setState(() => _category = value ?? _category),
      );

  Widget _cityField(Map<String, String> cities) =>
      DropdownButtonFormField<String>(
        initialValue: _city,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).source('เมือง'),
        ),
        items: cities.entries
            .map(
              (city) => DropdownMenuItem(
                value: city.key,
                child: Text(
                  city.value,
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

  @override
  void initState() {
    super.initState();
    InteractionStore.trackView(widget.productId);
    MarketplaceCache.productsRevision.addListener(_refreshWhenProductLoads);
  }

  @override
  void dispose() {
    MarketplaceCache.productsRevision.removeListener(_refreshWhenProductLoads);
    super.dispose();
  }

  void _refreshWhenProductLoads() {
    if (mounted && MarketplaceCache.productById(widget.productId) != null) {
      setState(() {});
    }
  }

  Future<void> _copyProductLink(ProductViewModel product) async {
    final link = Uri.base
        .replace(
          path: Uri.base.path.isEmpty ? '/' : Uri.base.path,
          queryParameters: {'product': product.id},
        )
        .toString();
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) showInfo(context, 'คัดลอกลิงก์สินค้าแล้ว');
  }

  Future<void> _edit(ProductViewModel product) async {
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
                final cityName = normalizeText(city.text);
                if (cityName.isEmpty) {
                  showInfo(context, 'กรุณาเลือกเมือง');
                  return;
                }
                try {
                  await SuikaiService.updateListing(
                    listingId: product.id,
                    title: title.text.trim(),
                    description: description.text.trim(),
                    city: cityName,
                    cityId: product.cityId,
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
    final product = MarketplaceCache.productById(widget.productId);
    if (product == null) {
      return const _MissingPage(title: 'ไม่พบสินค้า');
    }
    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText('รายละเอียดสินค้า'),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).source('แชร์สินค้า'),
            onPressed: () => _copyProductLink(product),
            icon: const Icon(Icons.link_rounded),
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
                MarketplaceCache.removeProduct(product.id);
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
                  itemBuilder: (context, index) => GestureDetector(
                    key: ValueKey('product-image-${product.imageUrls[index]}'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _FullscreenImageViewer(
                          images: product.imageUrls,
                          initialIndex: index,
                        ),
                      ),
                    ),
                    child: ColoredBox(
                      color: const Color(0xFFF5F5F5),
                      child: persistentImage(
                        product.imageUrls[index],
                        key: ValueKey(
                          'detail-image-${product.imageUrls[index]}',
                        ),
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(Icons.broken_image_outlined),
                        ),
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
          Builder(
            builder: (context) {
              final cityName = productCityLabel(context, product);
              return Row(
                children: [
                  const LocalizedText('เมือง'),
                  const Text(': '),
                  Expanded(
                    child: Text(
                      cityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
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

class _FullscreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _FullscreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (_, index) => _ZoomableProductImage(
              key: ValueKey(widget.images[index]),
              source: widget.images[index],
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: IconButton.filledTonal(
              key: const ValueKey('close-fullscreen-image'),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          Positioned(
            right: 16,
            top: 18,
            child: Text(
              '${_index + 1}/${widget.images.length}',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ZoomableProductImage extends StatefulWidget {
  final String source;
  const _ZoomableProductImage({super.key, required this.source});

  @override
  State<_ZoomableProductImage> createState() => _ZoomableProductImageState();
}

class _ZoomableProductImageState extends State<_ZoomableProductImage> {
  final TransformationController _transformation = TransformationController();

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  void _doubleTap() {
    _transformation.value = _transformation.value.isIdentity()
        ? (Matrix4.identity()..scale(2.5))
        : Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onDoubleTap: _doubleTap,
    child: InteractiveViewer(
      transformationController: _transformation,
      minScale: 1,
      maxScale: 5,
      child: Center(
        child: persistentImage(
          widget.source,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.broken_image_outlined, color: Colors.white),
        ),
      ),
    ),
  );
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
  final _city = TextEditingController();
  String _shopType = '';
  String _hours = 'เปิดทุกวัน';
  bool _accepted = false;
  bool _submitting = false;
  SelectedImage? _logoImage;
  SelectedImage? _coverImage;
  latlng.LatLng? _storePosition;

  static const _steps = [
    'ข้อมูลร้านค้า',
    'ข้อมูลติดต่อ',
    'ตำแหน่งร้านค้า',
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
    for (final c in [_name, _description, _phone, _viber, _email, _city]) {
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
      if (normalizeText(_city.text).isEmpty) {
        showInfo(context, 'กรุณากรอกชื่อเมือง');
        return;
      }
      if (_storePosition == null) {
        showInfo(context, 'กรุณาเลือกตำแหน่งร้านค้าบนแผนที่');
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
      if (position != null) {
        setState(
          () => _storePosition = latlng.LatLng(
            position.latitude,
            position.longitude,
          ),
        );
      }
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
            onPressed: () => showInfo(context, 'บันทึกฉบับร่างแล้ว'),
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
          'ตำแหน่งร้านค้า',
          subtitle: 'เลือกพิกัดด้วย GPS หรือแตะปักหมุดบนแผนที่',
        ),
        LocationPickerMap(
          value: _storePosition,
          onChanged: (point) => setState(() => _storePosition = point),
          currentLocation: () async {
            final position = await SuikaiService.getCurrentPosition();
            return position == null
                ? null
                : latlng.LatLng(position.latitude, position.longitude);
          },
        ),
        const SizedBox(height: 18),
        const LocalizedText(
          'เมือง *',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _city,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).source('กรอกชื่อเมือง'),
          ),
          validator: (value) => normalizeText(value).isEmpty
              ? AppLocalizations.of(context).source('กรุณากรอกชื่อเมือง')
              : null,
        ),
        const SizedBox(height: 18),
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
          title: 'ตำแหน่งร้านค้า',
          lines: [
            normalizeText(_city.text).isEmpty
                ? AppLocalizations.of(context).source('ไม่ระบุเมือง')
                : normalizeText(_city.text),
            _storePosition == null
                ? 'ยังไม่ได้เลือกพิกัด'
                : '${_storePosition!.latitude.toStringAsFixed(6)}, ${_storePosition!.longitude.toStringAsFixed(6)}',
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
                  final cityName = normalizeText(_city.text);
                  if (cityName.isEmpty) {
                    showInfo(context, 'กรุณากรอกชื่อเมือง');
                    return;
                  }
                  setState(() => _submitting = true);
                  try {
                    await SuikaiService.createStore(
                      name: normalizeText(_name.text),
                      description: normalizeText(_description.text),
                      category: _shopType,
                      city: cityName,
                      cityId: null,
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
  final ProductViewModel product;

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
                          child: Text(
                            productCityLabel(context, product),
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
