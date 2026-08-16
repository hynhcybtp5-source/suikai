import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  setUp(() {
    SharedPreferences.setMockInitialValues({'selected_locale': 'th'});
    SuikaiService.auth = InMemoryAuthRepository();
    SuikaiService.admin = InMemoryAdminRepository();
    SuikaiService.advertisements = InMemoryAdvertisementRepository();
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
          image: '/general.jpg',
          phone: '0912345678',
          viber: '0912345678',
          likeCount: 0,
          viewCount: 0,
          status: ProductStatus.reserved,
          images: ['/general.jpg'],
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
          image: '',
          phone: '0912345678',
          viber: '0912345678',
          likeCount: 0,
          viewCount: 0,
          status: ProductStatus.available,
          storeId: 'test-store',
          ownerId: 'test-owner',
          images: ['/image.jpg'],
        ),
      ]);
  });

  testWidgets('Home page renders Suikai UI', (WidgetTester tester) async {
    await tester.pumpWidget(const SuikaiApp());

    expect(find.text('Suikai'), findsOneWidget);
    expect(find.text('ซื้อขายง่าย ใกล้คุณ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('ประกาศล่าสุด'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ประกาศล่าสุด'), findsOneWidget);
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

  testWidgets('complete basic listing data advances without GPS or city id', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PostPage(startGeneral: true),
      ),
    );
    await tester.pump();

    final categoryField = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );
    categoryField.onChanged?.call('listing_mobile');
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ใส่ชื่อสินค้าที่ต้องการขาย'),
      'Regression product',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ระบุราคา'),
      '100',
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
    await tester.pump();
    tester
        .widget<ElevatedButton>(
          find.descendant(
            of: find.byKey(const ValueKey('general-basic-next')),
            matching: find.byType(ElevatedButton),
          ),
        )
        .onPressed!
        .call();
    await tester.pump();

    expect(find.text('รูปภาพสินค้า'), findsOneWidget);
  });

  testWidgets('missing category shows an error on the visible basic step', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('th'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PostPage(startGeneral: true),
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ใส่ชื่อสินค้าที่ต้องการขาย'),
      'Regression product',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ระบุราคา'),
      '100',
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
    await tester.pump();
    tester
        .widget<ElevatedButton>(
          find.descendant(
            of: find.byKey(const ValueKey('general-basic-next')),
            matching: find.byType(ElevatedButton),
          ),
        )
        .onPressed!
        .call();
    await tester.pumpAndSettle();

    expect(find.text('กรุณาเลือกหมวดหมู่สินค้า'), findsOneWidget);
    expect(find.text('ข้อมูลพื้นฐาน'), findsOneWidget);
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

  test('short video accepts only HTTPS TikTok URLs', () {
    expect(
      ShortVideoRecord.isValidTikTokUrl(
        'https://www.tiktok.com/@suikai/video/1234567890',
      ),
      isTrue,
    );
    expect(
      ShortVideoRecord.isValidTikTokUrl('https://vm.tiktok.com/abc123/'),
      isTrue,
    );
    expect(
      ShortVideoRecord.isValidTikTokUrl('https://example.com/video/123'),
      isFalse,
    );
    expect(ShortVideoRecord.isValidTikTokUrl('javascript:alert(1)'), isFalse);
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
    MarketplaceCache.setStatus(product.id, ProductStatus.sold);
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

  testWidgets(
    'Store product form exposes five image slots and store statuses',
    (tester) async {
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
      expect(find.text('Add store product'), findsOneWidget);
      expect(find.text('0/5'), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsNWidgets(4));
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      final statusDropdown = find.byWidgetPredicate(
        (widget) => widget is DropdownButtonFormField<ProductStatus>,
      );
      await tester.tap(statusDropdown);
      await tester.pumpAndSettle();
      expect(find.text('Available'), findsWidgets);
      expect(find.text('Out of stock'), findsOneWidget);
      expect(find.text('Deleted'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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

  testWidgets('Store product edit form pre-fills existing record and images', (
    tester,
  ) async {
    final product = MarketplaceCache.products.firstWhere(
      (value) => value.isStoreProduct,
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
        home: EditListingPage(productId: product.id),
      ),
    );
    await tester.pump();
    expect(
      find.text(product.imageUrls.take(5).length.toString() + '/5'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    final values = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .map((field) => field.controller?.text)
        .whereType<String>()
        .toSet();
    expect(values, contains(product.title));
    expect(values, contains(product.description));
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    final lowerValues = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .map((field) => field.controller?.text)
        .whereType<String>()
        .toSet();
    expect(lowerValues, contains(product.priceValue.toString()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('General listing uses the same pre-filled edit form', (
    tester,
  ) async {
    final product = MarketplaceCache.products.firstWhere(
      (value) => !value.isStoreProduct,
    );
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
        home: EditListingPage(productId: product.id),
      ),
    );
    await tester.pump();
    expect(
      find.text(product.imageUrls.take(5).length.toString() + '/5'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    final values = tester
        .widgetList<TextFormField>(find.byType(TextFormField))
        .map((field) => field.controller?.text)
        .whereType<String>()
        .toSet();
    expect(values, contains(product.title));
    expect(values, contains(product.description));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Post type cards are responsive, localized, and fully tappable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const titles = {
      'th': 'เพิ่มสินค้าทั่วไป',
      'en': 'Add a general item',
      'my': 'အထွေထွေပစ္စည်း ထည့်ရန်',
      'shn': 'ထႅမ်ၶူဝ်းၶၢႆထမ်းမတႃး',
    };
    for (final entry in titles.entries) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(entry.key),
          locale: Locale(entry.key),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            ShanMaterialLocalizationsDelegate(),
            ShanWidgetsLocalizationsDelegate(),
            ShanCupertinoLocalizationsDelegate(),
          ],
          routes: {
            SuikaiRoutes.openShop: (_) =>
                const Scaffold(body: Text('open-store-flow')),
          },
          home: const PostPage(),
        ),
      );
      await tester.pump();
      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.tap(find.byKey(const ValueKey('general-listing-choice')));
    await tester.pumpWidget(
      MaterialApp(
        key: const ValueKey('open-card-navigation'),
        locale: const Locale('th'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
          ShanMaterialLocalizationsDelegate(),
          ShanWidgetsLocalizationsDelegate(),
          ShanCupertinoLocalizationsDelegate(),
        ],
        routes: {
          SuikaiRoutes.openShop: (_) =>
              const Scaffold(body: Text('open-store-flow')),
        },
        home: const PostPage(),
      ),
    );
    await tester.ensureVisible(find.byKey(const ValueKey('open-store-choice')));
    await tester.tap(find.byKey(const ValueKey('open-store-choice')));
    await tester.pumpAndSettle();
    expect(find.text('open-store-flow'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
