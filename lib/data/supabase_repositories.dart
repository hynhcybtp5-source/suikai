import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'models.dart';
import 'repositories.dart';

class SupabaseBackend {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const legacyAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static String get clientKey =>
      publishableKey.isNotEmpty ? publishableKey : legacyAnonKey;

  static bool get enabled => url.isNotEmpty && clientKey.isNotEmpty;

  static Future<void> initialize() async {
    if (!enabled) return;
    await Supabase.initialize(url: url, publishableKey: clientKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}

Map<String, dynamic> _json(dynamic value) =>
    Map<String, dynamic>.from(value as Map);

String _mediaUrl(SupabaseClient client, Map<String, dynamic> media) => client
    .storage
    .from('${media['bucket']}')
    .getPublicUrl('${media['object_path']}');

Future<Map<String, dynamic>?> _mediaForUrl(
  SupabaseClient client,
  String url,
) async {
  if (url.isEmpty) return null;
  final segments = Uri.tryParse(url)?.pathSegments ?? const <String>[];
  final publicIndex = segments.indexOf('public');
  if (publicIndex < 0 || publicIndex + 2 > segments.length) return null;
  final row = await client
      .from('media_assets')
      .select()
      .eq('bucket', segments[publicIndex + 1])
      .eq('object_path', segments.skip(publicIndex + 2).join('/'))
      .maybeSingle();
  return row == null ? null : _json(row);
}

Future<void> _deleteMediaIfOrphan(
  SupabaseClient client,
  String? mediaId,
) async {
  if (mediaId == null || mediaId.isEmpty) return;
  final references = await Future.wait([
    client
        .from('profiles')
        .select('id')
        .eq('avatar_media_id', mediaId)
        .limit(1),
    client.from('stores').select('id').eq('logo_media_id', mediaId).limit(1),
    client.from('stores').select('id').eq('cover_media_id', mediaId).limit(1),
    client.from('listing_images').select('id').eq('media_id', mediaId).limit(1),
  ]);
  if (references.any((rows) => rows.isNotEmpty)) return;
  final row = await client
      .from('media_assets')
      .select()
      .eq('id', mediaId)
      .maybeSingle();
  if (row == null) return;
  final media = _json(row);
  await client.storage.from('${media['bucket']}').remove([
    '${media['object_path']}',
  ]);
  await client.from('media_assets').delete().eq('id', mediaId);
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient client;
  SupabaseAuthRepository(this.client);

  @override
  String? get currentUserId => client.auth.currentUser?.id;

  Future<void> restore() async {}

  @override
  Future<UserProfile> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'name': name.trim(), 'phone': phone.trim()},
    );
    final user = response.user;
    if (user == null) throw StateError('signup_failed');
    return UserProfile(
      id: user.id,
      name: name.trim(),
      phone: phone.trim(),
      email: user.email ?? email.trim().toLowerCase(),
      createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    );
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = response.user;
    if (user == null) throw StateError('invalid_credentials');
    final row = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    if (row['status'] == 'suspended') {
      await client.auth.signOut();
      throw StateError('account_suspended');
    }
    return _profileFromRow(_json(row), user: user);
  }

  @override
  Future<void> logout() => client.auth.signOut();
}

UserProfile _profileFromRow(Map<String, dynamic> row, {User? user}) =>
    UserProfile(
      id: '${row['id']}',
      name: '${row['name'] ?? ''}',
      phone: '${row['phone'] ?? ''}',
      email: '${row['email'] ?? user?.email ?? ''}',
      avatar: '${user?.userMetadata?['avatar_url'] ?? ''}',
      createdAt: DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
    );

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient client;
  SupabaseProfileRepository(this.client);

  @override
  Future<UserProfile?> get(String id) async {
    final row = await client
        .from('profiles')
        .select()
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    final data = _json(row);
    final mediaId = data['avatar_media_id']?.toString();
    if (mediaId != null) {
      final media = await client
          .from('media_assets')
          .select()
          .eq('id', mediaId)
          .maybeSingle();
      if (media != null) data['avatar'] = _mediaUrl(client, _json(media));
    }
    final profile = _profileFromRow(data, user: client.auth.currentUser);
    if (data['avatar'] == null) return profile;
    return UserProfile(
      id: profile.id,
      name: profile.name,
      phone: profile.phone,
      email: profile.email,
      avatar: '${data['avatar']}',
      createdAt: profile.createdAt,
    );
  }

  @override
  Future<void> save(UserProfile profile) async {
    final old = await client
        .from('profiles')
        .select('avatar_media_id')
        .eq('id', profile.id)
        .single();
    final oldMediaId = old['avatar_media_id']?.toString();
    final media = await _mediaForUrl(client, profile.avatar);
    final newMediaId = media?['id']?.toString();
    await client
        .from('profiles')
        .update({
          'name': profile.name,
          'phone': profile.phone,
          'email': profile.email,
          'avatar_media_id': newMediaId,
        })
        .eq('id', profile.id);
    if (profile.avatar.isNotEmpty) {
      await client.auth.updateUser(
        UserAttributes(data: {'avatar_url': profile.avatar}),
      );
    }
    if (oldMediaId != newMediaId) {
      await _deleteMediaIfOrphan(client, oldMediaId);
    }
  }
}

