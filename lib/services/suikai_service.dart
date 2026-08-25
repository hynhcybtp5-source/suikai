import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../data/supabase_repositories.dart';
import '../core/legal_versions.dart';
import 'video_post_processor.dart';
import 'video_watermark_processor.dart';

class SelectedImage {
  final XFile file;
  final Uint8List bytes;
  const SelectedImage({required this.file, required this.bytes});
  String get extension =>
      file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpg';
}

class SelectedVideoPost {
  final PreparedVideoPost prepared;
  const SelectedVideoPost(this.prepared);
}

enum LocationFailureReason {
  insecureContext,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationFailure implements Exception {
  final LocationFailureReason reason;
  final Object? cause;
  const LocationFailure(this.reason, [this.cause]);

  String get userMessage => switch (reason) {
    LocationFailureReason.insecureContext =>
      'ตำแหน่งบน Web ใช้ได้เฉพาะ HTTPS หรือ localhost',
    LocationFailureReason.serviceDisabled =>
      'กรุณาเปิด Location Service/GPS แล้วลองใหม่',
    LocationFailureReason.permissionDenied =>
      'ไม่ได้รับสิทธิ์ตำแหน่ง กรุณาอนุญาตในหน้าต่างของระบบ',
    LocationFailureReason.permissionDeniedForever =>
      'สิทธิ์ตำแหน่งถูกปิดถาวร กรุณาเปิดจาก Settings ของแอปหรือ Browser',
    LocationFailureReason.unavailable =>
      'ไม่สามารถอ่านตำแหน่งปัจจุบันได้ กรุณาลองใหม่',
  };

  @override
  String toString() => 'LocationFailure($reason, cause: $cause)';
}

class UgcLegalAcceptanceRequired implements Exception {
  const UgcLegalAcceptanceRequired();

  @override
  String toString() => 'ugc_legal_acceptance_required';
}

class SuikaiService {
  static late AuthRepository auth;
  static late ProfileRepository profiles;
  static late LegalConsentRepository legalConsents;
  static late ListingRepository listings;
  static late StoreRepository stores;
  static late StoreRequestRepository storeRequests;
  static late CategoryRepository categoryRepository;
  static late LikeRepository likes;
  static late ReportRepository reports;
  static late NotificationRepository notifications;
  static late ShortVideoRepository shortVideos;
  static late AdvertisementRepository advertisements;
  static late StorageService storage;
  static late AdminRepository admin;
  static final _picker = ImagePicker();
  static List<CategoryRecord> _categoryCache = [];
  static List<CityRecord> _cityCache = [];
  static late String deviceId;
  static final Map<String, _SignedUrlCacheEntry> _thumbnailUrlCache = {};
  static final Map<String, Future<File>> _videoDownloadCache = {};
  static final Map<String, Future<File>> _watermarkedVideoShareCache = {};
  static bool get usesSupabase => SupabaseBackend.enabled;
  static Session? get currentSession =>
      usesSupabase ? SupabaseBackend.client.auth.currentSession : null;
  static bool get hasValidSession => currentSession != null;
  static String? get currentUserId => auth.currentUserId;
  static bool get isLoggedIn => currentUserId != null;

