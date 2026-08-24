import 'models.dart';

abstract interface class AuthRepository {
  String? get currentUserId;
  Future<void> restore();
  Future<UserProfile> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String city,
  });
  Future<UserProfile> login(String email, String password);
  Future<void> loginWithTelegram();
  Future<void> completeTelegramWebLogin();
  Future<void> syncCurrentProfile();
  Future<void> logout();
}

abstract interface class ProfileRepository {
  Future<UserProfile?> get(String id);
  Future<UserProfile> save(UserProfile profile);
}

abstract interface class ListingRepository {
  Future<List<ListingRecord>> all();
  Future<List<ListingRecord>> publicListings();
  Future<ListingRecord> create(ListingRecord value);
  Future<void> update(ListingRecord value);
  Future<void> updateStatus({
    required String id,
    required String ownerId,
    required String status,
  });
  Future<void> delete(String id, String ownerId);
}

abstract interface class StoreRepository {
  Future<List<StoreRecord>> all();
  Future<List<StoreRecord>> publicStores();
  Future<StoreRecord> create(StoreRecord value);
  Future<void> update(StoreRecord value);
  Future<void> delete(String id, String ownerId);
}

abstract interface class StoreRequestRepository {
  Future<void> submitEdit(StoreEditRequestRecord value);
  Future<void> submitPromotion(PromotionRequestRecord value);
  Future<void> resubmitRejected(String storeId);
}

abstract interface class CategoryRepository {
  Future<List<CategoryRecord>> getByType(
    String type, {
    bool activeOnly = false,
  });
  Future<void> add(CategoryRecord value);
  Future<void> update(CategoryRecord value);
  Future<void> setActive(String id, bool active);
  Future<void> reorder(String type, List<String> orderedIds);
}

abstract interface class LikeRepository {
  Future<Set<String>> likedIds(String deviceId);
  Future<bool> like(String listingId, String deviceId);
  Future<bool> view(String listingId, String deviceId);
}

abstract interface class ReportRepository {
  Future<void> create(ReportRecord report);
}

abstract interface class NotificationRepository {
  Future<List<NotificationRecord>> all();
  Future<void> markRead(String id);
  Future<int> unreadCount();
}

abstract interface class ShortVideoRepository {
  Future<List<ShortVideoRecord>> active();
  Future<List<ShortVideoRecord>> all();
  Future<void> create(ShortVideoRecord value);
  Future<void> update(ShortVideoRecord value);
  Future<void> delete(String id);
}

abstract interface class AdvertisementRepository {
  Future<List<AdvertisementRecord>> active();
  Future<List<AdvertisementRecord>> all();
  Future<void> create(AdvertisementRecord value);
  Future<void> update(AdvertisementRecord value);
  Future<void> delete(String id);
}

abstract interface class StorageService {
  Future<String> persistImage(
    String sourcePath,
    String extension, {
    String? bucket,
    String? objectPrefix,
  });
  Future<StoredMedia> persistPrivateBinary({
    required String sourcePath,
    required String bucket,
    required String objectPrefix,
    required String extension,
    required String mimeType,
  });
  Future<StoredMedia> persistPrivateBytes({
    required List<int> bytes,
    required String bucket,
    required String objectPrefix,
    required String extension,
    required String mimeType,
  });
  Future<String> createSignedUrl({
    required String bucket,
    required String objectPath,
    required int expiresInSeconds,
  });
}

class StoredMedia {
  final String id, bucket, objectPath;
  final int sizeBytes;
  const StoredMedia({
    required this.id,
    required this.bucket,
    required this.objectPath,
    required this.sizeBytes,
  });
}

/// Backend-neutral contract used only by privileged administration UI.
abstract interface class AdminRepository {
  bool get isAuthenticated;
  Future<void> restore();
  Future<bool> login(String email, String password);
  Future<void> logout();
  Future<Map<String, int>> summary();
  Future<Map<String, dynamic>> analytics(String period);
  Future<List<Map<String, dynamic>>> users({int page = 0, int pageSize = 50});
  Future<List<Map<String, dynamic>>> listings({
    int page = 0,
    int pageSize = 50,
  });
  Future<List<Map<String, dynamic>>> stores({int page = 0, int pageSize = 50});
  Future<List<Map<String, dynamic>>> reports({int page = 0, int pageSize = 50});
  Future<void> setUserStatus(String id, String status);
  Future<void> deleteUser(String id);
  Future<void> setListingStatus(String id, String status);
  Future<void> deleteListing(String id);
  Future<void> setStoreStatus(String id, String status);
  Future<void> deleteStore(String id);
  Future<void> reviewReport(String id, bool reviewed);
  Future<List<Map<String, dynamic>>> storeEditRequests();
  Future<List<Map<String, dynamic>>> promotionRequests();
  Future<List<Map<String, dynamic>>> adminNotifications();
  Future<void> markAdminNotificationRead(String id);
  Future<void> reviewStoreEditRequest(String id, bool approved);
  Future<void> reviewPromotionRequest(String id, bool approved);
  Future<void> setStorePromoted(String id, bool promoted);
}