class SupabaseCategoryRepository implements CategoryRepository {
  final SupabaseClient client;
  SupabaseCategoryRepository(this.client);

  @override
  Future<List<CategoryRecord>> getByType(
    String type, {
    bool activeOnly = false,
  }) async {
    var query = client.from('categories').select().eq('type', type);
    if (activeOnly) query = query.eq('is_active', true);
    final rows = await query.order('sort_order');
    return rows.map((row) => CategoryRecord.fromJson(_json(row))).toList();
  }

  Map<String, dynamic> _payload(CategoryRecord value) => {
    'id': value.id,
    'kind': value.type,
    'name': value.nameTh,
    'active': value.isActive,
    'type': value.type,
    'name_th': value.nameTh,
    'name_shn': value.nameShn,
    'name_en': value.nameEn,
    'name_my': value.nameMy,
    'is_active': value.isActive,
    'sort_order': value.sortOrder,
  };

  @override
  Future<void> add(CategoryRecord value) =>
      client.from('categories').insert(_payload(value));

  @override
  Future<void> update(CategoryRecord value) => client
      .from('categories')
      .update(_payload(value)..remove('id'))
      .eq('id', value.id);

  @override
  Future<void> setActive(String id, bool active) => client
      .from('categories')
      .update({'is_active': active, 'active': active})
      .eq('id', id);

  @override
  Future<void> reorder(String type, List<String> orderedIds) async {
    for (var index = 0; index < orderedIds.length; index++) {
      await client
          .from('categories')
          .update({'sort_order': index})
          .eq('id', orderedIds[index])
          .eq('type', type);
    }
  }
}

class SupabaseListingRepository implements ListingRepository {
  final SupabaseClient client;
  SupabaseListingRepository(this.client);

  Future<ListingRecord> _record(Map<String, dynamic> row) async {
    final imageRows =
        (row['listing_images'] as List? ?? const []).map(_json).toList()..sort(
          (a, b) => ((a['sort_order'] as num?)?.toInt() ?? 0).compareTo(
            (b['sort_order'] as num?)?.toInt() ?? 0,
          ),
        );
    final likes = await client.rpc(
      'get_listing_like_count',
      params: {'p_listing_id': row['id']},
    );
    final views = await client.rpc(
      'get_listing_view_count',
      params: {'p_listing_id': row['id']},
    );
    return ListingRecord.fromJson({
      ...row,
      'category': row['category_id'] ?? row['category'] ?? '',
      'images': imageRows.map((image) => '${image['image_url']}').toList(),
      'likes': (likes as num?)?.toInt() ?? 0,
      'views': (views as num?)?.toInt() ?? 0,
    });
  }

  @override
  Future<List<ListingRecord>> all() async {
    final rows = await client
        .from('listings')
        .select('*, listing_images(image_url, media_id, sort_order)')
        .order('created_at', ascending: false);
    return Future.wait(rows.map((row) => _record(_json(row))));
  }

  Map<String, dynamic> _payload(ListingRecord value) => {
    'id': value.id,
    'owner_id': value.ownerId,
    'store_id': value.storeId,
    'listing_type': value.storeId == null ? 'general' : 'store',
    'title': value.title,
    'description': value.description,
    'category_id': value.category,
    'price': value.price,
    'currency': value.currency,
    'city': value.city,
    'phone': value.phone,
    'viber_phone': value.viber,
    'status': value.status,
    'latitude': value.latitude,
    'longitude': value.longitude,
    'is_location_visible': value.isLocationVisible,
  };

