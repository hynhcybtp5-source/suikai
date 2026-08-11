import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suikai/data/local_repositories.dart';
import 'package:suikai/data/models.dart';
import 'package:suikai/services/suikai_service.dart';

void main() {
  late Directory databaseDirectory;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    databaseDirectory = await Directory.systemTemp.createTemp(
      'suikai_moderation_test_',
    );
    Hive.init(databaseDirectory.path);
    LocalDatabase.users = await Hive.openBox('users');
    LocalDatabase.listings = await Hive.openBox('listings');
    LocalDatabase.stores = await Hive.openBox('stores');
    LocalDatabase.interactions = await Hive.openBox('interactions');
    LocalDatabase.reports = await Hive.openBox('reports');
    LocalDatabase.storeEditRequests = await Hive.openBox('store_edits');
    LocalDatabase.promotionRequests = await Hive.openBox('promotions');
    LocalDatabase.categories = await Hive.openBox('categories');
  });

  tearDownAll(() async {
    await Hive.close();
    await databaseDirectory.delete(recursive: true);
  });

  test('store changes and promotion require admin approval', () async {
    final storeRepository = LocalStoreRepository();
    final requests = LocalStoreRequestRepository();
    final admin = LocalAdminRepository();
    final store = StoreRecord(
      id: 'store-1',
      ownerId: 'owner-1',
      name: 'Before',
      logo: '',
      description: '',
      category: 'ร้านอาหาร',
      phone: '0912345678',
      viber: '',
      city: 'เมืองนาง',
      location: 'เมืองนาง',
      openingHours: '09:00-18:00',
      status: 'approved',
      createdAt: DateTime(2026),
    );
    await storeRepository.create(store);
    await requests.submitEdit(
      StoreEditRequestRecord(
        id: 'edit-1',
        storeId: store.id,
        ownerId: store.ownerId,
        proposedChanges: const {'name': 'After'},
        createdAt: DateTime(2026, 2),
      ),
    );

    expect((await storeRepository.all()).single.name, 'Before');
    expect(await admin.login('admin@suikai.local', 'admin1234'), isTrue);
    await admin.reviewStoreEditRequest('edit-1', true);
    expect((await storeRepository.all()).single.name, 'After');

    await requests.submitPromotion(
      PromotionRequestRecord(
        id: 'promotion-1',
        storeId: store.id,
        ownerId: store.ownerId,
        createdAt: DateTime(2026, 3),
      ),
    );
    expect((await storeRepository.all()).single.isPromoted, isFalse);
    await admin.reviewPromotionRequest('promotion-1', true);
    expect((await storeRepository.all()).single.isPromoted, isTrue);
  });

  test(
    'central categories persist, localize, deactivate and reorder',
    () async {
      final repository = LocalCategoryRepository();
      await repository.seedDefaults();
      await repository.migrateLegacyReferences();

      expect(
        (await LocalStoreRepository().all()).single.category,
        'store_food',
      );

      const added = CategoryRecord(
        id: 'listing_test',
        type: 'listing',
        nameTh: 'ทดสอบ',
        nameShn: 'တူဝ်ထတ်း',
        nameEn: 'Test',
        nameMy: 'စမ်းသပ်',
        sortOrder: 99,
      );
      await repository.add(added);
      expect(added.localizedName('th'), 'ทดสอบ');
      expect(added.localizedName('shn'), 'တူဝ်ထတ်း');
      expect(added.localizedName('en'), 'Test');
      expect(added.localizedName('my'), 'စမ်းသပ်');

      await repository.setActive(added.id, false);
      expect(
        (await repository.getByType(
          'listing',
          activeOnly: true,
        )).any((value) => value.id == added.id),
        isFalse,
      );
      expect(
        (await repository.getByType(
          'listing',
        )).any((value) => value.id == added.id),
        isTrue,
      );
      await repository.update(
        const CategoryRecord(
          id: 'listing_test',
          type: 'listing',
          nameTh: 'ทดสอบแก้ไข',
          nameShn: 'တူဝ်ထတ်း',
          nameEn: 'Edited',
          nameMy: 'စမ်းသပ်',
          isActive: false,
          sortOrder: 99,
        ),
      );
      expect(
        (await repository.getByType(
          'listing',
        )).singleWhere((value) => value.id == added.id).nameEn,
        'Edited',
      );

      final ids = (await repository.getByType(
        'listing',
      )).map((value) => value.id).toList();
      await repository.reorder('listing', [added.id, ...ids..remove(added.id)]);
      expect((await repository.getByType('listing')).first.id, added.id);

      await LocalDatabase.categories.close();
      LocalDatabase.categories = await Hive.openBox('categories');
      expect(
        (await repository.getByType(
          'listing',
        )).singleWhere((value) => value.id == added.id).isActive,
        isFalse,
      );
    },
  );

  test('store product edit preserves id and unchanged image paths', () async {
    final profile = await SuikaiService.register(
      name: 'Owner',
      phone: '0912345678',
      email: 'owner@suikai.local',
      password: 'password123',
    );
    await SuikaiService.login(profile.email, 'password123');
    final createdAt = DateTime(2026, 4);
    await LocalListingRepository().create(
      ListingRecord(
        id: 'store-product-edit',
        ownerId: profile.id,
        storeId: 'store-1',
        title: 'Before',
        description: 'Original details',
        category: 'listing_mobile',
        price: 100,
        currency: 'THB',
        city: 'เมืองนาง',
        status: 'available',
        images: const ['/persistent/image-a.jpg', '/persistent/image-b.jpg'],
        phone: '0912345678',
        viber: '0912345678',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );

    await SuikaiService.updateListing(
      listingId: 'store-product-edit',
      title: 'After',
      description: 'Original details',
      city: 'เมืองนาง',
      phone: '0912345678',
      viber: '0912345678',
      price: 100,
      currency: 'THB',
      status: 'reserved',
    );
    var saved = (await LocalListingRepository().all()).singleWhere(
      (value) => value.id == 'store-product-edit',
    );
    expect(saved.id, 'store-product-edit');
    expect(saved.createdAt, createdAt);
    expect(saved.images, const [
      '/persistent/image-a.jpg',
      '/persistent/image-b.jpg',
    ]);

    await SuikaiService.updateListing(
      listingId: saved.id,
      title: saved.title,
      description: saved.description,
      city: saved.city,
      phone: saved.phone,
      viber: saved.viber,
      price: saved.price,
      currency: saved.currency,
      status: saved.status,
      images: const ['/persistent/replacement.jpg'],
    );
    await LocalDatabase.listings.close();
    LocalDatabase.listings = await Hive.openBox('listings');
    saved = (await LocalListingRepository().all()).singleWhere(
      (value) => value.id == 'store-product-edit',
    );
    expect(saved.images, const ['/persistent/replacement.jpg']);
    expect(
      (await LocalListingRepository().all())
          .where((value) => value.id == 'store-product-edit')
          .length,
      1,
    );
  });

  test('location privacy fields persist and 500 km uses coordinates', () {
    final now = DateTime(2026, 5);
    final record = ListingRecord(
      id: 'located-listing',
      ownerId: 'owner-location',
      title: 'Located',
      description: '',
      category: 'listing_other',
      price: 1,
      currency: 'THB',
      city: 'Test city',
      status: 'available',
      images: const [],
      phone: '',
      viber: '',
      latitude: 19.0,
      longitude: 97.0,
      isLocationVisible: false,
      createdAt: now,
      updatedAt: now,
    );
    final restored = ListingRecord.fromJson(record.toJson());
    expect(restored.latitude, 19.0);
    expect(restored.longitude, 97.0);
    expect(restored.isLocationVisible, isFalse);
    expect(SuikaiService.distanceKm(0, 0, 0, 1), closeTo(111.3, 1));
    expect(SuikaiService.distanceKm(0, 0, 0, 5), greaterThan(500));
  });

  test('profile avatar reference can be changed and removed', () async {
    final repository = LocalProfileRepository();
    final profile = UserProfile(
      id: 'avatar-owner',
      name: 'Avatar Owner',
      phone: '',
      email: 'avatar@suikai.local',
      avatar: '/persistent/avatar.jpg',
      createdAt: DateTime(2026, 6),
    );
    await LocalDatabase.users.put(profile.id, profile.toJson());
    await repository.save(profile);
    expect((await repository.get(profile.id))?.avatar, profile.avatar);
    await repository.save(
      UserProfile(
        id: profile.id,
        name: profile.name,
        phone: profile.phone,
        email: profile.email,
        createdAt: profile.createdAt,
      ),
    );
    expect((await repository.get(profile.id))?.avatar, isEmpty);
  });

  test('logout clears only session and preserves Hive data', () async {
    final profile = await SuikaiService.register(
      name: 'Logout Owner',
      phone: '0900000000',
      email: 'logout@suikai.local',
      password: 'password123',
    );
    await SuikaiService.login(profile.email, 'password123');
    final usersBefore = LocalDatabase.users.length;
    final listingsBefore = LocalDatabase.listings.length;
    final storesBefore = LocalDatabase.stores.length;
    expect(
      (await SharedPreferences.getInstance()).getString(
        'local_session_user_id',
      ),
      profile.id,
    );

    await SuikaiService.logout();

    expect(SuikaiService.isLoggedIn, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getString(
        'local_session_user_id',
      ),
      isNull,
    );
    expect(LocalDatabase.users.length, usersBefore);
    expect(LocalDatabase.listings.length, listingsBefore);
    expect(LocalDatabase.stores.length, storesBefore);
    expect(LocalDatabase.users.containsKey(profile.id), isTrue);
  });
}
