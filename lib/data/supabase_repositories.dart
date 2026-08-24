import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final endpoint = Uri.tryParse(url);
    if (endpoint == null ||
        !endpoint.hasScheme ||
        !endpoint.hasAuthority ||
        (endpoint.scheme != 'https' && endpoint.scheme != 'http')) {
      throw StateError('invalid_supabase_url');
    }
    debugPrint(
      'Supabase initialize: scheme=${endpoint.scheme} host=${endpoint.host}',
    );
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: clientKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      debugPrint('Supabase initialize: complete host=${endpoint.host}');
    } catch (error, stackTrace) {
      debugPrint('Supabase initialize failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}

Map<String, dynamic> _json(dynamic value) =>
    Map<String, dynamic>.from(value as Map);

/// PostgREST normally serializes an embedded to-many relation as a list, but
/// older views/proxies can return a single object when exactly one row exists.
/// Normalize the response shape before relation consumers inspect it.
List<dynamic> _relationRows(dynamic value) => switch (value) {
  List<dynamic> rows => rows,
  List rows => rows,
  Map<String, dynamic> row => [row],
  Map row => [Map<String, dynamic>.from(row)],
  _ => const [],
};

List<String> _listingImageUrls(
  SupabaseClient client,
  dynamic relation,
) {
  final rows = _relationRows(relation).map(_json).toList()
    ..sort(
      (a, b) => ((a['sort_order'] as num?)?.toInt() ?? 0).compareTo(
        (b['sort_order'] as num?)?.toInt() ?? 0,
      ),
    );
  final urls = <String>[];
  for (final image in rows) {
    var url = '${image['image_url'] ?? ''}'.trim();
    final media = image['media_assets'];
    if (media is Map) {
      final asset = _json(media);
      final bucket = '${asset['bucket'] ?? ''}'.trim();
      final path = '${asset['object_path'] ?? ''}'.trim();
      if (bucket.isNotEmpty && path.isNotEmpty) {
        url = client.storage.from(bucket).getPublicUrl(path);
      }
    }
    if (url.isNotEmpty && !urls.contains(url)) urls.add(url);
  }
  return urls;
}

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
    client
        .from('listing_videos')
        .select('id')
        .eq('video_media_id', mediaId)
        .limit(1),
    client
        .from('listing_videos')
        .select('id')
        .eq('thumbnail_media_id', mediaId)
        .limit(1),
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
  static const _telegramAuthorizationUrl = 'https://oauth.telegram.org/auth';
  static const _telegramCallbackUri = String.fromEnvironment(
    'TELEGRAM_CALLBACK_URL',
  );
  static const _telegramClientId = String.fromEnvironment('TELEGRAM_CLIENT_ID');
  static const _telegramStatePreference = 'telegram_oauth_state';
  static const _telegramVerifierPreference = 'telegram_oauth_code_verifier';

  final SupabaseClient client;
  SupabaseAuthRepository(this.client);

  @override
  String? get currentUserId => client.auth.currentUser?.id;

  @override
  Future<void> restore() async {
    debugPrint('AUTH RESTORE START');
    try {
      await client.auth.getSession();
      debugPrint(
        'AUTH RESTORE COMPLETE sessionNull=${client.auth.currentSession == null} '
        'currentUserNull=${client.auth.currentUser == null}',
      );
    } on AuthException catch (error, stackTrace) {
      debugPrint('AUTH RESTORE FAILED errorType=${error.runtimeType}');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String city,
  }) async {
    final response = await client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'name': name.trim(), 'phone': phone.trim(), 'city': city.trim()},
    );
    final user = response.user;
    if (user == null) throw StateError('signup_failed');
    await syncCurrentProfile();
    return UserProfile(
      id: user.id,
      name: name.trim(),
      phone: phone.trim(),
      email: user.email ?? email.trim().toLowerCase(),
      city: city.trim(),
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
    await syncCurrentProfile();
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
  Future<void> loginWithTelegram() async {
    debugPrint('LOGIN START provider=telegram');
    if (_telegramClientId.isEmpty || _telegramCallbackUri.isEmpty) {
      throw StateError('telegram_client_id_not_configured');
    }

    final preferences = await SharedPreferences.getInstance();
    final state = '${kIsWeb ? 'web' : 'mobile'}.${_randomUrlSafeValue(32)}';
    final verifier = _randomUrlSafeValue(64);
    final challenge = base64Url
        .encode(sha256.convert(utf8.encode(verifier)).bytes)
        .replaceAll('=', '');

    await preferences.setString(_telegramStatePreference, state);
    await preferences.setString(_telegramVerifierPreference, verifier);

    final callbackUri = Uri.parse(_telegramCallbackUri);
    final authorizationUri = Uri.parse(_telegramAuthorizationUrl).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': _telegramClientId,
        'redirect_uri': _telegramCallbackUri,
        'origin': callbackUri.origin,
        'scope': 'openid',
        'state': state,
        'code_challenge': challenge,
        'code_challenge_method': 'S256',
      },
    );
    debugPrint(
      'TELEGRAM AUTH URL CREATED '
      'callbackHost=${callbackUri.host}',
    );

    final launched = await launchUrl(
      authorizationUri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_self',
    );
    if (!launched) throw StateError('telegram_authorization_not_opened');
  }

  @override
  Future<void> completeTelegramWebLogin() async {
    if (!kIsWeb) return;
    await completeTelegramLogin(Uri.base);
  }

  Future<void> completeTelegramLogin(Uri callbackUri) async {
    final code = callbackUri.queryParameters['code'];
    final callbackError = callbackUri.queryParameters['error'];
    debugPrint(
      'CALLBACK RECEIVED hasCode=${code?.isNotEmpty == true} '
      'hasError=${callbackError?.isNotEmpty == true}',
    );
    if ((code == null || code.isEmpty) &&
        (callbackError == null || callbackError.isEmpty)) {
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final receivedState = callbackUri.queryParameters['state'];
    final expectedState = preferences.getString(_telegramStatePreference);
    final verifier = preferences.getString(_telegramVerifierPreference);

    await preferences.remove(_telegramStatePreference);
    await preferences.remove(_telegramVerifierPreference);

    final stateValid = expectedState != null &&
        verifier != null &&
        receivedState != null &&
        _constantTimeEquals(expectedState, receivedState);
    debugPrint('CALLBACK STATE VALID=$stateValid');
    if (!stateValid) {
      throw StateError('telegram_oauth_state_mismatch');
    }
    if (callbackError != null && callbackError.isNotEmpty) {
      throw StateError(
        callbackUri.queryParameters['error_description'] ?? callbackError,
      );
    }
    if (code == null || code.isEmpty) {
      throw StateError('telegram_authorization_code_missing');
    }

    debugPrint('TOKEN EXCHANGE START');
    late final FunctionResponse response;
    try {
      response = await client.functions.invoke(
        'telegram-auth',
        body: {
          'code': code,
          'code_verifier': verifier,
          'redirect_uri': _telegramCallbackUri,
        },
      );
      debugPrint('TOKEN EXCHANGE SUCCESS');
    } catch (error) {
      debugPrint('TOKEN EXCHANGE FAILED errorType=${error.runtimeType}');
      rethrow;
    }
    final payload = _json(response.data);
    final tokenHash = payload['token_hash']?.toString();
    if (tokenHash == null || tokenHash.isEmpty) {
      throw StateError('telegram_token_hash_missing');
    }

    debugPrint('VERIFY OTP START');
    try {
      await client.auth.verifyOTP(type: OtpType.email, tokenHash: tokenHash);
      debugPrint(
        'VERIFY OTP SUCCESS sessionNull=${client.auth.currentSession == null} '
        'currentUserNull=${client.auth.currentUser == null}',
      );
    } catch (error) {
      debugPrint('VERIFY OTP FAILED errorType=${error.runtimeType}');
      rethrow;
    }
    await syncCurrentProfile();
  }

  @override
  Future<void> syncCurrentProfile() async {
    if (currentUserId == null) return;
    try {
      await client.rpc('sync_current_profile_from_auth');
    } on PostgrestException catch (error) {
      // Remote production has the standard auth-user profile trigger but not
      // the optional Telegram profile-sync RPC migration. The profile was
      // already created when Auth generated the magic link, so retain login.
      if (error.code != 'PGRST202' && error.code != '42883') rethrow;
    }
  }

  @override
  Future<void> logout() => client.auth.signOut();
}