  Future<void> _replaceImages(ListingRecord value) async {
    final oldRows = await client
        .from('listing_images')
        .select('media_id')
        .eq('listing_id', value.id);
    final mediaIds = <String?>[];
    for (final url in value.images) {
      mediaIds.add((await _mediaForUrl(client, url))?['id']?.toString());
    }
    await client.from('listing_images').delete().eq('listing_id', value.id);
    if (value.images.isNotEmpty) {
      await client.from('listing_images').insert([
        for (var index = 0; index < value.images.length; index++)
          {
            'listing_id': value.id,
            'image_url': value.images[index],
            'media_id': mediaIds[index],
            'sort_order': index,
            'is_primary': index == 0,
          },
      ]);
    }
    final retained = mediaIds.whereType<String>().toSet();
    for (final row in oldRows) {
      final oldMediaId = row['media_id']?.toString();
      if (!retained.contains(oldMediaId)) {
        await _deleteMediaIfOrphan(client, oldMediaId);
      }
    }
  }

  @override
  Future<ListingRecord> create(ListingRecord value) async {
    await client.from('listings').insert(_payload(value));
    await _replaceImages(value);
    return value;
  }

  @override
  Future<void> update(ListingRecord value) async {
    final payload = _payload(value)
      ..remove('id')
      ..remove('owner_id');
    await client.from('listings').update(payload).eq('id', value.id);
    await _replaceImages(value);
  }

  @override
  Future<void> delete(String id, String ownerId) async {
    await client
        .from('listings')
        .update({
          'is_hidden': true,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('owner_id', ownerId);
  }
}

class SupabaseStoreRepository implements StoreRepository {
  final SupabaseClient client;
  SupabaseStoreRepository(this.client);

  @override
  Future<List<StoreRecord>> all() async {
    final rows = await client.from('stores').select().order('created_at');
    return rows.map((row) {
      final data = _json(row);
      return StoreRecord.fromJson({
        ...data,
        'category': data['category_id'] ?? data['category'] ?? '',
      });
    }).toList();
  }

  Future<Map<String, dynamic>> _payload(StoreRecord value) async {
    final hours = value.openingHours.split('-');
    final logoMedia = await _mediaForUrl(client, value.logo);
    final coverMedia = await _mediaForUrl(client, value.cover);
    return {
      'id': value.id,
      'owner_id': value.ownerId,
      'name': value.name,
      'description': value.description,
      'logo_url': value.logo,
      'cover_url': value.cover,
      'logo_media_id': logoMedia?['id'],
      'cover_media_id': coverMedia?['id'],
      'category_id': value.category,
      'phone': value.phone,
      'viber_phone': value.viber,
      'email': value.email,
      'city': value.city,
      'location': value.location,
      'latitude': value.latitude,
      'longitude': value.longitude,
      'opening_time': hours.isEmpty ? null : hours.first.trim(),
      'closing_time': hours.length < 2 ? null : hours.last.trim(),
      'status': 'pending',
      'lifecycle_status': 'pending',
      'is_promoted': false,
    };
  }

  @override
  Future<StoreRecord> create(StoreRecord value) async {
    await client.from('stores').insert(await _payload(value));
    return value;
  }

  @override
  Future<void> update(StoreRecord value) async =>
      throw StateError('store_edit_request_required');

  @override
  Future<void> delete(String id, String ownerId) async =>
      throw StateError('admin_required');
}

class SupabaseStoreRequestRepository implements StoreRequestRepository {
  final SupabaseClient client;
  SupabaseStoreRequestRepository(this.client);

  @override
  Future<void> submitEdit(StoreEditRequestRecord value) async {
    final proposed = Map<String, dynamic>.from(value.proposedChanges);
    if (proposed['category'] != null) {
      proposed['category_id'] = proposed.remove('category');
    }
    for (final field in const ['logo', 'cover']) {
      final urlKey = '${field}_url';
      final url = proposed[urlKey]?.toString();
      if (url == null || url.isEmpty) continue;
      proposed['${field}_media_id'] = (await _mediaForUrl(client, url))?['id'];
    }
    await client.from('store_edit_requests').insert({
      'id': value.id,
      'store_id': value.storeId,
      'owner_id': value.ownerId,
      'proposed_changes': proposed,
      'status': 'pending',
    });
  }

  @override
  Future<void> submitPromotion(PromotionRequestRecord value) =>
      client.from('promotion_requests').insert(value.toJson());
}

class SupabaseLikeRepository implements LikeRepository {
  final SupabaseClient client;
  SupabaseLikeRepository(this.client);

  String _key(String device) => 'supabase_liked_$device';

  @override
  Future<Set<String>> likedIds(String deviceId) async =>
      (await SharedPreferences.getInstance())
          .getStringList(_key(deviceId))
          ?.toSet() ??
      <String>{};

  @override
  Future<bool> like(String listingId, String deviceId) async {
    final liked =
        await client.rpc(
              'toggle_listing_like',
              params: {'p_listing_id': listingId, 'p_device_id': deviceId},
            )
            as bool;
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(_key(deviceId)) ?? const []).toSet();
    liked ? ids.add(listingId) : ids.remove(listingId);
    await prefs.setStringList(_key(deviceId), ids.toList());
    return liked;
  }

  @override
  Future<bool> view(String listingId, String deviceId) async {
    await client.rpc(
      'record_listing_view',
      params: {'p_listing_id': listingId, 'p_device_id': deviceId},
    );
    return true;
  }
}

class SupabaseReportRepository implements ReportRepository {
  final SupabaseClient client;
  SupabaseReportRepository(this.client);

