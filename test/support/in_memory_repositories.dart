import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:suikai/data/models.dart';
import 'package:suikai/data/repositories.dart';
import 'package:suikai/data/store_categories.dart';

Map<String, dynamic> _map(dynamic value) =>
    Map<String, dynamic>.from(value as Map);

class InMemoryStorageService implements StorageService {
  @override
  Future<String> persistImage(
    String sourcePath,
    String extension, {
    String? bucket,
    String? objectPrefix,
  }) async => sourcePath;
}

class InMemoryAdvertisementRepository implements AdvertisementRepository {
  final List<AdvertisementRecord> values = [];

  @override
  Future<List<AdvertisementRecord>> active() async =>
      values.where((value) => value.isCurrentlyVisible).toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  @override
  Future<List<AdvertisementRecord>> all() async =>
      [...values]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  @override
  Future<void> create(AdvertisementRecord value) async => values.add(value);
  @override
  Future<void> update(AdvertisementRecord value) async {
    values.removeWhere((item) => item.id == value.id);
    values.add(value);
  }

  @override
  Future<void> delete(String id) async =>
      values.removeWhere((item) => item.id == id);
}

class TestDatabase {
  static late Box<dynamic> users,
      listings,
      stores,
      interactions,
      reports,
      storeEditRequests,
      promotionRequests,
      categories,
      shortVideos,
      adminNotifications;
  static Box<dynamic>? notifications;
  static Future<void> initialize() async {
    await Hive.initFlutter('suikai_local');
    users = await Hive.openBox('users_v1');
    listings = await Hive.openBox('listings_v1');
    stores = await Hive.openBox('stores_v1');
    interactions = await Hive.openBox('interactions_v1');
    reports = await Hive.openBox('reports_v1');
    storeEditRequests = await Hive.openBox('store_edit_requests_v1');
    promotionRequests = await Hive.openBox('promotion_requests_v1');
    categories = await Hive.openBox('categories_v1');
    notifications = await Hive.openBox('notifications_v1');
    shortVideos = await Hive.openBox('short_videos_v1');
    adminNotifications = await Hive.openBox('admin_notifications_v1');
  }
}

class InMemoryAuthRepository implements AuthRepository {
  static const _session = 'local_session_user_id';
  String? _current;
  @override
  String? get currentUserId {
    final id = _current;
    if (id == null) return null;
    final row = TestDatabase.users.get(id);
    if (row == null || _map(row)['status'] == 'suspended') return null;
    return id;
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _current = prefs.getString(_session);
    final row = _current == null ? null : TestDatabase.users.get(_current);
    if (row == null || _map(row)['status'] == 'suspended') {
      _current = null;
      await prefs.remove(_session);
    }
  }

  String _hash(String password) =>
      sha256.convert(password.codeUnits).toString();
  @override
  Future<UserProfile> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String city,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (TestDatabase.users.values.any((v) => _map(v)['email'] == normalized))
      throw StateError('email_exists');
    final p = UserProfile(
      id: const Uuid().v4(),
      name: name.trim(),
      phone: phone.trim(),
      email: normalized,
      city: city.trim(),
      createdAt: DateTime.now(),
    );
    await TestDatabase.users.put(p.id, {
      ...p.toJson(),
      'password_hash': _hash(password),
    });
    return p;
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final row = TestDatabase.users.values
        .cast<dynamic>()
        .map(_map)
        .where(
          (v) =>
              v['email'] == normalized && v['password_hash'] == _hash(password),
        )
        .firstOrNull;
    if (row == null) throw StateError('invalid_credentials');
    if (row['status'] == 'suspended') throw StateError('account_suspended');
    _current = '${row['id']}';
    (await SharedPreferences.getInstance()).setString(_session, _current!);
    return UserProfile.fromJson(row);
  }

  @override
  Future<void> logout() async {
    _current = null;
    await (await SharedPreferences.getInstance()).remove(_session);
  }
  @override
Future<void> loginWithTelegram() async {}

@override
Future<void> completeTelegramWebLogin() async {}

@override
Future<void> syncCurrentProfile() async {}
}

class InMemoryProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile?> get(String id) async {
    final v = TestDatabase.users.get(id);
    return v == null ? null : UserProfile.fromJson(_map(v));
  }

  @override
  Future<void> save(UserProfile p) async {
    final old = _map(TestDatabase.users.get(p.id));
    await TestDatabase.users.put(p.id, {...old, ...p.toJson()});
  }
}

