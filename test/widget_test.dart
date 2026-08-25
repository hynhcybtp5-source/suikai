import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:suikai/features/home/home_page.dart';
import 'package:suikai/features/admin/admin_dashboard.dart';
import 'package:suikai/l10n/app_localizations.dart';
import 'package:suikai/main.dart';
import 'package:suikai/core/locale_controller.dart';
import 'package:suikai/data/models.dart';
import 'package:suikai/services/suikai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'support/in_memory_repositories.dart';

void main() {
  late Directory databaseDirectory;

  setUpAll(() async {
    databaseDirectory = await Directory.systemTemp.createTemp(
      'suikai_widget_test_',
    );
    Hive.init(databaseDirectory.path);
    TestDatabase.users = await Hive.openBox('users');
    TestDatabase.listings = await Hive.openBox('listings');
    TestDatabase.stores = await Hive.openBox('stores');
    TestDatabase.interactions = await Hive.openBox('interactions');
    TestDatabase.reports = await Hive.openBox('reports');
    TestDatabase.storeEditRequests = await Hive.openBox('store_edits');
    TestDatabase.promotionRequests = await Hive.openBox('promotions');
    TestDatabase.categories = await Hive.openBox('categories');
    TestDatabase.adminNotifications = await Hive.openBox('admin_notifications');
    TestDatabase.notifications = await Hive.openBox('notifications');
    TestDatabase.shortVideos = await Hive.openBox('short_videos');
  });

  tearDownAll(() async {
    await Hive.close();
    await databaseDirectory.delete(recursive: true);
  });

  setUp(() async {
    for (final box in [
      TestDatabase.users,
      TestDatabase.listings,
      TestDatabase.stores,
      TestDatabase.interactions,
      TestDatabase.reports,
      TestDatabase.storeEditRequests,
      TestDatabase.promotionRequests,
      TestDatabase.categories,
      TestDatabase.adminNotifications,
      TestDatabase.shortVideos,
      TestDatabase.notifications,
    ]) {
      await box?.clear();
    }
    SharedPreferences.setMockInitialValues({'selected_locale': 'th'});
    final auth = InMemoryAuthRepository();
    SuikaiService.auth = auth;
    SuikaiService.legalConsents = InMemoryLegalConsentRepository(
      () => auth.currentUserId,
    );
    SuikaiService.profiles = InMemoryProfileRepository();
    SuikaiService.listings = InMemoryListingRepository();
    SuikaiService.stores = InMemoryStoreRepository();
    SuikaiService.storeRequests = InMemoryStoreRequestRepository();
    SuikaiService.categoryRepository = InMemoryCategoryRepository();
    SuikaiService.admin = InMemoryAdminRepository();
    SuikaiService.likes = InMemoryLikeRepository();
    SuikaiService.reports = InMemoryReportRepository();
    SuikaiService.notifications = InMemoryNotificationRepository();
    SuikaiService.shortVideos = InMemoryShortVideoRepository();
    SuikaiService.deviceId = 'widget-test-device';
    SuikaiService.advertisements = InMemoryAdvertisementRepository();
    SuikaiService.storage = InMemoryStorageService();
    SuikaiService.setCategoriesForTesting(const [
      CategoryRecord(
        id: 'listing_mobile',
        type: 'listing',
        nameTh: 'มือถือ',
        nameShn: 'မိုဝ်းထိုဝ်',
        nameEn: 'Mobile',
        nameMy: 'မိုဘိုင်း',
        sortOrder: 0,
      ),
    ]);
    SuikaiService.setCitiesForTesting(const []);
    MarketplaceCache.stores
      ..clear()
      ..add(
        const StoreViewModel(
          id: 'test-store',
          name: 'Test Store',
          type: 'store_mobile',
          city: 'เมืองนาง',
          distance: '1 กม.',
          logo: '',
          description: 'Store for widget tests',
          phone: '0912345678',
          viber: '0912345678',
          hours: '09:00-18:00',
          approved: true,
          ownerId: 'test-owner',
        ),
      );
    MarketplaceCache.products
      ..clear()
      ..addAll([
        const ProductViewModel(
          id: 'test-general',
          title: 'General product',
          priceValue: 100,
          description: 'General listing',
          category: 'listing_mobile',
          city: 'เมืองนาง',
          location: 'เมืองนาง',
          time: 'now',
          image: 'https://example.invalid/general.jpg',
          phone: '0912345678',
          viber: '0912345678',
          likeCount: 0,
          viewCount: 0,
          status: ProductStatus.reserved,
          video: ListingVideoRecord(
            id: 'general-video',
            videoMediaId: 'general-video-media',
            thumbnailMediaId: 'general-thumbnail-media',
            videoPath: 'general.mp4',
            thumbnailPath: 'general.jpg',
            durationMilliseconds: 1000,
            sizeBytes: 1024,
          ),
        ),
        const ProductViewModel(
          id: 'test-store-product',
          title: 'Store product',
          priceValue: 200,
          description: 'Store listing',
          category: 'listing_mobile',
          city: 'เมืองนาง',
          location: 'เมืองนาง',
          time: 'now',
          image: 'https://example.invalid/store.jpg',
          phone: '0912345678',
          viber: '0912345678',
          likeCount: 0,
          viewCount: 0,
          status: ProductStatus.available,
          storeId: 'test-store',
          ownerId: 'test-owner',
          video: ListingVideoRecord(
            id: 'store-video',
            videoMediaId: 'store-video-media',
            thumbnailMediaId: 'store-thumbnail-media',
            videoPath: 'store.mp4',
            thumbnailPath: 'store.jpg',
            durationMilliseconds: 1000,
            sizeBytes: 1024,
          ),
        ),
      ]);
  });

  testWidgets('Home page renders Suikai UI', (WidgetTester tester) async {
    await tester.pumpWidget(const SuikaiApp());

    expect(find.text('Suikai'), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
  });

  test('price parsing and validation helpers work as expected', () {
    expect(parsePriceValue('1,200'), 1200);
    expect(parsePriceValue(' 0 '), 0);
    expect(parsePriceValue('abc'), isNull);
    expect(validatePhone('09 9999 9999'), isNull);
    expect(validateEmail('user@example.com'), isNull);
    expect(validateEmail('bad-email'), isNotNull);
    expect(validateRequiredCity('   '), 'กรุณากรอกชื่อเมือง');
    expect(validateRequiredCity('  User City  '), isNull);
  });

  testWidgets('video listing opens its metadata dialog for a store post', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PostPage(storeId: 'test-store'),
      ),
    );
    await tester.pump();

    expect(find.text('ข้อมูลสินค้า'), findsOneWidget);
    expect(find.text('ชื่อสินค้า *'), findsOneWidget);
    expect(find.text('หมวดหมู่ *'), findsOneWidget);
    expect(find.text('ราคา *'), findsOneWidget);
  });

  testWidgets('video listing metadata requires a category', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PostPage(storeId: 'test-store'),
      ),
    );
    await tester.pump();
    expect(find.text('หมวดหมู่ *'), findsOneWidget);
  });

  test('map category filter uses exact Supabase category ids', () {
    expect(mapCategoryMatches('store_food', 'all'), isTrue);
    expect(mapCategoryMatches('store_food', 'store_food'), isTrue);
    expect(mapCategoryMatches('store_food', 'store_cafe'), isFalse);
    expect(mapCategoryMatches('listing_it', 'store_food'), isFalse);
  });

  test('store navigation URL keeps the exact destination coordinates', () {
    final uri = storeNavigationUri(20.8907, 97.1815);
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['api'], '1');
    expect(uri.queryParameters['destination'], '20.8907,97.1815');
  });

  test('product sharing always selects that product primary image', () {
    final general = MarketplaceCache.products.firstWhere(
      (product) => !product.isStoreProduct,
    );
    final store = MarketplaceCache.products.firstWhere(
      (product) => product.isStoreProduct,
    );
    expect(primaryProductImage(general), general.imageUrls.first);
    expect(primaryProductImage(store), store.imageUrls.first);
    expect(
      primaryProductImage(
        const ProductViewModel(
          id: 'no-image',
          title: 'No image',
          priceValue: 0,
          description: '',
          category: '',
          city: '',
          location: '',
          time: '',
          image: '',
          phone: '',
          viber: '',
          likeCount: 0,
          viewCount: 0,
          status: ProductStatus.available,
        ),
      ),
      isNull,
    );
  });

  test('sold general listing remains managed but leaves public feed', () {
    final product = MarketplaceCache.products.firstWhere(
      (value) => !value.isStoreProduct && value.status != ProductStatus.sold,
    );
    final originalStatus = product.status;
    final revisionBefore = MarketplaceCache.productsRevision.value;
    MarketplaceCache.setStatus(product.id, ProductStatus.sold);
    expect(MarketplaceCache.productsRevision.value, revisionBefore + 1);
    expect(MarketplaceCache.productById(product.id), isNotNull);
    expect(
      MarketplaceCache.feedProducts.any((value) => value.id == product.id),
      isFalse,
    );
    MarketplaceCache.setStatus(product.id, originalStatus);
  });

  testWidgets('Admin route is protected by separate login', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminDashboard()));
    expect(find.text('Admin Login'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ Admin'), findsOneWidget);
    expect(find.text('Suikai Admin'), findsNothing);
  });

  testWidgets('Mobile material popup supports every language switch', (
    tester,
  ) async {
    for (final code in const ['th', 'shn', 'en', 'my', 'shn']) {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          locale: Locale(code),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ShanMaterialLocalizationsDelegate(),
            ShanWidgetsLocalizationsDelegate(),
            ShanCupertinoLocalizationsDelegate(),
          ],
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => PopupMenuButton<String>(
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'th', child: Text('ไทย')),
                    PopupMenuItem(value: 'shn', child: Text('လိၵ်ႈတႆး')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final popup = find.byType(PopupMenuButton<String>);
      expect(MaterialLocalizations.of(tester.element(popup)), isNotNull);
      await tester.tap(popup);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('လိၵ်ႈတႆး'), findsOneWidget);
      expect(tester.takeException(), isNull);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pump(const Duration(milliseconds: 400));
    }
  });

  testWidgets('Mobile language changes in place without changing route', (
    tester,
  ) async {
    await localeController.setLocale('th');
    await tester.pumpWidget(const SuikaiApp());
    expect(find.text('ซื้อขายง่าย ใกล้คุณ'), findsOneWidget);

    await localeController.setLocale('en');
    await tester.pumpAndSettle();
    expect(find.text('Buy and sell easily nearby'), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);

    await localeController.setLocale('my');
    await tester.pumpAndSettle();
    expect(
      find.text('အနီးအနားမှာ လွယ်လွယ်ကူကူ ဝယ်/ရောင်းနိုင်ပါတယ်'),
      findsOneWidget,
    );

    await localeController.setLocale('shn');
    await tester.pumpAndSettle();
    expect(find.text('သိုဝ်ႉၶၢႆငၢႆႈငၢႆႈ ၸမ်ၸဝ်ႈ'), findsOneWidget);
  });

  testWidgets('Shared header menu changes language and keeps route history', (
    tester,
  ) async {
    await localeController.setLocale('th');
    await tester.pumpWidget(const SuikaiApp());
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    expect(find.text('เปลี่ยนภาษา'), findsOneWidget);
    expect(find.text('แผนที่'), findsWidgets);
    expect(find.text('ค้นหา'), findsOneWidget);
    expect(find.text('การแจ้งเตือน'), findsOneWidget);

    await tester.tap(find.text('เปลี่ยนภาษา'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Buy and sell easily nearby'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets('Listing card uses status color without status text', (
    tester,
  ) async {
    final product = MarketplaceCache.products.firstWhere(
      (item) => item.status == ProductStatus.reserved,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('th'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ShanMaterialLocalizationsDelegate(),
          ShanWidgetsLocalizationsDelegate(),
          ShanCupertinoLocalizationsDelegate(),
        ],
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 260,
            child: ProductCard(product: product),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('จอง'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Store product starts with the shared video metadata popup', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ShanMaterialLocalizationsDelegate(),
          ShanWidgetsLocalizationsDelegate(),
          ShanCupertinoLocalizationsDelegate(),
        ],
        home: const PostPage(storeId: 'store-test'),
      ),
    );
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search stays responsive for every supported mobile language', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final code in const ['th', 'shn', 'en', 'my']) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(code),
          locale: Locale(code),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ShanMaterialLocalizationsDelegate(),
            ShanWidgetsLocalizationsDelegate(),
            ShanCupertinoLocalizationsDelegate(),
          ],
          home: const SearchPage(),
        ),
      );
      await tester.pump();
      expect(find.byType(SearchPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('video listing edit entry explains the current restriction', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('th'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ShanMaterialLocalizationsDelegate(),
          ShanWidgetsLocalizationsDelegate(),
          ShanCupertinoLocalizationsDelegate(),
        ],
        home: const EditListingPage(productId: 'test-store-product'),
      ),
    );
    await tester.pump();
    expect(find.text('ประกาศวิดีโอแก้ไขได้เฉพาะข้อมูลสถานะ'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('video listing edit restriction is locale-safe', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ShanMaterialLocalizationsDelegate(),
          ShanWidgetsLocalizationsDelegate(),
          ShanCupertinoLocalizationsDelegate(),
        ],
        home: const EditListingPage(productId: 'test-general'),
      ),
    );
    await tester.pump();
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('video metadata dialog is responsive in every supported locale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final code in const ['th', 'en', 'my', 'shn']) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(code),
          locale: Locale(code),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ShanMaterialLocalizationsDelegate(),
            ShanWidgetsLocalizationsDelegate(),
            ShanCupertinoLocalizationsDelegate(),
          ],
          home: const PostPage(storeId: 'test-store'),
        ),
      );
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pump();
    }
  });
}