  @override
  Future<void> create(ReportRecord report) => client.from('reports').insert({
    'id': report.id,
    if (report.type == 'listing') 'listing_id': report.targetId,
    if (report.type == 'store') 'store_id': report.targetId,
    'reason': report.reason,
    'status': 'open',
    'workflow_status': 'pending',
  });
}

class SupabaseNotificationRepository implements NotificationRepository {
  final SupabaseClient client;
  SupabaseNotificationRepository(this.client);

  @override
  Future<List<NotificationRecord>> all() async {
    if (client.auth.currentUser == null) return const [];
    final rows = await client
        .from('notifications')
        .select()
        .order('created_at', ascending: false);
    return rows.map((row) => NotificationRecord.fromJson(_json(row))).toList();
  }

  @override
  Future<void> markRead(String id) async {
    if (client.auth.currentUser == null) return;
    await client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<int> unreadCount() async =>
      (await all()).where((value) => !value.isRead).length;
}

class SupabaseStorageService implements StorageService {
  final SupabaseClient client;
  SupabaseStorageService(this.client);

  @override
  Future<String> persistImage(
    String sourcePath,
    String extension, {
    String? bucket,
    String? objectPrefix,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('login_required');
    final targetBucket = bucket ?? 'profile-images';
    final prefix = objectPrefix ?? 'profiles/$userId';
    final path = '$prefix/${const Uuid().v4()}.$extension';
    final bytes = await XFile(sourcePath).readAsBytes();
    await client.storage
        .from(targetBucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$extension'),
        );
    try {
      await client.from('media_assets').insert({
        'owner_id': userId,
        'bucket': targetBucket,
        'object_path': path,
        'mime_type': 'image/$extension',
        'size_bytes': bytes.length,
      });
    } catch (_) {
      await client.storage.from(targetBucket).remove([path]);
      rethrow;
    }
    return client.storage.from(targetBucket).getPublicUrl(path);
  }
}

class SupabaseAdminRepository implements AdminRepository {
  final SupabaseClient client;
  bool _authenticated = false;
  SupabaseAdminRepository(this.client);

  @override
  bool get isAuthenticated => _authenticated;

  Future<void> restore() async {
    if (client.auth.currentUser == null) return;
    _authenticated = await client.rpc('is_active_admin') == true;
  }

  void _guard() {
    if (!_authenticated) throw StateError('admin_required');
  }

  @override
  Future<bool> login(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    _authenticated = await client.rpc('is_active_admin') == true;
    if (!_authenticated) await client.auth.signOut();
    return _authenticated;
  }

  @override
  Future<void> logout() async {
    _authenticated = false;
    await client.auth.signOut();
  }