String _randomUrlSafeValue(int byteCount) {
  final random = Random.secure();
  final bytes = List<int>.generate(byteCount, (_) => random.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

bool _constantTimeEquals(String left, String right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var index = 0; index < left.length; index++) {
    difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
  }
  return difference == 0;
}

UserProfile _profileFromRow(Map<String, dynamic> row, {User? user}) =>
    UserProfile(
      id: '${row['id']}',
      name: '${row['name'] ?? ''}',
      phone: '${row['phone'] ?? ''}',
      email: '${row['email'] ?? user?.email ?? ''}',
      avatar: '${user?.userMetadata?['avatar_url'] ?? ''}',
      city: '${row['city'] ?? ''}',
      cityId: row['city_id']?.toString(),
      viber: '${row['viber_phone'] ?? ''}',
      createdAt: DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
    );

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient client;
  SupabaseProfileRepository(this.client);

  @override
  Future<UserProfile?> get(String id) async {
    if (client.auth.currentUser?.id != id) {
      final row = await client.rpc(
        'get_public_seller_profile',
        params: {'p_owner_id': id},
      );
      if (row is! Map) return null;
      final data = _json(row);
      final bucket = data['avatar_bucket']?.toString();
      final path = data['avatar_path']?.toString();
      if (bucket != null &&
          bucket.isNotEmpty &&
          path != null &&
          path.isNotEmpty) {
        data['avatar'] = _mediaUrl(
          client,
          {'bucket': bucket, 'object_path': path},
        );
      }
      final profile = _profileFromRow(data);
      return UserProfile(
        id: profile.id,
        name: profile.name,
        phone: '',
        email: '',
        avatar: '${data['avatar'] ?? ''}',
        city: profile.city,
        cityId: profile.cityId,
        viber: '',
        createdAt: profile.createdAt,
      );
    }
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
      city: profile.city,
      cityId: profile.cityId,
      viber: profile.viber,
      createdAt: profile.createdAt,
    );
  }

  @override
  Future<UserProfile> save(UserProfile profile) async {
    final old = await client
        .from('profiles')
        .select('avatar_media_id')
        .eq('id', profile.id)
        .single();
    final oldMediaId = old['avatar_media_id']?.toString();
    final media = await _mediaForUrl(client, profile.avatar);
    final newMediaId = media?['id']?.toString();
    final row = await client
        .from('profiles')
        .update({
          'name': profile.name,
          'phone': profile.phone,
          'email': profile.email,
          'avatar_media_id': newMediaId,
          'city_id': profile.cityId,
          'city': profile.city.trim(),
          'viber_phone': profile.viber.trim(),
        })
        .eq('id', profile.id)
        .select('id,name,phone,email,city,city_id,viber_phone,created_at')
        .maybeSingle();
    if (row == null) throw StateError('profile_update_not_applied');
    if (profile.avatar.isNotEmpty) {
      await client.auth.updateUser(
        UserAttributes(data: {'avatar_url': profile.avatar}),
      );
    }
    if (oldMediaId != newMediaId) {
      await _deleteMediaIfOrphan(client, oldMediaId);
    }
    final saved = _profileFromRow(_json(row), user: client.auth.currentUser);
    return UserProfile(
      id: saved.id,
      name: saved.name,
      phone: saved.phone,
      email: saved.email,
      avatar: profile.avatar,
      city: saved.city,
      cityId: saved.cityId,
      viber: saved.viber,
      createdAt: saved.createdAt,
    );
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
    'icon_key': value.iconKey,
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
  Future<void> setActive(String id, bool active) =>
      client
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
  bool _canResolveCityCoordinates = true;
  SupabaseListingRepository(this.client);

  /// Listing cards remain available when an optional aggregate RPC is not
  /// deployed or temporarily unavailable. The next refresh retries it.
  Future<int> _listingMetric(String function, String listingId) async {
    try {
      final value = await client.rpc(
        function,
        params: {'p_listing_id': listingId},
      );
      return int.tryParse('$value') ?? 0;
    } catch (error, stackTrace) {
      debugPrint(
        'Listing metric unavailable: function=$function listing=$listingId '
        'error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return 0;
    }
  }

  Future<ListingRecord> _record(Map<String, dynamic> row) async {
    if (_canResolveCityCoordinates &&
        row['cities'] == null &&
        row['city_id'] == null &&
        row['latitude'] != null &&
        row['longitude'] != null) {
      try {
        final resolved = await client.rpc(
          'resolve_city_for_coordinates',
          params: {
            'p_latitude': row['latitude'],
            'p_longitude': row['longitude'],
          },
        );
        if (resolved is Map && resolved.isNotEmpty) {
          row = {
            ...row,
            'city_id': resolved['id'],
            'cities': Map<String, dynamic>.from(resolved),
          };
        }
      } on PostgrestException catch (error) {
        // The additive city-coordinate migration may not be deployed yet.
        // Keep the real city text from this listing; never substitute mock data.
        debugPrint('City coordinate resolution unavailable: $error');
        if (error.code == 'PGRST202' || error.code == '42703') {
          _canResolveCityCoordinates = false;
        }
      }
    }
    final likes = await _listingMetric(
      'get_listing_like_count',
      '${row['id']}',
    );
    final views = await _listingMetric(
      'get_listing_view_count',
      '${row['id']}',
    );
    return ListingRecord.fromJson({
      ...row,
      'category': row['category_id'] ?? row['category'] ?? '',
      'listing_video':
          _relationRows(row['listing_videos']).firstOrNull ??
          row['listing_video'],
      'images': _listingImageUrls(client, row['listing_images']),
      'likes': likes,
      'views': views,
    });
  }

  @override
  Future<List<ListingRecord>> publicListings() async {
    final response = await client.rpc('get_public_listings');
    final rows = (response as List? ?? const [])
        .map((row) => _json(row))
        .toList();
    return Future.wait(rows.map(_record));
  }

  @override
  Future<List<ListingRecord>> all() async {
    final rows = await client
        .from('listings')
        .select(
          '*, listing_videos(id,video_media_id,thumbnail_media_id,duration_milliseconds,size_bytes,'
          'video_media_assets:media_assets!listing_videos_video_media_id_fkey(object_path),'
          'thumbnail_media_assets:media_assets!listing_videos_thumbnail_media_id_fkey(object_path)), '
          'listing_images(id,image_url,media_id,sort_order,media_assets(bucket,object_path)), '
          'cities(id,name,name_th,name_shn,name_en,name_my,is_active)',
        )
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
    'city': value.city.trim(),
    if (value.cityId != null && value.cityId!.trim().isNotEmpty)
      'city_id': value.cityId,
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
      final mediaId = row['media_id']?.toString();
      if (!retained.contains(mediaId)) await _deleteMediaIfOrphan(client, mediaId);
    }
  }

  @override
  Future<ListingRecord> create(ListingRecord value) async {
    try {
      final authUserId = client.auth.currentUser?.id;
      if (value.ownerId.trim().isEmpty) {
        throw StateError('listing_owner_required');
      }
      if (authUserId == null || authUserId != value.ownerId) {
        throw StateError('listing_owner_auth_mismatch');
      }
      if (value.storeId != null && value.city.trim().isEmpty) {
        throw StateError('store_listing_city_required');
      }
      if (value.storeId != null) {
        final store = await client
            .from('stores')
            .select('id,owner_id,status,is_hidden,deleted_at')
            .eq('id', value.storeId!)
            .maybeSingle();
        if (store == null ||
            store['owner_id'] != authUserId ||
            store['status'] != 'approved' ||
            store['is_hidden'] == true ||
            store['deleted_at'] != null) {
          throw StateError('store_not_approved_or_not_owned');
        }
      }
      final row = await client
          .from('listings')
          .insert(_payload(value))
          .select()
          .single();
      await _replaceImages(value);
      final video = value.video;
      if (video != null) {
        await client.from('listing_videos').insert({
          'listing_id': value.id,
          'video_media_id': video.videoMediaId,
          'thumbnail_media_id': video.thumbnailMediaId,
          'duration_milliseconds': video.durationMilliseconds,
          'size_bytes': video.sizeBytes,
        });
      }
      return ListingRecord.fromJson({
        ..._json(row),
        'category': row['category_id'] ?? row['category'] ?? value.category,
        if (video != null) 'listing_video': video.toJson(),
        'images': value.images,
      });
    } catch (error, stackTrace) {
      debugPrint(
        'Supabase listing insert failed: $error\n'
        'owner_id=${value.ownerId} store_id=${value.storeId} '
        'listing_type=${value.storeId == null ? 'general' : 'store'} '
        'category_id=${value.category}\n$stackTrace',
      );
      rethrow;
    }
  }

  @override
  Future<void> update(ListingRecord value) async {
    if (value.storeId != null && value.city.trim().isEmpty) {
      throw StateError('store_listing_city_required');
    }
    if (value.storeId != null) {
      final userId = client.auth.currentUser?.id;
      final store = await client
          .from('stores')
          .select('owner_id,status,is_hidden,deleted_at')
          .eq('id', value.storeId!)
          .maybeSingle();
      if (userId == null ||
          store == null ||
          store['owner_id'] != userId ||
          store['status'] != 'approved' ||
          store['is_hidden'] == true ||
          store['deleted_at'] != null) {
        throw StateError('store_not_approved_or_not_owned');
      }
    }
    final payload = _payload(value)
      ..remove('id')
      ..remove('owner_id');
    // A PostgREST update without `select()` can complete successfully even
    // when RLS filters every row. Read the returned status so callers never
    // treat an unapplied status change as a successful save.
    final updated = await client
        .from('listings')
        .update(payload)
        .eq('id', value.id)
        .select('id,status')
        .maybeSingle();
    if (updated == null) throw StateError('listing_update_not_applied');
    if ('${updated['status']}' != value.status) {
      throw StateError('listing_status_update_mismatch');
    }
    await _replaceImages(value);
    debugPrint(
      'Listing status updated: id=${value.id} status=${updated['status']}',
    );
  }

  @override
  Future<void> updateStatus({
    required String id,
    required String ownerId,
    required String status,
  }) async {
    final updated = await client
        .from('listings')
        .update({'status': status})
        .eq('id', id)
        .eq('owner_id', ownerId)
        .select('id,status')
        .maybeSingle();
    if (updated == null) throw StateError('listing_status_update_not_applied');
    if ('${updated['id']}' != id || '${updated['status']}' != status) {
      throw StateError('listing_status_update_mismatch');
    }
    debugPrint('Listing status updated: id=$id status=${updated['status']}');
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
    final rows = await client
        .from('stores')
        .select('*,cities(id,name,name_th,name_shn,name_en,name_my,is_active)')
        .order('created_at');
    return _records(rows);
  }

  @override
  Future<List<StoreRecord>> publicStores() async {
    final rows = await client.rpc('get_public_stores') as List? ?? const [];
    return _records(rows);
  }

  List<StoreRecord> _records(List<dynamic> rows) {
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
      'city': value.city.trim(),
      'city_id': value.cityId,
      'location': value.location,
      'latitude': value.latitude,
      'longitude': value.longitude,
      'opening_time': hours.isEmpty ? null : hours.first.trim(),
      'closing_time': hours.length < 2 ? null : hours.last.trim(),
      'status': 'pending',
      'is_promoted': false,
    };
  }

  @override
  Future<StoreRecord> create(StoreRecord value) async {
    if (value.city.trim().isEmpty) throw StateError('store_city_required');
    await client.from('stores').insert(await _payload(value));
    return value;
  }

  @override
  Future<void> update(StoreRecord value) async =>
      throw StateError('store_edit_request_required');

  @override
  Future<void> delete(String id, String ownerId) async =>
      client.rpc('owner_delete_unapproved_store', params: {'p_store_id': id});
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

  @override
  Future<void> resubmitRejected(String storeId) => client.rpc(
    'owner_resubmit_rejected_store',
    params: {'p_store_id': storeId},
  );
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
    'status': 'pending',
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

