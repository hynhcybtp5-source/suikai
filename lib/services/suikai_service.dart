import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../data/local_repositories.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../data/store_categories.dart';
import '../data/supabase_repositories.dart';

class SelectedImage {
  final XFile file;
  final Uint8List bytes;
  const SelectedImage({required this.file, required this.bytes});
  String get extension =>
      file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
}

class SuikaiService {
  static AuthRepository auth = LocalAuthRepository();
  static ProfileRepository profiles = LocalProfileRepository();
  static ListingRepository listings = LocalListingRepository();
  static StoreRepository stores = LocalStoreRepository();
  static StoreRequestRepository storeRequests = LocalStoreRequestRepository();
  static CategoryRepository categoryRepository = LocalCategoryRepository();
  static LikeRepository likes = LocalLikeRepository();
  static ReportRepository reports = LocalReportRepository();
  static NotificationRepository notifications = LocalNotificationRepository();
  static StorageService storage = createLocalStorageService();
  static AdminRepository admin = LocalAdminRepository();
  static final _picker = ImagePicker();
  static List<CategoryRecord> _categoryCache = [...initialCategoryRecords];
  static late String deviceId;
  static bool get usesSupabase => SupabaseBackend.enabled;
  static String? get currentUserId => auth.currentUserId;
  static bool get isLoggedIn => currentUserId != null;

  static Future<bool> initialize() async {
    await LocalDatabase.initialize();
    if (usesSupabase) {
      await SupabaseBackend.initialize();
      final client = SupabaseBackend.client;
      auth = SupabaseAuthRepository(client);
      profiles = SupabaseProfileRepository(client);
      listings = SupabaseListingRepository(client);
      stores = SupabaseStoreRepository(client);
      storeRequests = SupabaseStoreRequestRepository(client);
      categoryRepository = SupabaseCategoryRepository(client);
      likes = SupabaseLikeRepository(client);
      reports = SupabaseReportRepository(client);
      notifications = SupabaseNotificationRepository(client);
      storage = SupabaseStorageService(client);
      admin = SupabaseAdminRepository(client);
      await (auth as SupabaseAuthRepository).restore();
      await (admin as SupabaseAdminRepository).restore();
    } else {
      final localAuth = LocalAuthRepository();
      final localCategories = LocalCategoryRepository();
      final localAdmin = LocalAdminRepository();
      auth = localAuth;
      profiles = LocalProfileRepository();
      listings = LocalListingRepository();
      stores = LocalStoreRepository();
      storeRequests = LocalStoreRequestRepository();
      categoryRepository = localCategories;
      likes = LocalLikeRepository();
      reports = LocalReportRepository();
      notifications = LocalNotificationRepository();
      storage = createLocalStorageService();
      admin = localAdmin;
      await localCategories.seedDefaults();
      await localCategories.migrateLegacyReferences();
      await localAuth.restore();
      await localAdmin.restore();
    }
    await refreshCategories();
    final prefs = await SharedPreferences.getInstance();
    deviceId = prefs.getString('local_device_id') ?? const Uuid().v4();
    await prefs.setString('local_device_id', deviceId);
    return true;
  }

  static Future<void> refreshCategories() async {
    _categoryCache = [
      ...await categoryRepository.getByType('store'),
      ...await categoryRepository.getByType('listing'),
    ];
  }

  static List<CategoryRecord> categoryRecords(
    String type, {
    bool activeOnly = false,
  }) =>
      _categoryCache
          .where(
            (category) =>
                category.type == type && (!activeOnly || category.isActive),
          )
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  static CategoryRecord? categoryForValue(String type, String value) =>
      _categoryCache
          .where((category) => category.type == type && category.matches(value))
          .firstOrNull;

  static String categoryIdForValue(String type, String value) =>
      categoryForValue(type, value)?.id ?? value;

  static String categoryLabel(String type, String value, String localeCode) =>
      categoryForValue(type, value)?.localizedName(localeCode) ?? value;

  static Future<void> addCategory(CategoryRecord value) async {
    await categoryRepository.add(value);
    await refreshCategories();
  }

  static Future<void> updateCategory(CategoryRecord value) async {
    await categoryRepository.update(value);
    await refreshCategories();
  }

  static Future<void> setCategoryActive(String id, bool active) async {
    await categoryRepository.setActive(id, active);
    await refreshCategories();
  }

  static Future<void> reorderCategories(
    String type,
    List<String> orderedIds,
  ) async {
    await categoryRepository.reorder(type, orderedIds);
    await refreshCategories();
  }