  static Future<bool> initialize() async {
    if (!usesSupabase) {
      throw StateError(
        'Supabase configuration is required. Provide SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY.',
      );
    }
    try {
      await SupabaseBackend.initialize();
    } catch (error, stackTrace) {
      debugPrint('SuikaiService Supabase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
    try {
      final client = SupabaseBackend.client;
      auth = SupabaseAuthRepository(client);
      profiles = SupabaseProfileRepository(client);
      legalConsents = SupabaseLegalConsentRepository(client);
      listings = SupabaseListingRepository(client);
      stores = SupabaseStoreRepository(client);
      storeRequests = SupabaseStoreRequestRepository(client);
      categoryRepository = SupabaseCategoryRepository(client);
      likes = SupabaseLikeRepository(client);
      reports = SupabaseReportRepository(client);
      notifications = SupabaseNotificationRepository(client);
      shortVideos = SupabaseShortVideoRepository(client);
      advertisements = SupabaseAdvertisementRepository(client);
      storage = SupabaseStorageService(client);
      admin = SupabaseAdminRepository(client);
      await auth.restore();
      await admin.restore();
      final prefs = await SharedPreferences.getInstance();
      deviceId = prefs.getString('local_device_id') ?? const Uuid().v4();
      await prefs.setString('local_device_id', deviceId);
    } catch (error, stackTrace) {
      debugPrint(
        'SuikaiService initialization failed after Supabase setup: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
    return true;
  }

  static Future<void> warmUpAfterFirstFrame() async {
    if (auth.currentUserId != null) {
      try {
        await auth.syncCurrentProfile();
      } catch (error, stackTrace) {
        debugPrint('Startup warmup syncCurrentProfile failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      try {
        await (admin as SupabaseAdminRepository).restore();
      } catch (error, stackTrace) {
        debugPrint('Startup warmup admin restore failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    try {
      await refreshCategories();
    } catch (error, stackTrace) {
      debugPrint('Startup warmup refreshCategories failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    try {
      await refreshCities();
    } catch (error, stackTrace) {
      debugPrint('Startup warmup refreshCities failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> refreshCategories() async {
    _categoryCache = [
      ...await categoryRepository.getByType('store'),
      ...await categoryRepository.getByType('listing'),
    ];
  }

  @visibleForTesting
  static void setCategoriesForTesting(List<CategoryRecord> categories) {
    _categoryCache = List.of(categories);
  }

  static Future<void> refreshCities() async {
    final rows = await SupabaseBackend.client
        .from('cities')
        .select('id,name,name_th,name_shn,name_en,name_my,is_active')
        .eq('is_active', true)
        .order('name');
    _cityCache = rows
        .map((row) => CityRecord.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  static List<CityRecord> get activeCities => List.unmodifiable(_cityCache);

  @visibleForTesting
  static void setCitiesForTesting(List<CityRecord> cities) {
    _cityCache = List.of(cities);
  }

  static Future<List<AdvertisementRecord>> fetchActiveAdvertisements() =>
      advertisements.active();
  static Future<List<AdvertisementRecord>> fetchAllAdvertisements() =>
      advertisements.all();
  static Future<void> saveAdvertisement(
    AdvertisementRecord value, {
    required bool create,
  }) => create ? advertisements.create(value) : advertisements.update(value);
  static Future<void> deleteAdvertisement(String id) =>
      advertisements.delete(id);
  static Future<String> uploadAdvertisementImage(SelectedImage image) =>
      storage.persistImage(
        image.file.path,
        image.extension,
        bucket: 'banner-images',
        objectPrefix: 'banners/${currentUserId ?? 'admin'}',
      );

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
    required String city,
    required bool acceptedUgcTerms,
  }) => auth.register(
    name: name,
    phone: phone,
    email: email,
    password: password,
    city: city.trim(),
    acceptedUgcTerms: acceptedUgcTerms,
  );

  static Future<bool> hasAcceptedCurrentUgcLegalTerms() {
    if (currentUserId == null) return Future.value(false);
    return legalConsents.hasAccepted(
      termsVersion: LegalVersions.termsOfService,
      communityGuidelinesVersion: LegalVersions.communityGuidelines,
    );
  }

  static Future<void> acceptCurrentUgcLegalTerms() => legalConsents.accept(
    termsVersion: LegalVersions.termsOfService,
    communityGuidelinesVersion: LegalVersions.communityGuidelines,
  );

  static Future<void> requireCurrentUgcLegalTerms() async {
    _requireUser();
    if (!await hasAcceptedCurrentUgcLegalTerms()) {
      throw const UgcLegalAcceptanceRequired();
    }
  }

  static Future<UserProfile> login(String email, String password) =>
      auth.login(email, password);
  static Future<void> loginWithTelegram() => auth.loginWithTelegram();
  static Future<void> logout() => auth.logout();
  static Future<void> deleteOwnAccount() => auth.deleteOwnAccount();
  static Future<UserProfile?> currentProfile() =>
      currentUserId == null ? Future.value(null) : profiles.get(currentUserId!);
  static Future<bool> blockSeller(String sellerId) =>
      profiles.blockSeller(sellerId);
  static Future<List<UserProfile>> getBlockedUsers() =>
      profiles.getBlockedUsers();
  static Future<void> unblockUser(String sellerId) =>
      profiles.unblockUser(sellerId);

  static String _normalizePhone(String? value) =>
      (value ?? '').trim().replaceAll(RegExp(r'[^0-9+]'), '');

  static List<String> incompleteGeneralPostingProfileFields(
    UserProfile? profile,
  ) {
    if (profile == null) return const ['name', 'phone', 'city'];
    return [
      if (profile.name.trim().isEmpty) 'name',
      if (_normalizePhone(profile.phone).isEmpty) 'phone',
      if (profile.city.trim().isEmpty) 'city',
    ];
  }

  static Future<UserProfile> requireCompleteGeneralPostingProfile() async {
    final profile = await currentProfile();
    final missing = incompleteGeneralPostingProfileFields(profile);
    if (profile == null || missing.isNotEmpty) {
      throw StateError(
        'general_posting_profile_incomplete:${missing.join(',')}',
      );
    }
    return profile;
  }

  static Future<CityRecord?> resolveCityForCoordinates(
    double latitude,
    double longitude,
  ) async {
    final row = await SupabaseBackend.client.rpc(
      'resolve_city_for_coordinates',
      params: {'p_latitude': latitude, 'p_longitude': longitude},
    );
    return row is Map
        ? CityRecord.fromJson(Map<String, dynamic>.from(row))
        : null;
  }

  static Future<String> signedThumbnailUrl(ListingVideoRecord video) async {
    final key = video.thumbnailMediaId;
    final cached = _thumbnailUrlCache[key];
    final now = DateTime.now();
    if (cached != null && cached.expiresAt.difference(now).inSeconds > 60) {
      return cached.url;
    }
    final url = await storage.createSignedUrl(
      bucket: 'listing-thumbnails',
      objectPath: video.thumbnailPath,
      expiresInSeconds: 10 * 60,
    );
    _thumbnailUrlCache[key] = _SignedUrlCacheEntry(
      url,
      now.add(const Duration(minutes: 10)),
    );
    return url;
  }

  static Future<String> signedVideoUrl(ListingVideoRecord video) =>
      storage.createSignedUrl(
        bucket: 'listing-videos',
        objectPath: video.videoPath,
        expiresInSeconds: 5 * 60,
      );
  static Future<UserProfile> updateProfile(UserProfile profile) =>
      requireCurrentUgcLegalTerms().then((_) => profiles.save(profile));

  static Future<List<ShortVideoRecord>> fetchActiveShortVideos() =>
      shortVideos.active();

  static Future<List<ShortVideoRecord>> fetchAllShortVideos() {
    if (!admin.isAuthenticated) throw StateError('admin_required');
    return shortVideos.all();
  }

  static Future<void> saveShortVideo(
    ShortVideoRecord value, {
    required bool create,
  }) {
    if (!admin.isAuthenticated) throw StateError('admin_required');
    if (!ShortVideoRecord.isValidYouTubeUrl(value.youtubeUrl)) {
      throw const FormatException('invalid_youtube_url');
    }
    return create ? shortVideos.create(value) : shortVideos.update(value);
  }

  static Future<void> deleteShortVideo(String id) {
    if (!admin.isAuthenticated) throw StateError('admin_required');
    return shortVideos.delete(id);
  }

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

  static Future<bool> shareProductVideo({
    required ListingVideoRecord video,
    required String title,
  }) async {
    if (kIsWeb) return false;
    try {
      final file = await _watermarkedVideoShareCache.putIfAbsent(
        video.videoMediaId,
        () => _watermarkVideoForShare(video),
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              file.path,
              mimeType: 'video/mp4',
              name: 'suikai-${video.videoMediaId}.mp4',
            ),
          ],
          text: title,
          title: title,
        ),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Video share watermark failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _watermarkedVideoShareCache.remove(video.videoMediaId);
      return false;
    }
  }

  static Future<File> _watermarkVideoForShare(ListingVideoRecord video) async {
    final output = File(
      '${Directory.systemTemp.path}/suikai-video-watermarked-v2-${video.videoMediaId}.mp4',
    );
    if (await output.exists() && await output.length() > 0) return output;
    if (await output.exists()) await output.delete();

    final source = await _videoDownloadCache.putIfAbsent(
      video.videoMediaId,
      () => _downloadVideoForShare(video),
    );
    final logo = await _shareWatermarkLogoFile();
    await VideoWatermarkProcessor.apply(
      sourcePath: source.path,
      logoPath: logo.path,
      outputPath: output.path,
    );
    if (!await output.exists() || await output.length() == 0) {
      if (await output.exists()) await output.delete();
      throw StateError('video_watermark_failed');
    }
    return output;
  }

  static Future<File> _shareWatermarkLogoFile() async {
    final logo = File(
      '${Directory.systemTemp.path}/suikai-share-watermark-logo.png',
    );
    if (await logo.exists() && await logo.length() > 0) return logo;
    final data = await rootBundle.load(
      'assets/images/suikai_watermark_logo.png',
    );
    await logo.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    if (await logo.length() == 0) {
      throw const FileSystemException('watermark_logo_copy_failed');
    }
    return logo;
  }

  static Future<File> _downloadVideoForShare(ListingVideoRecord video) async {
    final file = File(
      '${Directory.systemTemp.path}/suikai-video-${video.videoMediaId}.mp4',
    );
    if (await file.exists() && await file.length() > 0) return file;

    final url = await signedVideoUrl(video);
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(minutes: 2));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('video_download_failed:${response.statusCode}');
    }
    await file.writeAsBytes(response.bodyBytes, flush: true);
    if (await file.length() == 0) throw const FileSystemException();
    return file;
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

  static Future<List<SelectedImage>> pickImages({required int maxCount}) async {
    if (maxCount < 1) return const [];
    final picked = await _picker.pickMultiImage(
      imageQuality: 80,
      limit: maxCount,
    );
    final selected = <SelectedImage>[];
    for (final file in picked.take(maxCount)) {
      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : '';
      if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(ext)) {
        throw const FormatException('รองรับเฉพาะ JPG, PNG และ WebP');
      }
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        throw const FormatException('รูปต้องมีขนาดไม่เกิน 10MB');
      }
      selected.add(SelectedImage(file: file, bytes: bytes));
    }
    return selected;
  }

  static Future<SelectedVideoPost?> pickVideoPost({
    required ImageSource source,
  }) async {
    if (kIsWeb) throw UnsupportedError('video_post_not_supported_on_web');
    final selected = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 30),
    );
    if (selected == null) return null;
    return SelectedVideoPost(await VideoPostProcessor.prepare(selected.path));
  }

  /// Keeps custom camera capture on the same preparation path as picker videos.
  static Future<SelectedVideoPost> prepareVideoPost(String sourcePath) async =>
      SelectedVideoPost(await VideoPostProcessor.prepare(sourcePath));

  /// Legacy image listings remain supported by the old Supabase project.
  static Future<List<String>> persistSelectedImages(
    List<SelectedImage> images, {
    String? listingId,
  }) async {
    await requireCurrentUgcLegalTerms();
    final prefix = listingId == null ? null : 'listings/$listingId';
    return Future.wait(
      images.map(
        (image) => storage.persistImage(
          image.file.path,
          image.extension,
          bucket: 'listing-images',
          objectPrefix: prefix,
        ),
      ),
    );
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
    String? city,
    String? cityId,
    required String phone,
    required String viber,
    required double price,
    double? originalPrice,
    required String currency,
    required String listingType,
    String? storeId,
    String status = 'available',
    SelectedVideoPost? video,
    @Deprecated('Listings are video-only.')
    List<SelectedImage> images = const [],
    double? latitude,
    double? longitude,
    bool isLocationVisible = true,
  }) async {
    final ownerId = _requireUser();
    await requireCurrentUgcLegalTerms();
    if (title.trim().isEmpty || category.trim().isEmpty || price < 0) {
      throw StateError('listing_required_fields_missing');
    }
    // Reject an invalid video-only listing before checking optional profile
    // completion, giving callers a stable and actionable validation result.
    if (video == null) throw StateError('listing_video_required');
    // Existing clients and listings did not have an original price. Keep that
    // flow compatible while validating a discount whenever it is provided.
    if (listingType == 'general' &&
        originalPrice != null &&
        originalPrice < price) {
      throw StateError('listing_original_price_invalid');
    }
    final normalizedStatus = status;
    var listingPhone = phone;
    var listingViber = viber;
    if (listingType == 'general') {
      await requireCompleteGeneralPostingProfile();
    }
    if (listingType == 'store') {
      if (storeId == null || storeId.isEmpty) {
        throw StateError('store_id_required');
      }
      final store = (await stores.all())
          .where((value) => value.id == storeId && value.ownerId == ownerId)
          .firstOrNull;
      if (store == null || store.status != 'approved') {
        throw StateError('store_not_approved');
      }
      listingPhone = _normalizePhone(store.phone);
      listingViber = _normalizePhone(store.viber);
    }
    final now = DateTime.now();
    final id = const Uuid().v4();
    final savedImages = await persistSelectedImages(images, listingId: id);
    ListingVideoRecord? savedVideo;
    if (video != null) {
      final draftPrefix = 'listings/drafts/${_requireUser()}/$id';
      final media = await storage.persistPrivateBinary(
        sourcePath: video.prepared.path,
        bucket: 'listing-videos',
        objectPrefix: draftPrefix,
        extension: 'mp4',
        mimeType: 'video/mp4',
      );
      final thumbnail = await storage.persistPrivateBytes(
        bytes: video.prepared.thumbnailBytes,
        bucket: 'listing-thumbnails',
        objectPrefix: draftPrefix,
        extension: 'jpg',
        mimeType: 'image/jpeg',
      );
      savedVideo = ListingVideoRecord(
        id: '',
        videoMediaId: media.id,
        thumbnailMediaId: thumbnail.id,
        videoPath: media.objectPath,
        thumbnailPath: thumbnail.objectPath,
        durationMilliseconds: video.prepared.durationMilliseconds,
        sizeBytes: media.sizeBytes,
      );
    }
    final value = ListingRecord(
      id: id,
      ownerId: ownerId,
      storeId: storeId,
      title: title,
      description: description,
      category: category,
      price: price,
      originalPrice: originalPrice,
      currency: currency,
      city: city?.trim() ?? '',
      cityId: cityId,
      status: normalizedStatus,
      video: savedVideo,
      images: savedImages,
      phone: listingPhone,
      viber: listingViber,
      latitude: latitude,
      longitude: longitude,
      isLocationVisible: isLocationVisible,
      createdAt: now,
      updatedAt: now,
    );
    try {
      final created = await listings.create(value);
      return created.toJson();
    } catch (error, stackTrace) {
      debugPrint(
        'Create listing failed: $error\n'
        'owner_id=$ownerId store_id=$storeId listing_type=$listingType\n'
        '$stackTrace',
      );
      rethrow;
    }
  }

  static Future<void> updateListing({
    required String listingId,
    required String title,
    required String description,
    required String city,
    String? cityId,
    required String phone,
    required String viber,
    required double price,
    double? originalPrice,
    required String currency,
    required String status,
    String? category,
    @Deprecated('Listings are video-only.') List<String>? images,
    @Deprecated('Listings are video-only.')
    List<SelectedImage> newImages = const [],
    double? latitude,
    double? longitude,
    bool? isLocationVisible,
  }) async {
    try {
      await requireCurrentUgcLegalTerms();
      final all = await listings.all();
      final old = all.where((e) => e.id == listingId).firstOrNull;
      if (old == null) throw StateError('not_found');
      if (old.ownerId != _requireUser()) throw StateError('not_owner');
      if (old.storeId != null) {
        final store = (await stores.all())
            .where(
              (value) =>
                  value.id == old.storeId && value.ownerId == currentUserId,
            )
            .firstOrNull;
        if (store == null || store.status != 'approved') {
          throw StateError('store_not_approved');
        }
      }
      final normalizedStatus = status;
      final allowedStatuses = const {'available', 'reserved', 'sold'};
      if (!allowedStatuses.contains(normalizedStatus)) {
        throw StateError('invalid_listing_status');
      }
      await listings.update(
        ListingRecord(
          id: old.id,
          ownerId: _requireUser(),
          storeId: old.storeId,
          title: title,
          description: description,
          category: category ?? old.category,
          price: price,
          originalPrice: originalPrice ?? old.originalPrice,
          currency: currency,
          city: city,
          cityId: cityId ?? old.cityId,
          cityRecord: old.cityRecord,
          status: normalizedStatus,
          video: old.video,
          phone: phone,
          viber: viber,
          createdAt: old.createdAt,
          updatedAt: DateTime.now(),
          likes: old.likes,
          views: old.views,
          latitude: latitude ?? old.latitude,
          longitude: longitude ?? old.longitude,
          isLocationVisible: isLocationVisible ?? old.isLocationVisible,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Listing status update failed: id=$listingId '
        'requested=$status error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Updates only a listing status. This deliberately avoids location and
  /// full-listing validation so legacy general listings without a city remain
  /// manageable by their owner.
  static Future<void> updateListingStatus({
    required String listingId,
    required String status,
  }) async {
    try {
      final old = (await listings.all())
          .where((listing) => listing.id == listingId)
          .firstOrNull;
      if (old == null) throw StateError('not_found');
      final ownerId = _requireUser();
      if (old.ownerId != ownerId) throw StateError('not_owner');
      final normalizedStatus = status;
      final allowedStatuses = const {'available', 'reserved', 'sold'};
      if (!allowedStatuses.contains(normalizedStatus)) {
        throw StateError('invalid_listing_status');
      }
      await listings.updateStatus(
        id: old.id,
        ownerId: ownerId,
        status: normalizedStatus,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Listing status update failed: id=$listingId '
        'requested=$status error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> deleteListing(String id) =>
      listings.delete(id, _requireUser());

  static Future<Map<String, dynamic>?> createStore({
    required String name,
    required String description,
    required String category,
    required String city,
    String? cityId,
    required String phone,
    required String viber,
    required String hours,
    required SelectedImage logo,
    SelectedImage? cover,
    String? email,
    double? latitude,
    double? longitude,
  }) async {
    if (city.trim().isEmpty) throw StateError('store_city_required');
    final id = const Uuid().v4();
    final ownerId = _requireUser();
    await requireCurrentUgcLegalTerms();
    final logoPath = await storage.persistImage(
      logo.file.path,
      logo.extension,
      bucket: 'store-images',
      objectPrefix: 'stores/drafts/$ownerId/$id',
    );
    final coverPath = cover == null
        ? ''
        : await storage.persistImage(
            cover.file.path,
            cover.extension,
            bucket: 'store-images',
            objectPrefix: 'stores/drafts/$ownerId/$id',
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
      city: city.trim(),
      cityId: cityId,
      location: '$city${latitude == null ? '' : ',$latitude,$longitude'}',
      openingHours: hours,
      status: 'pending',
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
    await requireCurrentUgcLegalTerms();
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
        cityId: values['city_id']?.toString() ?? old.cityId,
        cityRecord: old.cityRecord,
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
    await requireCurrentUgcLegalTerms();
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
    final store = (await stores.all())
        .where((value) => value.id == storeId)
        .firstOrNull;
    if (store?.status == 'rejected') {
      await storeRequests.resubmitRejected(storeId);
    }
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
      (await stores.publicStores())
          .where(
            (e) =>
                e.status == 'approved' &&
                e.lifecycleStatus == 'active' &&
                !e.isHidden &&
                e.deletedAt == null,
          )
          .map((e) => e.toJson())
          .toList();
  static Future<List<Map<String, dynamic>>> fetchMyStores() async =>
      (await stores.all())
          .where((e) => e.ownerId == currentUserId)
          .map((e) => e.toJson())
          .toList();
  static Future<List<Map<String, dynamic>>> fetchListings({
    double? latitude,
    double? longitude,
  }) async =>
      (await listings.publicListings(latitude: latitude, longitude: longitude))
          .where((e) => e.status != 'deleted' && e.status != 'hidden')
          .map(_listingMap)
          .toList();
  static Future<List<Map<String, dynamic>>> fetchListingsForStore(
    String storeId,
  ) async => (await listings.publicListings())
      .where(
        (e) =>
            e.storeId == storeId &&
            e.status != 'sold' &&
            e.status != 'deleted' &&
            e.status != 'hidden',
      )
      .map(_listingMap)
      .toList();
  static Future<List<Map<String, dynamic>>> fetchMapListings() async =>
      (await listings.publicListings())
          .where(
            (e) =>
                e.latitude != null &&
                e.longitude != null &&
                e.isLocationVisible &&
                e.isPublished &&
                !e.isHidden &&
                e.deletedAt == null &&
                (e.status == 'available' || e.status == 'reserved'),
          )
          .map(_listingMap)
          .toList();
  static Map<String, dynamic> _listingMap(ListingRecord e) => {
    ...e.toJson(),
    'listing_stats': {'like_count': e.likes, 'view_count': e.views},
  };
  static Future<void> likeListing(String id) async {
    await likes.like(id, deviceId);
  }

  static Future<void> trackView(String id) async {
    await likes.view(id, deviceId);
  }

  static Future<Set<String>> fetchLikedIds() => likes.likedIds(deviceId);

  static Future<void> submitReport({
    required String reason,
    required String details,
    String? listingId,
    String? storeId,
    String? userId,
  }) async {
    final targets = [
      listingId,
      storeId,
      userId,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    if (targets.length != 1) throw StateError('report_target_required');
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) throw StateError('report_reason_required');
    await reports.create(
      ReportRecord(
        id: const Uuid().v4(),
        reason: details.trim().isEmpty
            ? cleanReason
            : '$cleanReason: ${details.trim()}',
        targetId: targets.single,
        type: listingId != null
            ? 'listing'
            : storeId != null
            ? 'store'
            : 'user',
        deviceId: deviceId,
        createdAt: DateTime.now(),
      ),
    );
  }

  static Future<List<NotificationRecord>> fetchNotifications() =>
      isLoggedIn ? notifications.all() : Future.value(const []);
  static Future<int> unreadNotificationCount() =>
      isLoggedIn ? notifications.unreadCount() : Future.value(0);
  static Future<void> markNotificationRead(String id) =>
      isLoggedIn ? notifications.markRead(id) : Future.value();
  static Future<Position?> getCurrentPosition({bool request = true}) async {
    try {
      if (kIsWeb &&
          Uri.base.scheme != 'https' &&
          Uri.base.host != 'localhost' &&
          Uri.base.host != '127.0.0.1') {
        throw const LocationFailure(LocationFailureReason.insecureContext);
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationFailure(LocationFailureReason.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (request && permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        throw const LocationFailure(
          LocationFailureReason.permissionDeniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        throw const LocationFailure(LocationFailureReason.permissionDenied);
      }
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on LocationFailure catch (error, stackTrace) {
      debugPrint('Current location failed: $error\n$stackTrace');
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Current location unavailable: $error\n$stackTrace');
      throw LocationFailure(LocationFailureReason.unavailable, error);
    }
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

class _SignedUrlCacheEntry {
  final String url;
  final DateTime expiresAt;
  const _SignedUrlCacheEntry(this.url, this.expiresAt);
}