  @override
  Future<List<Map<String, dynamic>>> users() async {
    _guard();
    return (await client.from('profiles').select().order('created_at'))
        .map(_json)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> listings() async {
    _guard();
    final rows = await client
        .from('listings')
        .select('*, listing_images(image_url, sort_order)')
        .order('created_at', ascending: false);
    return rows.map((row) {
      final value = _json(row);
      value['images'] = (value['listing_images'] as List? ?? const [])
          .map((image) => '${_json(image)['image_url']}')
          .toList();
      return value;
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> stores() async {
    _guard();
    return (await client.from('stores').select().order('created_at'))
        .map(_json)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> reports() async {
    _guard();
    return (await client.from('reports').select().order('created_at')).map((
      row,
    ) {
      final value = _json(row);
      value['target_id'] = value['listing_id'] ?? value['store_id'];
      value['type'] = value['listing_id'] == null ? 'store' : 'listing';
      value['reviewed'] = value['workflow_status'] != 'pending';
      value['status'] = value['workflow_status'];
      return value;
    }).toList();
  }

  @override
  Future<Map<String, int>> summary() async {
    final allUsers = await users();
    final allListings = await listings();
    return {
      'users': allUsers.length,
      'listings': allListings.where((row) => row['store_id'] == null).length,
      'stores': (await stores()).length,
      'store_products': allListings
          .where((row) => row['store_id'] != null)
          .length,
      'reports': (await reports()).length,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> storeEditRequests() async {
    _guard();
    return (await client
            .from('store_edit_requests')
            .select()
            .order('created_at'))
        .map(_json)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> promotionRequests() async {
    _guard();
    return (await client
            .from('promotion_requests')
            .select()
            .order('created_at'))
        .map(_json)
        .toList();
  }

  @override
  Future<void> setUserStatus(String id, String status) => client.rpc(
    'admin_set_profile_status',
    params: {'p_user_id': id, 'p_status': status},
  );

  @override
  Future<void> deleteUser(String id) => setUserStatus(id, 'suspended');

  @override
  Future<void> setListingStatus(String id, String status) => client.rpc(
    'admin_moderate_listing',
    params: {'p_listing_id': id, 'p_status': status},
  );

  @override
  Future<void> deleteListing(String id) => client.rpc(
    'admin_moderate_listing',
    params: {'p_listing_id': id, 'p_status': 'deleted'},
  );

  @override
  Future<void> setStoreStatus(String id, String status) => client.rpc(
    'admin_set_store_status',
    params: {'p_store_id': id, 'p_status': status},
  );

  @override
  Future<void> deleteStore(String id) => setStoreStatus(id, 'suspended');

  @override
  Future<void> reviewReport(String id, bool reviewed) => reviewed
      ? client.rpc(
          'review_report',
          params: {'p_report_id': id, 'p_status': 'reviewed'},
        )
      : Future<void>.value();

  @override
  Future<void> reviewStoreEditRequest(String id, bool approved) async {
    final row = await client
        .from('store_edit_requests')
        .select('before_snapshot, proposed_changes')
        .eq('id', id)
        .single();
    final before = Map<String, dynamic>.from(
      row['before_snapshot'] as Map? ?? const {},
    );
    final proposed = Map<String, dynamic>.from(
      row['proposed_changes'] as Map? ?? const {},
    );
    await client.rpc(
      'review_store_edit_request',
      params: {'p_request_id': id, 'p_approved': approved},
    );
    for (final field in const ['logo_media_id', 'cover_media_id']) {
      if (!proposed.containsKey(field)) continue;
      final oldId = before[field]?.toString();
      final newId = proposed[field]?.toString();
      if (approved && oldId != newId) {
        await _deleteMediaIfOrphan(client, oldId);
      } else if (!approved) {
        await _deleteMediaIfOrphan(client, newId);
      }
    }
  }

  @override
  Future<void> reviewPromotionRequest(String id, bool approved) => client.rpc(
    'review_promotion_request',
    params: {'p_request_id': id, 'p_approved': approved},
  );

  @override
  Future<void> setStorePromoted(String id, bool promoted) => client.rpc(
    'admin_set_store_promoted',
    params: {'p_store_id': id, 'p_promoted': promoted},
  );
}