  static Future<int> categoryUsageCount(CategoryRecord category) async {
    if (category.type == 'store') {
      return (await stores.all())
          .where((store) => category.matches(store.category))
          .length;
    }
    return (await listings.all())
        .where(
          (listing) =>
              listing.storeId == null && category.matches(listing.category),
        )
        .length;
  }

  static Future<UserProfile> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) =>
      auth.register(name: name, phone: phone, email: email, password: password);
  static Future<UserProfile> login(String email, String password) =>
      auth.login(email, password);
  static Future<void> logout() => auth.logout();
  static Future<UserProfile?> currentProfile() =>
      currentUserId == null ? Future.value(null) : profiles.get(currentUserId!);
  static Future<void> updateProfile(UserProfile profile) =>
      profiles.save(profile);

  static Future<bool> shareProductImage({
    required String imageSource,
    required String title,
    required String price,
  }) async {
    if (imageSource.trim().isEmpty) return false;
    late final XFile image;
    if (imageSource.startsWith('http://') ||
        imageSource.startsWith('https://')) {
      final response = await http
          .get(Uri.parse(imageSource))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final rawExtension = Uri.parse(
        imageSource,
      ).pathSegments.lastOrNull?.split('.').last.toLowerCase();
      final extension =
          const {'jpg', 'jpeg', 'png', 'webp'}.contains(rawExtension)
          ? rawExtension!
          : 'jpg';
      image = XFile.fromData(
        response.bodyBytes,
        mimeType: response.headers['content-type'] ?? 'image/jpeg',
        name: 'suikai-product.$extension',
      );
    } else {
      image = XFile(imageSource);
      try {
        if (await image.length() == 0) return false;
      } catch (_) {
        return false;
      }
    }
    await SharePlus.instance.share(
      ShareParams(files: [image], text: '$title\n$price', title: title),
    );
    return true;
  }

  static Future<SelectedImage?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return null;
    final ext = picked.name.contains('.')
        ? picked.name.split('.').last.toLowerCase()
        : '';
    if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(ext))
      throw const FormatException('รองรับเฉพาะ JPG, PNG และ WebP');
    final bytes = await picked.readAsBytes();
    if (bytes.lengthInBytes > 10 * 1024 * 1024)
      throw const FormatException('รูปต้องมีขนาดไม่เกิน 10MB');
    return SelectedImage(file: picked, bytes: bytes);
  }

  static Future<List<String>> _saveImages(
    List<SelectedImage> values, {
    String? bucket,
    String? objectPrefix,
  }) async {
    final out = <String>[];
    for (final i in values) {
      out.add(
        await storage.persistImage(
          i.file.path,
          i.extension,
          bucket: bucket,
          objectPrefix: objectPrefix,
        ),
      );
    }
    return out;
  }

  static String _requireUser() {
    final id = currentUserId;
    if (id == null) throw StateError('login_required');
    return id;
  }

  static Future<Map<String, dynamic>?> createListing({
    required String title,
    required String description,
    required String category,
    required String city,
    required String phone,
    required String viber,
    required double price,
    required String currency,
    required String listingType,
    String? storeId,
    String status = 'available',
    List<SelectedImage> images = const [],
    double? latitude,
    double? longitude,
    bool isLocationVisible = true,
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final saved = await _saveImages(
      images,
      bucket: 'listing-images',
      objectPrefix: usesSupabase
          ? 'listings/drafts/${_requireUser()}/$id'
          : 'listings/$id',
    );
    final value = ListingRecord(
      id: id,
      ownerId: _requireUser(),
      storeId: storeId,
      title: title,
      description: description,
      category: category,
      price: price,
      currency: currency,
      city: city,
      status: status,
      images: saved,
      phone: phone,
      viber: viber,
      latitude: isLocationVisible ? latitude : null,
      longitude: isLocationVisible ? longitude : null,
      isLocationVisible: isLocationVisible,
      createdAt: now,
      updatedAt: now,
    );
    await listings.create(value);
    return value.toJson();
  }

  static Future<void> updateListing({
    required String listingId,
    required String title,
    required String description,
    required String city,
    required String phone,
    required String viber,
    required double price,
    required String currency,
    required String status,
    String? category,
    List<String>? images,
    List<SelectedImage> newImages = const [],
    double? latitude,
    double? longitude,
    bool? isLocationVisible,
  }) async {
    final all = await listings.all();
    final old = all.where((e) => e.id == listingId).firstOrNull;
    if (old == null) throw StateError('not_found');
    final extra = await _saveImages(
      newImages,
      bucket: 'listing-images',
      objectPrefix: 'listings/$listingId',
    );
    await listings.update(
      ListingRecord(
        id: old.id,
        ownerId: _requireUser(),
        storeId: old.storeId,
        title: title,
        description: description,
        category: category ?? old.category,
        price: price,
        currency: currency,
        city: city,
        status: status,
        images: images == null
            ? [...old.images, ...extra]
            : [...images, ...extra],
        phone: phone,
        viber: viber,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
        likes: old.likes,
        views: old.views,
        latitude: (isLocationVisible ?? old.isLocationVisible)
            ? (latitude ?? old.latitude)
            : null,
        longitude: (isLocationVisible ?? old.isLocationVisible)
            ? (longitude ?? old.longitude)
            : null,
        isLocationVisible: isLocationVisible ?? old.isLocationVisible,
      ),
    );
  }

  static Future<List<String>> persistSelectedImages(
    List<SelectedImage> images, {
    String? listingId,
  }) => _saveImages(
    images,
    bucket: listingId == null ? null : 'listing-images',
    objectPrefix: listingId == null ? null : 'listings/$listingId',
  );

  static Future<void> deleteListing(String id) =>
      listings.delete(id, _requireUser());

  static Future<Map<String, dynamic>?> createStore({
    required String name,
    required String description,
    required String category,
    required String city,
    required String phone,
    required String viber,
    required String hours,
    required SelectedImage logo,
    SelectedImage? cover,
    String? email,
    double? latitude,
    double? longitude,
  }) async {
    final id = const Uuid().v4();
    final ownerId = _requireUser();
    final logoPath = await storage.persistImage(
      logo.file.path,
      logo.extension,
      bucket: 'store-images',
      objectPrefix: usesSupabase ? 'stores/drafts/$ownerId/$id' : 'stores/$id',
    );
    final coverPath = cover == null
        ? ''
        : await storage.persistImage(
            cover.file.path,
            cover.extension,
            bucket: 'store-images',
            objectPrefix: usesSupabase
                ? 'stores/drafts/$ownerId/$id'
                : 'stores/$id',
          );
    final value = StoreRecord(
      id: id,
      ownerId: ownerId,
      name: name,
      logo: logoPath,
      cover: coverPath,
      description: description,
      category: category,
      phone: phone,
      viber: viber,
      city: city,
      location: '$city${latitude == null ? '' : ',$latitude,$longitude'}',
      openingHours: hours,
      status: usesSupabase ? 'pending' : 'approved',
      email: email ?? '',
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    );
    await stores.create(value);
    return value.toJson();
  }

  static Future<void> updateStore({
    required String storeId,
    required Map<String, dynamic> values,
    SelectedImage? logo,
    SelectedImage? cover,
  }) async {
    final all = await stores.all();
    final old = all.where((e) => e.id == storeId).firstOrNull;
    if (old == null) throw StateError('not_found');
    final logoPath = logo == null
        ? old.logo
        : await storage.persistImage(
            logo.file.path,
            logo.extension,
            bucket: 'store-images',
            objectPrefix: 'stores/$storeId',
          );
    await stores.update(
      StoreRecord(
        id: old.id,
        ownerId: _requireUser(),
        name: '${values['name'] ?? old.name}',
        logo: logoPath,
        cover: old.cover,
        description: '${values['description'] ?? old.description}',
        category: '${values['category'] ?? old.category}',
        phone: '${values['phone'] ?? old.phone}',
        viber: '${values['viber_phone'] ?? old.viber}',
        city: '${values['city'] ?? old.city}',
        location: '${values['location'] ?? old.location}',
        openingHours:
            values['opening_hours']?.toString() ??
            (values.containsKey('opening_time')
                ? '${values['opening_time']}-${values['closing_time']}'
                : old.openingHours),
        status: old.status,
        email: old.email,
        latitude: old.latitude,
        longitude: old.longitude,
        createdAt: old.createdAt,
        isPromoted: old.isPromoted,
        promotionStartAt: old.promotionStartAt,
        promotionEndAt: old.promotionEndAt,
      ),
    );
  }

  static Future<void> submitStoreEditRequest({
    required String storeId,
    required Map<String, dynamic> values,
    SelectedImage? logo,
    SelectedImage? cover,
  }) async {
    final ownerId = _requireUser();
    final proposed = Map<String, dynamic>.from(values);
    if (logo != null) {
      proposed['logo_url'] = await storage.persistImage(
        logo.file.path,
        logo.extension,
        bucket: 'store-images',
        objectPrefix: 'stores/$storeId/requests',
      );
    }
    if (cover != null) {
      proposed['cover_url'] = await storage.persistImage(
        cover.file.path,
        cover.extension,
        bucket: 'store-images',
        objectPrefix: 'stores/$storeId/requests',
      );
    }
    await storeRequests.submitEdit(
      StoreEditRequestRecord(
        id: const Uuid().v4(),
        storeId: storeId,
        ownerId: ownerId,
        proposedChanges: proposed,
        createdAt: DateTime.now(),
      ),
    );
  }

  static Future<void> submitPromotionRequest(String storeId) =>
      storeRequests.submitPromotion(
        PromotionRequestRecord(
          id: const Uuid().v4(),
          storeId: storeId,
          ownerId: _requireUser(),
          createdAt: DateTime.now(),
        ),
      );

  static Future<void> deleteStore(String id) =>
      stores.delete(id, _requireUser());
  static Future<List<Map<String, dynamic>>> fetchStores() async =>
      (await stores.all())
          .where((e) => e.status == 'approved')
          .map((e) => e.toJson())
          .toList();
  static Future<List<Map<String, dynamic>>> fetchMyStores() async =>
      (await stores.all())
          .where((e) => e.ownerId == currentUserId)
          .map((e) => e.toJson())
          .toList();
  static Future<List<Map<String, dynamic>>> fetchListings() async =>
      (await listings.all())
          .where((e) => e.status != 'deleted' && e.status != 'hidden')
          .map(_listingMap)
          .toList();
  static Future<List<Map<String, dynamic>>> fetchListingsForStore(
    String storeId,
  ) async => (await listings.all())
      .where(
        (e) =>
            e.storeId == storeId &&
            e.status != 'sold' &&
            e.status != 'deleted' &&
            e.status != 'hidden',
      )
      .map(_listingMap)
      .toList();
  static Map<String, dynamic> _listingMap(ListingRecord e) => {
    ...e.toJson(),
    'listing_images': [
      for (final p in e.images) {'image_url': p},
    ],
    'listing_stats': {'like_count': e.likes, 'view_count': e.views},
  };
  static Future<void> likeListing(String id) async {
    if (!await likes.like(id, deviceId)) return;
    if (usesSupabase) return;
    await _bump(id, like: true);
  }

  static Future<void> trackView(String id) async {
    if (!await likes.view(id, deviceId)) return;
    if (usesSupabase) return;
    await _bump(id, like: false);
  }

  static Future<Set<String>> fetchLikedIds() => likes.likedIds(deviceId);
  static Future<void> _bump(String id, {required bool like}) async {
    final old = (await listings.all()).where((e) => e.id == id).firstOrNull;
    if (old == null) return;
    await LocalDatabase.listings.put(id, {
      ...old.toJson(),
      'likes': old.likes + (like ? 1 : 0),
      'views': old.views + (like ? 0 : 1),
    });
  }

  static Future<void> submitReport({
    required String reason,
    required String details,
    String? listingId,
    String? storeId,
  }) => reports.create(
    ReportRecord(
      id: const Uuid().v4(),
      reason: details.trim().isEmpty ? reason : '$reason: ${details.trim()}',
      targetId: listingId ?? storeId ?? '',
      type: listingId == null ? 'store' : 'listing',
      createdAt: DateTime.now(),
    ),
  );
  static Future<List<NotificationRecord>> fetchNotifications() =>
      isLoggedIn ? notifications.all() : Future.value(const []);
  static Future<int> unreadNotificationCount() =>
      isLoggedIn ? notifications.unreadCount() : Future.value(0);
  static Future<void> markNotificationRead(String id) =>
      isLoggedIn ? notifications.markRead(id) : Future.value();
  static Future<Position?> getCurrentPosition({bool request = true}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var p = await Geolocator.checkPermission();
    if (request && p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever)
      return null;
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  static double distanceKm(
    double latitude,
    double longitude,
    double otherLatitude,
    double otherLongitude,
  ) =>
      Geolocator.distanceBetween(
        latitude,
        longitude,
        otherLatitude,
        otherLongitude,
      ) /
      1000;

  static bool isWithin500Km(
    Position position,
    double? latitude,
    double? longitude,
  ) =>
      latitude != null &&
      longitude != null &&
      distanceKm(position.latitude, position.longitude, latitude, longitude) <=
          500;

  static Future<bool> shouldOfferLocationOnLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('location_intro_seen') ?? false);
  }

  static Future<void> markLocationIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_intro_seen', true);
  }
}