class SupabaseShortVideoRepository implements ShortVideoRepository {
  final SupabaseClient client;
  SupabaseShortVideoRepository(this.client);

  List<ShortVideoRecord> _records(List<dynamic> rows) =>
      rows.map((row) => ShortVideoRecord.fromJson(_json(row))).toList();

  Future<T> _timed<T>(String name, Future<T> Function() query) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('Supabase $name: start');
    try {
      return await query();
    } finally {
      debugPrint('Supabase $name: end ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  @override
  Future<List<ShortVideoRecord>> active() async => _records(
    await client
        .from('tiktok_videos')
        .select()
        .eq('is_active', true)
        .order('sort_order')
        .order('created_at'),
  );

  @override
  Future<List<ShortVideoRecord>> all() async => _records(
    await _timed(
      'tiktok_videos.page_1',
      () => client
          .from('tiktok_videos')
          .select(
            'id,tiktok_url,title,sort_order,is_active,created_by,created_at,updated_at',
          )
          .order('sort_order')
          .order('created_at')
          .range(0, 99),
    ),
  );

  Map<String, dynamic> _payload(ShortVideoRecord value) => {
    'id': value.id,
    'tiktok_url': value.tiktokUrl,
    'title': value.title.trim(),
    'sort_order': value.displayOrder,
    'is_active': value.isActive,
    'created_by': value.createdBy ?? client.auth.currentUser?.id,
  };

  @override
  Future<void> create(ShortVideoRecord value) =>
      client.from('tiktok_videos').insert(_payload(value));

  @override
  Future<void> update(ShortVideoRecord value) => client
      .from('tiktok_videos')
      .update(_payload(value)..remove('id'))
      .eq('id', value.id);

  @override
  Future<void> delete(String id) =>
      client.from('tiktok_videos').delete().eq('id', id);
}

class SupabaseAdvertisementRepository implements AdvertisementRepository {
  final SupabaseClient client;
  SupabaseAdvertisementRepository(this.client);

  Map<String, dynamic> _payload(AdvertisementRecord value) => {
    'id': value.id,
    'title': value.title,
    'image_url': value.imageUrl,
    'target_type': value.targetType,
    'target_id': value.targetId,
    // `target_url` is supported by both the original and current banners
    // schema. Sending deprecated aliases (`active`, `sort_order`) or the
    // optional `external_url` column makes inserts fail against deployments
    // that use the current baseline schema.
    'target_url': value.externalUrl,
    'start_at': value.startAt?.toUtc().toIso8601String(),
    'end_at': value.endAt?.toUtc().toIso8601String(),
    'display_order': value.displayOrder,
    'is_active': value.isActive,
  };

  @override
  Future<List<AdvertisementRecord>> active() async {
    final rows = await client
        .from('banners')
        .select()
        .eq('is_active', true)
        .order('display_order');
    return rows
        .map((row) => AdvertisementRecord.fromJson(_json(row)))
        .where((value) => value.isCurrentlyVisible)
        .toList();
  }

  @override
  Future<List<AdvertisementRecord>> all() async {
    final rows = await client.from('banners').select().order('display_order');
    return rows.map((row) => AdvertisementRecord.fromJson(_json(row))).toList();
  }

  @override
  Future<void> create(AdvertisementRecord value) =>
      client.from('banners').insert(_payload(value));

  @override
  Future<void> update(AdvertisementRecord value) => client
      .from('banners')
      .update(_payload(value)..remove('id'))
      .eq('id', value.id);

  @override
  Future<void> delete(String id) =>
      client.from('banners').delete().eq('id', id);
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

  @override
  Future<StoredMedia> persistPrivateBinary({
    required String sourcePath,
    required String bucket,
    required String objectPrefix,
    required String extension,
    required String mimeType,
  }) async {
    final bytes = await XFile(sourcePath).readAsBytes();
    return persistPrivateBytes(
      bytes: bytes,
      bucket: bucket,
      objectPrefix: objectPrefix,
      extension: extension,
      mimeType: mimeType,
    );
  }

  @override
  Future<StoredMedia> persistPrivateBytes({
    required List<int> bytes,
    required String bucket,
    required String objectPrefix,
    required String extension,
    required String mimeType,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('login_required');
    final path = '$objectPrefix/${const Uuid().v4()}.$extension';
    await client.storage
        .from(bucket)
        .uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: mimeType),
        );
    try {
      final row = await client
          .from('media_assets')
          .insert({
            'owner_id': userId,
            'bucket': bucket,
            'object_path': path,
            'mime_type': mimeType,
            'size_bytes': bytes.length,
          })
          .select('id')
          .single();
      return StoredMedia(
        id: '${row['id']}',
        bucket: bucket,
        objectPath: path,
        sizeBytes: bytes.length,
      );
    } catch (_) {
      await client.storage.from(bucket).remove([path]);
      rethrow;
    }
  }

  @override
  Future<String> createSignedUrl({
    required String bucket,
    required String objectPath,
    required int expiresInSeconds,
  }) async {
    try {
      return await client.storage
          .from(bucket)
          .createSignedUrl(objectPath, expiresInSeconds);
    } catch (error, stackTrace) {
      // Never log the signed URL itself. Bucket/path and caller identity are
      // enough to identify an RLS denial while keeping access tokens private.
      debugPrint(
        'Listing media signed URL denied: bucket=$bucket path=$objectPath '
        'user=${client.auth.currentUser?.id ?? 'anon'} error=$error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}

class SupabaseAdminRepository implements AdminRepository {
  final SupabaseClient client;
  bool _authenticated = false;
  SupabaseAdminRepository(this.client);

  @override
  bool get isAuthenticated => _authenticated;

  @override
  Future<void> restore() async {
    if (client.auth.currentUser == null) return;
    _authenticated = await client.rpc('is_active_admin') == true;
  }

  void _guard() {
    if (!_authenticated) throw StateError('admin_required');
  }

  Future<T> _timed<T>(String name, Future<T> Function() query) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('Supabase admin $name: start');
    try {
      return await query();
    } finally {
      debugPrint(
        'Supabase admin $name: end ${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  @override
  Future<bool> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw StateError('admin_credentials_required');
    }
    _authenticated = false;
    // Never log credentials. This marker separates a synchronous client/config
    // failure from an HTTP failure in the browser console.
    debugPrint('Admin login: starting Auth request');
    try {
      final response = await client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      if (response.session == null) throw StateError('admin_session_missing');
      debugPrint('Admin login: Auth session established; checking admin role');
      _authenticated = await client.rpc('is_active_admin') == true;
      if (!_authenticated) {
        debugPrint('Admin login: is_active_admin returned false');
        await client.auth.signOut();
      }
      return _authenticated;
    } catch (error, stackTrace) {
      _authenticated = false;
      debugPrint('Admin login failed before completion: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    _authenticated = false;
    await client.auth.signOut();
  }

  @override
  Future<List<Map<String, dynamic>>> users({
    int page = 0,
    int pageSize = 50,
  }) async {
    _guard();
    final rows = (await _timed(
      'profiles.page_1',
      () => client
          .from('profiles')
          .select('id,name,phone,email,avatar_media_id,status,created_at')
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1),
    )).map(_json).toList();
    final mediaIds = rows
        .map((row) => row['avatar_media_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (mediaIds.isEmpty) return rows;
    final mediaRows = await client
        .from('media_assets')
        .select('id,bucket,object_path')
        .inFilter('id', mediaIds);
    final avatarUrls = <String, String>{};
    for (final item in mediaRows) {
      final media = _json(item);
      final bucket = '${media['bucket'] ?? ''}';
      final path = '${media['object_path'] ?? ''}';
      if (bucket.isNotEmpty && path.isNotEmpty) {
        avatarUrls['${media['id']}'] = client.storage
            .from(bucket)
            .getPublicUrl(path);
      }
    }
    for (final row in rows) {
      row['avatar_url'] = avatarUrls['${row['avatar_media_id']}'] ?? '';
    }
    return rows;
  }

  @override
  Future<List<Map<String, dynamic>>> listings({
    int page = 0,
    int pageSize = 50,
  }) async {
    _guard();
    final rows = await _timed(
      'listings.page_1',
      () => client
          .from('listings')
          .select(
            'id,owner_id,store_id,title,description,category,category_id,'
            'price,currency,city,status,created_at,latitude,longitude,'
            'is_location_visible,listing_videos(id,video_media_id,thumbnail_media_id,'
            'duration_milliseconds,size_bytes,'
            'video_media_assets:media_assets!listing_videos_video_media_id_fkey(object_path),'
            'thumbnail_media_assets:media_assets!listing_videos_thumbnail_media_id_fkey(object_path)),'
            'listing_images(id,image_url,media_id,sort_order,media_assets(bucket,object_path))',
          )
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1),
    );
    return rows.map((row) {
      final value = _json(row);
      final videos = _relationRows(value['listing_videos']);
      value['listing_video'] = videos.isEmpty ? null : videos.first;
      value.remove('listing_videos');
      value['images'] = _listingImageUrls(client, value['listing_images']);
      value.remove('listing_images');
      return value;
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> stores({
    int page = 0,
    int pageSize = 50,
  }) async {
    _guard();
    final rows = await _timed(
      'stores.page_1',
      () => client
          .from('stores')
          .select(
            'id,owner_id,name,description,logo_media_id,cover_media_id,category_id,'
            'phone,viber_phone,city,status,is_promoted,created_at,'
            'latitude,longitude,logo_media:media_assets!stores_logo_media_id_fkey(bucket,object_path)',
          )
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1),
    );
    return rows.map((row) {
      final value = _json(row);
      final media = value['logo_media'];
      if (media is Map) {
        final asset = _json(media);
        final bucket = '${asset['bucket'] ?? ''}';
        final path = '${asset['object_path'] ?? ''}';
        if (bucket.isNotEmpty && path.isNotEmpty) {
          value['logo_url'] = client.storage.from(bucket).getPublicUrl(path);
        }
      }
      return value;
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> reports({
    int page = 0,
    int pageSize = 50,
  }) async {
    _guard();
    return (await _timed(
      'reports.page_1',
      () => client
          .from('reports')
          .select('id,listing_id,store_id,reason,status,created_at')
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1),
    )).map((row) {
      final value = _json(row);
      value['target_id'] = value['listing_id'] ?? value['store_id'];
      value['type'] = value['listing_id'] == null ? 'store' : 'listing';
      value['reviewed'] = value['status'] != 'pending';
      return value;
    }).toList();
  }

  @override
  Future<Map<String, int>> summary() async {
    _guard();
    final values = await Future.wait<int>([
      _timed(
        'summary.profiles',
        () => client.from('profiles').count(CountOption.exact),
      ),
      _timed(
        'summary.general_listings',
        () => client
            .from('listings')
            .count(CountOption.exact)
            .eq('listing_type', 'general'),
      ),
      _timed(
        'summary.store_products',
        () => client
            .from('listings')
            .count(CountOption.exact)
            .eq('listing_type', 'store'),
      ),
      _timed(
        'summary.stores',
        () => client.from('stores').count(CountOption.exact),
      ),
      _timed(
        'summary.reports',
        () => client.from('reports').count(CountOption.exact),
      ),
      _timed(
        'summary.pending_stores',
        () => client
            .from('stores')
            .count(CountOption.exact)
            .eq('status', 'pending'),
      ),
      _timed(
        'summary.pending_reports',
        () => client
            .from('reports')
            .count(CountOption.exact)
            .eq('workflow_status', 'pending'),
      ),
    ]);
    return {
      'users': values[0],
      'listings': values[1],
      'store_products': values[2],
      'stores': values[3],
      'reports': values[4],
      'pending_stores': values[5],
      'pending_reports': values[6],
    };
  }

  @override
  Future<Map<String, dynamic>> analytics(String period) async {
    _guard();
    final value = await _timed(
      'analytics.$period',
      () => client.rpc('admin_analytics', params: {'p_period': period}),
    );
    return _json(value);
  }

  @override
  Future<List<Map<String, dynamic>>> storeEditRequests() async {
    _guard();
    return (await _timed(
      'store_edit_requests.page_1',
      () => client
          .from('store_edit_requests')
          .select(
            'id,store_id,owner_id,before_snapshot,proposed_changes,status,created_at',
          )
          .order('created_at', ascending: false)
          .range(0, 99),
    )).map(_json).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> promotionRequests() async {
    _guard();
    return (await _timed(
      'promotion_requests.page_1',
      () => client
          .from('promotion_requests')
          .select('id,store_id,owner_id,status,created_at')
          .order('created_at', ascending: false)
          .range(0, 99),
    )).map(_json).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> adminNotifications() async {
    _guard();
    return (await _timed(
      'admin_notifications.page_1',
      () => client
          .from('admin_notifications')
          .select('id,type,shop_id,listing_id,title,message,is_read,created_at')
          .order('created_at', ascending: false)
          .range(0, 99),
    )).map(_json).toList();
  }

  @override
  Future<void> markAdminNotificationRead(String id) async {
    _guard();
    await client
        .from('admin_notifications')
        .update({'is_read': true})
        .eq('id', id);
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
