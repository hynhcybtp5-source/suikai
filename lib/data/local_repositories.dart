import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'repositories.dart';
import 'store_categories.dart';
import 'local_storage_service_io.dart'
    if (dart.library.html) 'local_storage_service_web.dart';

Map<String, dynamic> _map(dynamic value) =>
    Map<String, dynamic>.from(value as Map);

StorageService createLocalStorageService() => LocalStorageService();

class LocalDatabase {
  static late Box<dynamic> users,
      listings,
      stores,
      interactions,
      reports,
      storeEditRequests,
      promotionRequests,
      categories;
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
  }
}

class LocalAuthRepository implements AuthRepository {
  static const _session = 'local_session_user_id';
  String? _current;
  @override
  String? get currentUserId {
    final id = _current;
    if (id == null) return null;
    final row = LocalDatabase.users.get(id);
    if (row == null || _map(row)['status'] == 'suspended') return null;
    return id;
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _current = prefs.getString(_session);
    final row = _current == null ? null : LocalDatabase.users.get(_current);
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
  }) async {
    final normalized = email.trim().toLowerCase();
    if (LocalDatabase.users.values.any((v) => _map(v)['email'] == normalized))
      throw StateError('email_exists');
    final p = UserProfile(
      id: const Uuid().v4(),
      name: name.trim(),
      phone: phone.trim(),
      email: normalized,
      createdAt: DateTime.now(),
    );
    await LocalDatabase.users.put(p.id, {
      ...p.toJson(),
      'password_hash': _hash(password),
    });
    return p;
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    final row = LocalDatabase.users.values
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
}

class LocalProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile?> get(String id) async {
    final v = LocalDatabase.users.get(id);
    return v == null ? null : UserProfile.fromJson(_map(v));
  }

  @override
  Future<void> save(UserProfile p) async {
    final old = _map(LocalDatabase.users.get(p.id));
    await LocalDatabase.users.put(p.id, {...old, ...p.toJson()});
  }
}

