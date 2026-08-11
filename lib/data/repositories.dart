import 'models.dart';

abstract interface class AuthRepository {
  String? get currentUserId;
  Future<UserProfile> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  });
  Future<UserProfile> login(String email, String password);
  Future<void> logout();
}

abstract interface class ProfileRepository {
  Future<UserProfile?> get(String id);
  Future<void> save(UserProfile profile);
}

abstract interface class ListingRepository {
  Future<List<ListingRecord>> all();
  Future<ListingRecord> create(ListingRecord value);
  Future<void> update(ListingRecord value);
  Future<void> delete(String id, String ownerId);
}

abstract interface class StoreRepository {
  Future<List<StoreRecord>> all();
  Future<StoreRecord> create(StoreRecord value);
  Future<void> update(StoreRecord value);
  Future<void> delete(String id, String ownerId);
}

abstract interface class StoreRequestRepository {
  Future<void> submitEdit(StoreEditRequestRecord value);
  Future<void> submitPromotion(PromotionRequestRecord value);
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

abstract interface class StorageService {
  Future<String> persistImage(String sourcePath, String extension);
}

/// Backend-neutral contract used only by privileged administration UI.
abstract interface class AdminRepository {
  bool get isAuthenticated;
  Future<bool> login(String email, String password);
  Future<void> logout();
  Future<Map<String, int>> summary();
  Future<List<Map<String, dynamic>>> users();
  Future<List<Map<String, dynamic>>> listings();
  Future<List<Map<String, dynamic>>> stores();
  Future<List<Map<String, dynamic>>> reports();
  Future<void> setUserStatus(String id, String status);
  Future<void> deleteUser(String id);
  Future<void> setListingStatus(String id, String status);
  Future<void> deleteListing(String id);
  Future<void> setStoreStatus(String id, String status);
  Future<void> deleteStore(String id);
  Future<void> reviewReport(String id, bool reviewed);
  Future<List<Map<String, dynamic>>> storeEditRequests();
  Future<List<Map<String, dynamic>>> promotionRequests();
  Future<void> reviewStoreEditRequest(String id, bool approved);
  Future<void> reviewPromotionRequest(String id, bool approved);
  Future<void> setStorePromoted(String id, bool promoted);
}