class InMemoryListingRepository implements ListingRepository {
  @override
  Future<List<ListingRecord>> all() async =>
      TestDatabase.listings.values
          .map((v) => ListingRecord.fromJson(_map(v)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  @override
  Future<ListingRecord> create(ListingRecord v) async {
    if (v.city.trim().isEmpty) throw StateError('listing_city_required');
    await TestDatabase.listings.put(v.id, v.toJson());
    final notificationId = 'new_listing:${v.id}';
    await TestDatabase.adminNotifications.put(notificationId, {
      'id': notificationId,
      'type': v.storeId == null ? 'general_listing' : 'store_product',
      'listing_id': v.id,
      'title': v.storeId == null ? 'ประกาศใหม่' : 'สินค้าใหม่ในร้าน',
      'message': v.title,
      'is_read': false,
      'created_at': v.createdAt.toIso8601String(),
    });
    return v;
  }

  @override
  Future<void> update(ListingRecord v) async {
    final old = TestDatabase.listings.get(v.id);
    if (old == null || _map(old)['owner_id'] != v.ownerId)
      throw StateError('forbidden');
    await TestDatabase.listings.put(v.id, v.toJson());
  }

  @override
  Future<void> delete(String id, String ownerId) async {
    final old = TestDatabase.listings.get(id);
    if (old != null && _map(old)['owner_id'] == ownerId)
      await TestDatabase.listings.delete(id);
  }
}

class InMemoryStoreRepository implements StoreRepository {
  @override
  Future<List<StoreRecord>> all() async => TestDatabase.stores.values
      .map((v) => StoreRecord.fromJson(_map(v)))
      .toList();
  @override
  Future<StoreRecord> create(StoreRecord v) async {
    final pending = StoreRecord(
      id: v.id,
      ownerId: v.ownerId,
      name: v.name,
      logo: v.logo,
      cover: v.cover,
      description: v.description,
      category: v.category,
      phone: v.phone,
      viber: v.viber,
      city: v.city,
      location: v.location,
      openingHours: v.openingHours,
      status: 'pending',
      email: v.email,
      latitude: v.latitude,
      longitude: v.longitude,
      createdAt: v.createdAt,
    );
    await TestDatabase.stores.put(pending.id, pending.toJson());
    final notificationId = 'shop_application:${pending.id}';
    if (!TestDatabase.adminNotifications.containsKey(notificationId)) {
      await TestDatabase.adminNotifications.put(notificationId, {
        'id': notificationId,
        'type': 'shop_application',
        'shop_id': pending.id,
        'title': 'คำขอเปิดร้านใหม่',
        'message': 'ร้าน ${pending.name} ส่งคำขอเปิดร้าน',
        'is_read': false,
        'created_at': pending.createdAt.toIso8601String(),
      });
    }
    return pending;
  }

  @override
  Future<void> update(StoreRecord v) async {
    final old = TestDatabase.stores.get(v.id);
    if (old == null || _map(old)['owner_id'] != v.ownerId)
      throw StateError('forbidden');
    await TestDatabase.stores.put(v.id, {
      ...v.toJson(),
      'status': _map(old)['status'],
    });
  }

  @override
  Future<void> delete(String id, String ownerId) async {
    final old = TestDatabase.stores.get(id);
    if (old != null && _map(old)['owner_id'] == ownerId)
      await TestDatabase.stores.delete(id);
  }
}

class InMemoryStoreRequestRepository implements StoreRequestRepository {
  void _verifyOwner(String storeId, String ownerId) {
    final row = TestDatabase.stores.get(storeId);
    if (row == null || _map(row)['owner_id'] != ownerId) {
      throw StateError('forbidden');
    }
  }

  @override
  Future<void> submitEdit(StoreEditRequestRecord value) async {
    _verifyOwner(value.storeId, value.ownerId);
    await TestDatabase.storeEditRequests.put(value.id, value.toJson());
  }

  @override
  Future<void> submitPromotion(PromotionRequestRecord value) async {
    _verifyOwner(value.storeId, value.ownerId);
    final pending = TestDatabase.promotionRequests.values
        .map(_map)
        .any((e) => e['store_id'] == value.storeId && e['status'] == 'pending');
    if (pending) throw StateError('request_pending');
    await TestDatabase.promotionRequests.put(value.id, value.toJson());
  }

  @override
  Future<void> resubmitRejected(String storeId) async {
    final row = TestDatabase.stores.get(storeId);
    if (row == null) throw StateError('not_found');
    await TestDatabase.stores.put(storeId, _map(row)..['status'] = 'pending');
  }
}

class InMemoryCategoryRepository implements CategoryRepository {
  Future<void> seedDefaults() async {
    for (final category in initialCategoryRecords) {
      if (!TestDatabase.categories.containsKey(category.id)) {
        await TestDatabase.categories.put(category.id, category.toJson());
      }
    }
  }

  Future<void> migrateLegacyReferences() async {
    final storeCategories = await getByType('store');
    final listingCategories = await getByType('listing');
    for (final key in TestDatabase.stores.keys) {
      final row = _map(TestDatabase.stores.get(key));
      final current = '${row['category'] ?? ''}';
      final match = storeCategories
          .where((c) => c.matches(current))
          .firstOrNull;
      if (match != null && current != match.id) {
        await TestDatabase.stores.put(key, {...row, 'category': match.id});
      }
    }
    for (final key in TestDatabase.listings.keys) {
      final row = _map(TestDatabase.listings.get(key));
      if (row['store_id'] != null) continue;
      final current = '${row['category'] ?? ''}';
      final match = listingCategories
          .where((c) => c.matches(current))
          .firstOrNull;
      if (match != null && current != match.id) {
        await TestDatabase.listings.put(key, {...row, 'category': match.id});
      }
    }
    for (final key in TestDatabase.storeEditRequests.keys) {
      final row = _map(TestDatabase.storeEditRequests.get(key));
      final proposed = Map<String, dynamic>.from(
        row['proposed_changes'] as Map? ?? const {},
      );
      final current = '${proposed['category'] ?? ''}';
      final match = storeCategories
          .where((c) => c.matches(current))
          .firstOrNull;
      if (match != null && current != match.id) {
        await TestDatabase.storeEditRequests.put(key, {
          ...row,
          'proposed_changes': {...proposed, 'category': match.id},
        });
      }
    }
  }

  @override
  Future<List<CategoryRecord>> getByType(
    String type, {
    bool activeOnly = false,
  }) async =>
      TestDatabase.categories.values
          .map((value) => CategoryRecord.fromJson(_map(value)))
          .where(
            (category) =>
                category.type == type && (!activeOnly || category.isActive),
          )
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  Future<void> add(CategoryRecord value) async {
    if (TestDatabase.categories.containsKey(value.id)) {
      throw StateError('category_exists');
    }
    await TestDatabase.categories.put(value.id, value.toJson());
  }

  @override
  Future<void> update(CategoryRecord value) async {
    if (!TestDatabase.categories.containsKey(value.id)) {
      throw StateError('category_not_found');
    }
    await TestDatabase.categories.put(value.id, value.toJson());
  }

  @override
  Future<void> setActive(String id, bool active) async {
    final raw = TestDatabase.categories.get(id);
    if (raw == null) throw StateError('category_not_found');
    await TestDatabase.categories.put(id, {..._map(raw), 'is_active': active});
  }

  @override
  Future<void> reorder(String type, List<String> orderedIds) async {
    for (var index = 0; index < orderedIds.length; index++) {
      final id = orderedIds[index];
      final raw = TestDatabase.categories.get(id);
      if (raw == null || _map(raw)['type'] != type) continue;
      await TestDatabase.categories.put(id, {
        ..._map(raw),
        'sort_order': index,
      });
    }
  }
}

class InMemoryLikeRepository implements LikeRepository {
  String _key(String kind, String item, String device) => '$kind:$device:$item';
  @override
  Future<Set<String>> likedIds(String device) async => TestDatabase
      .interactions
      .keys
      .whereType<String>()
      .where((k) => k.startsWith('like:$device:'))
      .map((k) => k.split(':').last)
      .toSet();
  @override
  Future<bool> like(String id, String device) async {
    final k = _key('like', id, device);
    if (TestDatabase.interactions.containsKey(k)) return false;
    await TestDatabase.interactions.put(k, DateTime.now().toIso8601String());
    return true;
  }

  @override
  Future<bool> view(String id, String device) async {
    final k = _key('view', id, device);
    if (TestDatabase.interactions.containsKey(k)) return false;
    await TestDatabase.interactions.put(k, DateTime.now().toIso8601String());
    return true;
  }
}

class InMemoryReportRepository implements ReportRepository {
  @override
  Future<void> create(ReportRecord r) =>
      TestDatabase.reports.put(r.id, r.toJson());
}

class InMemoryNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationRecord>> all() async {
    final box = TestDatabase.notifications;
    if (box == null) return const [];
    return box.values
        .map((value) => NotificationRecord.fromJson(_map(value)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> markRead(String id) async {
    final box = TestDatabase.notifications;
    final raw = box?.get(id);
    if (raw == null) return;
    await box!.put(id, {
      ..._map(raw),
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<int> unreadCount() async =>
      (await all()).where((value) => !value.isRead).length;
}

class InMemoryShortVideoRepository implements ShortVideoRepository {
  List<ShortVideoRecord> _rows() =>
      TestDatabase.shortVideos.values
          .map(_map)
          .map(ShortVideoRecord.fromJson)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  Future<List<ShortVideoRecord>> active() async =>
      _rows().where((value) => value.isActive).toList();

  @override
  Future<List<ShortVideoRecord>> all() async => _rows();

  @override
  Future<void> create(ShortVideoRecord value) =>
      TestDatabase.shortVideos.put(value.id, value.toJson());

  @override
  Future<void> update(ShortVideoRecord value) =>
      TestDatabase.shortVideos.put(value.id, value.toJson());

  @override
  Future<void> delete(String id) => TestDatabase.shortVideos.delete(id);
}

class InMemoryAdminRepository implements AdminRepository {
  static const _sessionKey = 'local_admin_session';
  static const _adminEmail = 'admin@suikai.local';
  static final _adminHash = sha256.convert('admin1234'.codeUnits).toString();
  bool _authenticated = false;

  @override
  bool get isAuthenticated => _authenticated;

  Future<void> restore() async {
    _authenticated =
        (await SharedPreferences.getInstance()).getBool(_sessionKey) ?? false;
  }

  @override
  Future<bool> login(String email, String password) async {
    _authenticated =
        email.trim().toLowerCase() == _adminEmail &&
        sha256.convert(password.codeUnits).toString() == _adminHash;
    if (_authenticated) {
      await (await SharedPreferences.getInstance()).setBool(_sessionKey, true);
    }
    return _authenticated;
  }

  @override
  Future<void> logout() async {
    _authenticated = false;
    await (await SharedPreferences.getInstance()).remove(_sessionKey);
  }

  void _guard() {
    if (!_authenticated) throw StateError('admin_required');
  }

  @override
  Future<Map<String, int>> summary() async {
    _guard();
    final rows = TestDatabase.listings.values.map(_map).toList();
    return {
      'users': TestDatabase.users.length,
      'listings': rows.where((e) => e['store_id'] == null).length,
      'stores': TestDatabase.stores.length,
      'store_products': rows.where((e) => e['store_id'] != null).length,
      'reports': TestDatabase.reports.length,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> users({
    int page = 0,
    int pageSize = 50,
  }) async {
    _guard();
    return TestDatabase.users.values
        .map(_map)
        .map((e) {
          final safe = Map<String, dynamic>.from(e)..remove('password_hash');
          safe['status'] ??= 'active';
          return safe;
        })
        .skip(page * pageSize)
        .take(pageSize)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> listings({
    int page = 0,
    int pageSize = 50,
  }) async {
    _guard();
    return TestDatabase.listings.values
        .map(_map)
        .skip(page * pageSize)
        .take(pageSize)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> stores({
    int page = 0,
    int pageSize = 50,
  }) async {
    _guard();
    return TestDatabase.stores.values
        .map(_map)
        .skip(page * pageSize)
        .take(pageSize)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> reports({
    int page = 0,
    int pageSize = 50,
  }) async {
    _guard();
    return TestDatabase.reports.values
        .map(_map)
        .map((e) {
          e['reviewed'] ??= false;
          return e;
        })
        .skip(page * pageSize)
        .take(pageSize)
        .toList();
  }

  @override
  Future<void> setUserStatus(String id, String status) async {
    _guard();
    final row = TestDatabase.users.get(id);
    if (row != null)
      await TestDatabase.users.put(id, {..._map(row), 'status': status});
  }

  @override
  Future<void> deleteUser(String id) async {
    _guard();
    final ownedStores = TestDatabase.stores.values
        .map(_map)
        .where((e) => e['owner_id'] == id)
        .map((e) => '${e['id']}')
        .toSet();
    final listingKeys = TestDatabase.listings.values
        .map(_map)
        .where(
          (e) =>
              e['owner_id'] == id || ownedStores.contains('${e['store_id']}'),
        )
        .map((e) => '${e['id']}')
        .toList();
    await TestDatabase.listings.deleteAll(listingKeys);
    await TestDatabase.stores.deleteAll(ownedStores);
    await TestDatabase.users.delete(id);
  }

  @override
  Future<void> setListingStatus(String id, String status) async {
    _guard();
    final row = TestDatabase.listings.get(id);
    if (row != null)
      await TestDatabase.listings.put(id, {
        ..._map(row),
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });
  }

  @override
  Future<void> deleteListing(String id) async {
    _guard();
    await TestDatabase.listings.delete(id);
  }

  @override
  Future<void> setStoreStatus(String id, String status) async {
    _guard();
    final row = TestDatabase.stores.get(id);
    final next = status == 'active' ? 'approved' : status;
    if (row != null &&
        const {'pending', 'approved', 'rejected', 'suspended'}.contains(next)) {
      await TestDatabase.stores.put(id, {..._map(row), 'status': next});
    }
  }

  @override
  Future<void> deleteStore(String id) async {
    _guard();
    final products = TestDatabase.listings.values
        .map(_map)
        .where((e) => '${e['store_id']}' == id)
        .map((e) => '${e['id']}')
        .toList();
    await TestDatabase.listings.deleteAll(products);
    await TestDatabase.stores.delete(id);
  }

  @override
  Future<void> reviewReport(String id, bool reviewed) async {
    _guard();
    final row = TestDatabase.reports.get(id);
    if (row != null)
      await TestDatabase.reports.put(id, {
        ..._map(row),
        'reviewed': reviewed,
        'reviewed_at': reviewed ? DateTime.now().toIso8601String() : null,
      });
  }

  @override
  Future<List<Map<String, dynamic>>> storeEditRequests() async {
    _guard();
    return TestDatabase.storeEditRequests.values.map(_map).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> promotionRequests() async {
    _guard();
    return TestDatabase.promotionRequests.values.map(_map).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> adminNotifications() async {
    _guard();
    return TestDatabase.adminNotifications.values.map(_map).toList()
      ..sort((a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'));
  }

  @override
  Future<void> markAdminNotificationRead(String id) async {
    _guard();
    final row = TestDatabase.adminNotifications.get(id);
    if (row != null) {
      await TestDatabase.adminNotifications.put(id, {
        ..._map(row),
        'is_read': true,
      });
    }
  }

  @override
  Future<void> reviewStoreEditRequest(String id, bool approved) async {
    _guard();
    final raw = TestDatabase.storeEditRequests.get(id);
    if (raw == null) return;
    final request = _map(raw);
    if (request['status'] != 'pending') return;
    final storeId = '${request['store_id']}';
    final storeRaw = TestDatabase.stores.get(storeId);
    if (approved && storeRaw != null) {
      final proposed = Map<String, dynamic>.from(
        request['proposed_changes'] as Map,
      );
      await TestDatabase.stores.put(storeId, {..._map(storeRaw), ...proposed});
    }
    await TestDatabase.storeEditRequests.put(id, {
      ...request,
      'status': approved ? 'approved' : 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> reviewPromotionRequest(String id, bool approved) async {
    _guard();
    final raw = TestDatabase.promotionRequests.get(id);
    if (raw == null) return;
    final request = _map(raw);
    if (request['status'] != 'pending') return;
    if (approved) {
      final storeId = '${request['store_id']}';
      final storeRaw = TestDatabase.stores.get(storeId);
      if (storeRaw != null) {
        await TestDatabase.stores.put(storeId, {
          ..._map(storeRaw),
          'is_promoted': true,
          'promotion_start_at': request['requested_start_at'],
          'promotion_end_at': request['requested_end_at'],
        });
      }
    }
    await TestDatabase.promotionRequests.put(id, {
      ...request,
      'status': approved ? 'approved' : 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> setStorePromoted(String id, bool promoted) async {
    _guard();
    final row = TestDatabase.stores.get(id);
    if (row != null) {
      await TestDatabase.stores.put(id, {
        ..._map(row),
        'is_promoted': promoted,
        if (!promoted) 'promotion_end_at': null,
      });
    }
  }
}