class LocalListingRepository implements ListingRepository {
  @override
  Future<List<ListingRecord>> all() async =>
      LocalDatabase.listings.values
          .map((v) => ListingRecord.fromJson(_map(v)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  @override
  Future<ListingRecord> create(ListingRecord v) async {
    await LocalDatabase.listings.put(v.id, v.toJson());
    return v;
  }

  @override
  Future<void> update(ListingRecord v) async {
    final old = LocalDatabase.listings.get(v.id);
    if (old == null || _map(old)['owner_id'] != v.ownerId)
      throw StateError('forbidden');
    await LocalDatabase.listings.put(v.id, v.toJson());
  }

  @override
  Future<void> delete(String id, String ownerId) async {
    final old = LocalDatabase.listings.get(id);
    if (old != null && _map(old)['owner_id'] == ownerId)
      await LocalDatabase.listings.delete(id);
  }
}

class LocalStoreRepository implements StoreRepository {
  @override
  Future<List<StoreRecord>> all() async => LocalDatabase.stores.values
      .map((v) => StoreRecord.fromJson(_map(v)))
      .toList();
  @override
  Future<StoreRecord> create(StoreRecord v) async {
    await LocalDatabase.stores.put(v.id, v.toJson());
    return v;
  }

  @override
  Future<void> update(StoreRecord v) async {
    final old = LocalDatabase.stores.get(v.id);
    if (old == null || _map(old)['owner_id'] != v.ownerId)
      throw StateError('forbidden');
    await LocalDatabase.stores.put(v.id, v.toJson());
  }

  @override
  Future<void> delete(String id, String ownerId) async {
    final old = LocalDatabase.stores.get(id);
    if (old != null && _map(old)['owner_id'] == ownerId)
      await LocalDatabase.stores.delete(id);
  }
}

class LocalStoreRequestRepository implements StoreRequestRepository {
  void _verifyOwner(String storeId, String ownerId) {
    final row = LocalDatabase.stores.get(storeId);
    if (row == null || _map(row)['owner_id'] != ownerId) {
      throw StateError('forbidden');
    }
  }

  @override
  Future<void> submitEdit(StoreEditRequestRecord value) async {
    _verifyOwner(value.storeId, value.ownerId);
    await LocalDatabase.storeEditRequests.put(value.id, value.toJson());
  }

  @override
  Future<void> submitPromotion(PromotionRequestRecord value) async {
    _verifyOwner(value.storeId, value.ownerId);
    final pending = LocalDatabase.promotionRequests.values
        .map(_map)
        .any((e) => e['store_id'] == value.storeId && e['status'] == 'pending');
    if (pending) throw StateError('request_pending');
    await LocalDatabase.promotionRequests.put(value.id, value.toJson());
  }
}

class LocalCategoryRepository implements CategoryRepository {
  Future<void> seedDefaults() async {
    for (final category in initialCategoryRecords) {
      if (!LocalDatabase.categories.containsKey(category.id)) {
        await LocalDatabase.categories.put(category.id, category.toJson());
      }
    }
  }

  Future<void> migrateLegacyReferences() async {
    final storeCategories = await getByType('store');
    final listingCategories = await getByType('listing');
    for (final key in LocalDatabase.stores.keys) {
      final row = _map(LocalDatabase.stores.get(key));
      final current = '${row['category'] ?? ''}';
      final match = storeCategories
          .where((c) => c.matches(current))
          .firstOrNull;
      if (match != null && current != match.id) {
        await LocalDatabase.stores.put(key, {...row, 'category': match.id});
      }
    }
    for (final key in LocalDatabase.listings.keys) {
      final row = _map(LocalDatabase.listings.get(key));
      if (row['store_id'] != null) continue;
      final current = '${row['category'] ?? ''}';
      final match = listingCategories
          .where((c) => c.matches(current))
          .firstOrNull;
      if (match != null && current != match.id) {
        await LocalDatabase.listings.put(key, {...row, 'category': match.id});
      }
    }
    for (final key in LocalDatabase.storeEditRequests.keys) {
      final row = _map(LocalDatabase.storeEditRequests.get(key));
      final proposed = Map<String, dynamic>.from(
        row['proposed_changes'] as Map? ?? const {},
      );
      final current = '${proposed['category'] ?? ''}';
      final match = storeCategories
          .where((c) => c.matches(current))
          .firstOrNull;
      if (match != null && current != match.id) {
        await LocalDatabase.storeEditRequests.put(key, {
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
      LocalDatabase.categories.values
          .map((value) => CategoryRecord.fromJson(_map(value)))
          .where(
            (category) =>
                category.type == type && (!activeOnly || category.isActive),
          )
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  @override
  Future<void> add(CategoryRecord value) async {
    if (LocalDatabase.categories.containsKey(value.id)) {
      throw StateError('category_exists');
    }
    await LocalDatabase.categories.put(value.id, value.toJson());
  }

  @override
  Future<void> update(CategoryRecord value) async {
    if (!LocalDatabase.categories.containsKey(value.id)) {
      throw StateError('category_not_found');
    }
    await LocalDatabase.categories.put(value.id, value.toJson());
  }

  @override
  Future<void> setActive(String id, bool active) async {
    final raw = LocalDatabase.categories.get(id);
    if (raw == null) throw StateError('category_not_found');
    await LocalDatabase.categories.put(id, {..._map(raw), 'is_active': active});
  }

  @override
  Future<void> reorder(String type, List<String> orderedIds) async {
    for (var index = 0; index < orderedIds.length; index++) {
      final id = orderedIds[index];
      final raw = LocalDatabase.categories.get(id);
      if (raw == null || _map(raw)['type'] != type) continue;
      await LocalDatabase.categories.put(id, {
        ..._map(raw),
        'sort_order': index,
      });
    }
  }
}

class LocalLikeRepository implements LikeRepository {
  String _key(String kind, String item, String device) => '$kind:$device:$item';
  @override
  Future<Set<String>> likedIds(String device) async => LocalDatabase
      .interactions
      .keys
      .whereType<String>()
      .where((k) => k.startsWith('like:$device:'))
      .map((k) => k.split(':').last)
      .toSet();
  @override
  Future<bool> like(String id, String device) async {
    final k = _key('like', id, device);
    if (LocalDatabase.interactions.containsKey(k)) return false;
    await LocalDatabase.interactions.put(k, DateTime.now().toIso8601String());
    return true;
  }

  @override
  Future<bool> view(String id, String device) async {
    final k = _key('view', id, device);
    if (LocalDatabase.interactions.containsKey(k)) return false;
    await LocalDatabase.interactions.put(k, DateTime.now().toIso8601String());
    return true;
  }
}

class LocalReportRepository implements ReportRepository {
  @override
  Future<void> create(ReportRecord r) =>
      LocalDatabase.reports.put(r.id, r.toJson());
}

class LocalAdminRepository implements AdminRepository {
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
    final rows = await listings();
    return {
      'users': LocalDatabase.users.length,
      'listings': rows.where((e) => e['store_id'] == null).length,
      'stores': LocalDatabase.stores.length,
      'store_products': rows.where((e) => e['store_id'] != null).length,
      'reports': LocalDatabase.reports.length,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> users() async {
    _guard();
    return LocalDatabase.users.values.map(_map).map((e) {
      final safe = Map<String, dynamic>.from(e)..remove('password_hash');
      safe['status'] ??= 'active';
      return safe;
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> listings() async {
    _guard();
    return LocalDatabase.listings.values.map(_map).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> stores() async {
    _guard();
    return LocalDatabase.stores.values.map(_map).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> reports() async {
    _guard();
    return LocalDatabase.reports.values.map(_map).map((e) {
      e['reviewed'] ??= false;
      return e;
    }).toList();
  }

  @override
  Future<void> setUserStatus(String id, String status) async {
    _guard();
    final row = LocalDatabase.users.get(id);
    if (row != null)
      await LocalDatabase.users.put(id, {..._map(row), 'status': status});
  }

  @override
  Future<void> deleteUser(String id) async {
    _guard();
    final ownedStores = LocalDatabase.stores.values
        .map(_map)
        .where((e) => e['owner_id'] == id)
        .map((e) => '${e['id']}')
        .toSet();
    final listingKeys = LocalDatabase.listings.values
        .map(_map)
        .where(
          (e) =>
              e['owner_id'] == id || ownedStores.contains('${e['store_id']}'),
        )
        .map((e) => '${e['id']}')
        .toList();
    await LocalDatabase.listings.deleteAll(listingKeys);
    await LocalDatabase.stores.deleteAll(ownedStores);
    await LocalDatabase.users.delete(id);
  }

  @override
  Future<void> setListingStatus(String id, String status) async {
    _guard();
    final row = LocalDatabase.listings.get(id);
    if (row != null)
      await LocalDatabase.listings.put(id, {
        ..._map(row),
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      });
  }

  @override
  Future<void> deleteListing(String id) async {
    _guard();
    await LocalDatabase.listings.delete(id);
  }

  @override
  Future<void> setStoreStatus(String id, String status) async {
    _guard();
    final row = LocalDatabase.stores.get(id);
    if (row != null)
      await LocalDatabase.stores.put(id, {..._map(row), 'status': status});
  }

  @override
  Future<void> deleteStore(String id) async {
    _guard();
    final products = LocalDatabase.listings.values
        .map(_map)
        .where((e) => '${e['store_id']}' == id)
        .map((e) => '${e['id']}')
        .toList();
    await LocalDatabase.listings.deleteAll(products);
    await LocalDatabase.stores.delete(id);
  }

  @override
  Future<void> reviewReport(String id, bool reviewed) async {
    _guard();
    final row = LocalDatabase.reports.get(id);
    if (row != null)
      await LocalDatabase.reports.put(id, {
        ..._map(row),
        'reviewed': reviewed,
        'reviewed_at': reviewed ? DateTime.now().toIso8601String() : null,
      });
  }

  @override
  Future<List<Map<String, dynamic>>> storeEditRequests() async {
    _guard();
    return LocalDatabase.storeEditRequests.values.map(_map).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> promotionRequests() async {
    _guard();
    return LocalDatabase.promotionRequests.values.map(_map).toList();
  }

  @override
  Future<void> reviewStoreEditRequest(String id, bool approved) async {
    _guard();
    final raw = LocalDatabase.storeEditRequests.get(id);
    if (raw == null) return;
    final request = _map(raw);
    if (request['status'] != 'pending') return;
    final storeId = '${request['store_id']}';
    final storeRaw = LocalDatabase.stores.get(storeId);
    if (approved && storeRaw != null) {
      final proposed = Map<String, dynamic>.from(
        request['proposed_changes'] as Map,
      );
      await LocalDatabase.stores.put(storeId, {..._map(storeRaw), ...proposed});
    }
    await LocalDatabase.storeEditRequests.put(id, {
      ...request,
      'status': approved ? 'approved' : 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> reviewPromotionRequest(String id, bool approved) async {
    _guard();
    final raw = LocalDatabase.promotionRequests.get(id);
    if (raw == null) return;
    final request = _map(raw);
    if (request['status'] != 'pending') return;
    if (approved) {
      final storeId = '${request['store_id']}';
      final storeRaw = LocalDatabase.stores.get(storeId);
      if (storeRaw != null) {
        await LocalDatabase.stores.put(storeId, {
          ..._map(storeRaw),
          'is_promoted': true,
          'promotion_start_at': request['requested_start_at'],
          'promotion_end_at': request['requested_end_at'],
        });
      }
    }
    await LocalDatabase.promotionRequests.put(id, {
      ...request,
      'status': approved ? 'approved' : 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> setStorePromoted(String id, bool promoted) async {
    _guard();
    final row = LocalDatabase.stores.get(id);
    if (row != null) {
      await LocalDatabase.stores.put(id, {
        ..._map(row),
        'is_promoted': promoted,
        if (!promoted) 'promotion_end_at': null,
      });
    }
  }
}
