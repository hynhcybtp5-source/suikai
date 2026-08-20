import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suikai/data/models.dart';
import 'package:suikai/features/admin/admin_dashboard.dart';
import 'package:suikai/services/suikai_service.dart';
import 'package:suikai/services/video_post_processor.dart';

import 'support/in_memory_repositories.dart';

SelectedVideoPost _selectedVideo() => SelectedVideoPost(
  PreparedVideoPost(
    path: '/tmp/suikai-test-video.mp4',
    thumbnailBytes: Uint8List.fromList([0xFF, 0xD8, 0xFF]),
    durationMilliseconds: 1000,
    sizeBytes: 1024,
  ),
);

ListingVideoRecord _listingVideo() => const ListingVideoRecord(
  id: 'test-video',
  videoMediaId: 'test-video-media',
  thumbnailMediaId: 'test-thumbnail-media',
  videoPath: 'listings/test/video.mp4',
  thumbnailPath: 'listings/test/thumbnail.jpg',
  durationMilliseconds: 1000,
  sizeBytes: 1024,
);

void main() {
  late Directory databaseDirectory;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    databaseDirectory = await Directory.systemTemp.createTemp(
      'suikai_moderation_test_',
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
    SuikaiService.auth = InMemoryAuthRepository();
    SuikaiService.profiles = InMemoryProfileRepository();
    SuikaiService.listings = InMemoryListingRepository();
    SuikaiService.stores = InMemoryStoreRepository();
    SuikaiService.storeRequests = InMemoryStoreRequestRepository();
    SuikaiService.categoryRepository = InMemoryCategoryRepository();
    SuikaiService.likes = InMemoryLikeRepository();
    SuikaiService.reports = InMemoryReportRepository();
    SuikaiService.notifications = InMemoryNotificationRepository();
    SuikaiService.shortVideos = InMemoryShortVideoRepository();
    SuikaiService.advertisements = InMemoryAdvertisementRepository();
    SuikaiService.storage = InMemoryStorageService();
    SuikaiService.admin = InMemoryAdminRepository();
  });

  tearDownAll(() async {
    await Hive.close();
    await databaseDirectory.delete(recursive: true);
  });

  test('listing creation rejects a missing video', () async {
    final profile = await SuikaiService.register(
      name: 'Video required',
      phone: '0910000000',
      email: 'video-required@suikai.local',
      password: 'password123',
      city: '',
    );
    await SuikaiService.login(profile.email, 'password123');
    await expectLater(
      SuikaiService.createListing(
        title: 'No video',
        description: '',
        category: 'listing_mobile',
        phone: profile.phone,
        viber: '',
        price: 1,
        currency: 'MMK',
        listingType: 'general',
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'listing_video_required',
        ),
      ),
    );
  });

  test('store changes and promotion require admin approval', () async {
    final storeRepository = InMemoryStoreRepository();
    final requests = InMemoryStoreRequestRepository();
    final admin = InMemoryAdminRepository();
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
    final application = await storeRepository.create(store);
    expect(application.status, 'pending');
    expect((await storeRepository.all()).single.status, 'pending');
    expect(await admin.login('admin@suikai.local', 'admin1234'), isTrue);
    final alerts = await admin.adminNotifications();
    expect(alerts.single['type'], 'shop_application');
    expect(alerts.single['shop_id'], store.id);
    expect(alerts.single['is_read'], isFalse);
    await admin.markAdminNotificationRead('${alerts.single['id']}');
    expect((await admin.adminNotifications()).single['is_read'], isTrue);
    await admin.setStoreStatus(store.id, 'approved');
    expect((await storeRepository.all()).single.status, 'approved');
    await storeRepository.update(
      StoreRecord.fromJson({...store.toJson(), 'status': 'rejected'}),
    );
    expect((await storeRepository.all()).single.status, 'approved');
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
      final repository = InMemoryCategoryRepository();
      await repository.seedDefaults();
      await repository.migrateLegacyReferences();

      expect(
        (await InMemoryStoreRepository().all()).single.category,
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

      await TestDatabase.categories.close();
      TestDatabase.categories = await Hive.openBox('categories');
      expect(
        (await repository.getByType(
          'listing',
        )).singleWhere((value) => value.id == added.id).isActive,
        isFalse,
      );
    },
  );

  test('store product edit preserves id and video metadata', () async {
    final profile = await SuikaiService.register(
      name: 'Owner',
      phone: '0912345678',
      email: 'owner@suikai.local',
      password: 'password123',
      city: 'Test City',
    );
    await SuikaiService.login(profile.email, 'password123');
    final createdAt = DateTime(2026, 4);
    await TestDatabase.stores.put('store-1', {
      'id': 'store-1',
      'owner_id': profile.id,
      'name': 'Approved test store',
      'status': 'approved',
      'category': 'store_mobile',
      'created_at': createdAt.toIso8601String(),
    });
    await InMemoryListingRepository().create(
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
        video: _listingVideo(),
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
    var saved = (await InMemoryListingRepository().all()).singleWhere(
      (value) => value.id == 'store-product-edit',
    );
    expect(saved.id, 'store-product-edit');
    expect(saved.status, 'reserved');
    expect(saved.video?.videoPath, 'listings/test/video.mp4');
    expect(
      (await InMemoryListingRepository().publicListings()).where(
        (value) => value.id == saved.id,
      ),
      isNotEmpty,
    );
    expect(saved.createdAt, createdAt);

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
    );
    await TestDatabase.listings.close();
    TestDatabase.listings = await Hive.openBox('listings');
    saved = (await InMemoryListingRepository().all()).singleWhere(
      (value) => value.id == 'store-product-edit',
    );
    expect(
      (await InMemoryListingRepository().all())
          .where((value) => value.id == 'store-product-edit')
          .length,
      1,
    );
  });

  test(
    'general listing saves trimmed free-text city without GPS or city id',
    () async {
      final profile = await SuikaiService.register(
        name: 'General seller',
        phone: '0911111111',
        email: 'general-city@suikai.local',
        password: 'password123',
        city: 'Profile City',
      );
      await SuikaiService.login(profile.email, 'password123');

      final result = await SuikaiService.createListing(
        title: 'City regression product',
        description: 'No GPS is required',
        category: 'listing_mobile',
        city: '  User Entered City  ',
        cityId: null,
        phone: '0911111111',
        viber: '',
        price: 125,
        currency: 'THB',
        listingType: 'general',
        video: _selectedVideo(),
        latitude: 19.123456,
        longitude: 97.654321,
        isLocationVisible: false,
      );

      expect(result?['city'], 'User Entered City');
      expect(result?['city_id'], isNull);
      expect(result?['latitude'], 19.123456);
      expect(result?['longitude'], 97.654321);
      expect(result?['is_location_visible'], isFalse);
    },
  );

  test('store listing always uses the store contact details', () async {
    final profile = await SuikaiService.register(
      name: 'Store contact owner',
      phone: '0912345678',
      email: 'store-contact-owner@suikai.local',
      password: 'password123',
      city: 'เมืองนาง',
    );
    await SuikaiService.login(profile.email, 'password123');
    const storeId = 'store-contact-source';
    await TestDatabase.stores.put(
      storeId,
      StoreRecord(
        id: storeId,
        ownerId: profile.id,
        name: 'Store contact source',
        logo: '',
        description: '',
        category: 'store_mobile',
        phone: '099 111 2222',
        viber: '099 333 4444',
        city: 'เมืองนาง',
        location: 'เมืองนาง',
        openingHours: '09:00-18:00',
        status: 'approved',
        createdAt: DateTime(2026, 8, 16),
      ).toJson(),
    );

    final saved = await SuikaiService.createListing(
      title: 'Store contact product',
      description: '',
      category: 'listing_mobile',
      city: 'เมืองอื่น',
      phone: '088 000 0000',
      viber: '088 999 9999',
      price: 10,
      currency: 'THB',
      listingType: 'store',
      storeId: storeId,
      video: _selectedVideo(),
    );

    expect(saved?['phone'], '0991112222');
    expect(saved?['viber_phone'], '0993334444');
  });

  test('admin location text shows coordinates and missing-data fallback', () {
    expect(
      adminLocationText(13.1234567, 99.6543212),
      'Latitude: 13.123457\nLongitude: 99.654321',
    );
    expect(adminLocationText(null, null), 'ไม่มีข้อมูลตำแหน่ง');
  });

  test(
    'general listing accepts an empty city when GPS/profile city is unavailable',
    () async {
      final saved = await SuikaiService.createListing(
        title: 'Invalid city product',
        description: '',
        category: 'listing_mobile',
        city: '   ',
        phone: '0911111111',
        viber: '',
        price: 10,
        currency: 'THB',
        listingType: 'general',
        video: _selectedVideo(),
        isLocationVisible: false,
      );
      expect(saved?['city'], isEmpty);
      final id = '${saved?['id']}';
      await SuikaiService.updateListingStatus(
        listingId: id,
        status: 'reserved',
      );
      expect(
        (await InMemoryListingRepository().all())
            .singleWhere((listing) => listing.id == id)
            .status,
        'reserved',
      );
      expect(
        (await InMemoryListingRepository().publicListings()).map(
          (listing) => listing.id,
        ),
        contains(id),
      );
      await SuikaiService.updateListingStatus(listingId: id, status: 'sold');
      expect(
        (await InMemoryListingRepository().all())
            .singleWhere((listing) => listing.id == id)
            .status,
        'sold',
      );
      expect(
        (await InMemoryListingRepository().publicListings()).map(
          (listing) => listing.id,
        ),
        isNot(contains(id)),
      );
    },
  );

  test(
    'status-only updates preserve video metadata and public visibility',
    () async {
      final profile = await SuikaiService.register(
        name: 'Status owner',
        phone: '',
        email: 'status-owner@suikai.test',
        password: 'password123',
        city: '',
      );
      await SuikaiService.login(profile.email, 'password123');
      const video = ListingVideoRecord(
        id: 'video-status-only',
        videoMediaId: 'video-media-status-only',
        thumbnailMediaId: 'thumbnail-media-status-only',
        videoPath: 'videos/status-only.mp4',
        thumbnailPath: 'thumbnails/status-only.jpg',
        durationMilliseconds: 1000,
        sizeBytes: 100,
      );
      await InMemoryListingRepository().create(
        ListingRecord(
          id: 'general-status-only',
          ownerId: profile.id,
          title: 'General',
          description: '',
          category: 'listing_mobile',
          price: 1,
          currency: 'THB',
          city: '',
          status: 'available',
          video: video,
          phone: '',
          viber: '',
          createdAt: DateTime(2026, 8, 16),
          updatedAt: DateTime(2026, 8, 16),
        ),
      );
      await SuikaiService.updateListingStatus(
        listingId: 'general-status-only',
        status: 'reserved',
      );
      var saved = (await InMemoryListingRepository().all()).singleWhere(
        (listing) => listing.id == 'general-status-only',
      );
      expect(saved.status, 'reserved');
      expect(saved.video?.videoPath, video.videoPath);
      await SuikaiService.updateListingStatus(
        listingId: 'general-status-only',
        status: 'sold',
      );
      expect(
        (await InMemoryListingRepository().publicListings()).map(
          (listing) => listing.id,
        ),
        isNot(contains('general-status-only')),
      );

      await InMemoryListingRepository().create(
        ListingRecord(
          id: 'store-status-only',
          ownerId: profile.id,
          storeId: 'store-status-only',
          title: 'Store',
          description: '',
          category: 'listing_mobile',
          price: 1,
          currency: 'THB',
          city: 'เมืองนาง',
          status: 'available',
          video: _listingVideo(),
          phone: '',
          viber: '',
          createdAt: DateTime(2026, 8, 16),
          updatedAt: DateTime(2026, 8, 16),
        ),
      );
      await SuikaiService.updateListingStatus(
        listingId: 'store-status-only',
        status: 'reserved',
      );
      saved = (await InMemoryListingRepository().all()).singleWhere(
        (listing) => listing.id == 'store-status-only',
      );
      expect(saved.status, 'reserved');
      await SuikaiService.updateListingStatus(
        listingId: 'store-status-only',
        status: 'sold',
      );
      expect(
        (await InMemoryListingRepository().publicListings()).map(
          (listing) => listing.id,
        ),
        isNot(contains('store-status-only')),
      );
    },
  );

  test(
    'map listings include only visible published active coordinates',
    () async {
      final ownerId = SuikaiService.currentUserId!;
      final now = DateTime(2026, 8, 12);
      Future<void> add(
        String id, {
        String status = 'available',
        bool visible = true,
        bool published = true,
        bool hidden = false,
      }) => InMemoryListingRepository().create(
        ListingRecord(
          id: id,
          ownerId: ownerId,
          title: id,
          description: '',
          category: 'listing_mobile',
          price: 1,
          currency: 'THB',
          city: 'Map Test City',
          status: status,
          video: _listingVideo(),
          phone: '',
          viber: '',
          latitude: 20,
          longitude: 97,
          isLocationVisible: visible,
          isPublished: published,
          isHidden: hidden,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await add('map-visible');
      await add('map-private', visible: false);
      await add('map-sold', status: 'sold');
      await add('map-hidden', hidden: true);
      await add('map-unpublished', published: false);

      final ids = (await SuikaiService.fetchMapListings())
          .map((row) => '${row['id']}')
          .toSet();
      expect(ids, contains('map-visible'));
      expect(ids, isNot(contains('map-private')));
      expect(ids, isNot(contains('map-sold')));
      expect(ids, isNot(contains('map-hidden')));
      expect(ids, isNot(contains('map-unpublished')));
    },
  );

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
      video: _listingVideo(),
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
    final repository = InMemoryProfileRepository();
    final profile = UserProfile(
      id: 'avatar-owner',
      name: 'Avatar Owner',
      phone: '',
      email: 'avatar@suikai.local',
      avatar: '/persistent/avatar.jpg',
      city: 'เมืองนาง',
      cityId: 'city-1',
      viber: '0912345678',
      createdAt: DateTime(2026, 6),
    );
    await TestDatabase.users.put(profile.id, profile.toJson());
    final saved = await repository.save(profile);
    expect((await repository.get(profile.id))?.avatar, profile.avatar);
    expect(saved.cityId, 'city-1');
    expect(saved.viber, '0912345678');
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
      city: 'Test City',
    );
    await SuikaiService.login(profile.email, 'password123');
    final usersBefore = TestDatabase.users.length;
    final listingsBefore = TestDatabase.listings.length;
    final storesBefore = TestDatabase.stores.length;
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
    expect(TestDatabase.users.length, usersBefore);
    expect(TestDatabase.listings.length, listingsBefore);
    expect(TestDatabase.stores.length, storesBefore);
    expect(TestDatabase.users.containsKey(profile.id), isTrue);
  });
}
