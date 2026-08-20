class UserProfile {
  final String id, name, phone, email, avatar, city, viber;
  final String? cityId;
  final DateTime createdAt;
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.avatar = '',
    this.city = '',
    this.viber = '',
    this.cityId,
    required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'avatar': avatar,
    'city': city,
    'city_id': cityId,
    'viber_phone': viber,
    'created_at': createdAt.toIso8601String(),
  };
  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: '${j['id']}',
    name: '${j['name'] ?? ''}',
    phone: '${j['phone'] ?? ''}',
    email: '${j['email'] ?? ''}',
    avatar: '${j['avatar'] ?? ''}',
    city: '${j['city'] ?? ''}',
    cityId: j['city_id']?.toString(),
    viber: '${j['viber_phone'] ?? ''}',
    createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
  );
}

class CategoryRecord {
  final String id, type, nameTh, nameShn, nameEn, nameMy, iconKey;
  final bool isActive;
  final int sortOrder;
  const CategoryRecord({
    required this.id,
    required this.type,
    required this.nameTh,
    required this.nameShn,
    required this.nameEn,
    required this.nameMy,
    this.iconKey = 'category',
    this.isActive = true,
    required this.sortOrder,
  });

  String localizedName(String localeCode) => switch (localeCode) {
    'shn' => nameShn,
    'en' => nameEn,
    'my' => nameMy,
    _ => nameTh,
  };

  bool matches(String value) =>
      value == id ||
      value == nameTh ||
      value == nameShn ||
      value == nameEn ||
      value == nameMy;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'name_th': nameTh,
    'name_shn': nameShn,
    'name_en': nameEn,
    'name_my': nameMy,
    'icon_key': iconKey,
    'is_active': isActive,
    'sort_order': sortOrder,
  };

  factory CategoryRecord.fromJson(Map<String, dynamic> json) => CategoryRecord(
    id: '${json['id']}',
    type: '${json['type']}',
    nameTh: '${json['name_th'] ?? ''}',
    nameShn: '${json['name_shn'] ?? ''}',
    nameEn: '${json['name_en'] ?? ''}',
    nameMy: '${json['name_my'] ?? ''}',
    iconKey: '${json['icon_key'] ?? ''}'.trim().isEmpty
        ? 'category'
        : '${json['icon_key']}'.trim(),
    isActive: json['is_active'] != false,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  );
}

class CityRecord {
  final String id, name, nameTh, nameShn, nameEn, nameMy;
  final bool isActive;
  final double? latitude, longitude;

  const CityRecord({
    required this.id,
    required this.name,
    this.nameTh = '',
    this.nameShn = '',
    this.nameEn = '',
    this.nameMy = '',
    this.isActive = true,
    this.latitude,
    this.longitude,
  });

  String localizedName(String localeCode) {
    final translated = switch (localeCode) {
      'th' => nameTh,
      'shn' => nameShn,
      'my' => nameMy,
      'en' => nameEn,
      _ => '',
    };
    if (translated.trim().isNotEmpty) return translated.trim();
    if (nameEn.trim().isNotEmpty) return nameEn.trim();
    return name.trim();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_th': nameTh,
    'name_shn': nameShn,
    'name_en': nameEn,
    'name_my': nameMy,
    'is_active': isActive,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory CityRecord.fromJson(Map<String, dynamic> json) => CityRecord(
    id: '${json['id']}',
    name: '${json['name'] ?? ''}',
    nameTh: '${json['name_th'] ?? ''}',
    nameShn: '${json['name_shn'] ?? ''}',
    nameEn: '${json['name_en'] ?? ''}',
    nameMy: '${json['name_my'] ?? ''}',
    isActive: json['is_active'] != false,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}

class ListingRecord {
  final String id,
      ownerId,
      title,
      description,
      category,
      currency,
      city,
      status,
      phone,
      viber;
  final String? storeId, cityId;
  final CityRecord? cityRecord;
  final double? latitude, longitude;
  final bool isLocationVisible;
  final bool isPublished, isHidden;
  final DateTime? deletedAt;
  final double price;

  final ListingVideoRecord? video;
  final List<String> images;
  final int likes, views;
  final DateTime createdAt, updatedAt;
  const ListingRecord({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.currency,
    required this.city,
    required this.status,
    this.video,
    this.images = const [],
    required this.phone,
    required this.viber,
    required this.createdAt,
    required this.updatedAt,
    this.storeId,
    this.cityId,
    this.cityRecord,
    this.latitude,
    this.longitude,
    this.isLocationVisible = true,
    this.isPublished = true,
    this.isHidden = false,
    this.deletedAt,
    this.likes = 0,
    this.views = 0,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'store_id': storeId,
    'title': title,
    'description': description,
    'category': category,
    'price': price,
    'currency': currency,
    'city': city,
    'city_id': cityId,
    if (cityRecord != null) 'cities': cityRecord!.toJson(),
    'status': status,
    if (video != null) 'listing_video': video!.toJson(),
    'images': images,
    'phone': phone,
    'viber_phone': viber,
    'likes': likes,
    'views': views,
    'latitude': latitude,
    'longitude': longitude,
    'is_location_visible': isLocationVisible,
    'is_published': isPublished,
    'is_hidden': isHidden,
    'deleted_at': deletedAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
  factory ListingRecord.fromJson(Map<String, dynamic> j) => ListingRecord(
    id: '${j['id']}',
    ownerId: '${j['owner_id'] ?? ''}',
    storeId: j['store_id']?.toString(),
    cityId: j['city_id']?.toString(),
    cityRecord: j['cities'] is Map
        ? CityRecord.fromJson(Map<String, dynamic>.from(j['cities'] as Map))
        : null,
    title: '${j['title'] ?? ''}',
    description: '${j['description'] ?? ''}',
    category: '${j['category'] ?? ''}',
    price: (j['price'] as num?)?.toDouble() ?? 0,
    currency: '${j['currency'] ?? 'MMK'}',
    city: '${j['city'] ?? ''}',
    status: '${j['status'] ?? 'available'}',
    video: j['listing_video'] is Map
        ? ListingVideoRecord.fromJson(
            Map<String, dynamic>.from(j['listing_video'] as Map),
          )
        : null,
    images: List<String>.from(j['images'] ?? const []),
    phone: '${j['phone'] ?? ''}',
    viber: '${j['viber_phone'] ?? ''}',
    likes: (j['likes'] as num?)?.toInt() ?? 0,
    views: (j['views'] as num?)?.toInt() ?? 0,
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    isLocationVisible: j['is_location_visible'] != false,
    isPublished: j['is_published'] == true,
    isHidden: j['is_hidden'] == true,
    deletedAt: DateTime.tryParse('${j['deleted_at']}'),
    createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
    updatedAt: DateTime.tryParse('${j['updated_at']}') ?? DateTime.now(),
  );
}

/// Metadata only; video and thumbnail bytes always remain in Object Storage.
class ListingVideoRecord {
  final String id;
  final String videoMediaId;
  final String thumbnailMediaId;
  final String videoPath;
  final String thumbnailPath;
  final int durationMilliseconds;
  final int sizeBytes;

  const ListingVideoRecord({
    required this.id,
    required this.videoMediaId,
    required this.thumbnailMediaId,
    required this.videoPath,
    required this.thumbnailPath,
    required this.durationMilliseconds,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'video_media_id': videoMediaId,
    'thumbnail_media_id': thumbnailMediaId,
    'video_path': videoPath,
    'thumbnail_path': thumbnailPath,
    'duration_milliseconds': durationMilliseconds,
    'size_bytes': sizeBytes,
  };

  factory ListingVideoRecord.fromJson(
    Map<String, dynamic> json,
  ) => ListingVideoRecord(
    id: '${json['id'] ?? ''}',
    videoMediaId: '${json['video_media_id'] ?? ''}',
    thumbnailMediaId: '${json['thumbnail_media_id'] ?? ''}',
    videoPath:
        '${json['video_path'] ?? json['video_media_assets']?['object_path'] ?? ''}',
    thumbnailPath:
        '${json['thumbnail_path'] ?? json['thumbnail_media_assets']?['object_path'] ?? ''}',
    durationMilliseconds: (json['duration_milliseconds'] as num?)?.toInt() ?? 0,
    sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
  );
}

class StoreRecord {
  final String id,
      ownerId,
      name,
      logo,
      cover,
      description,
      category,
      phone,
      viber,
      city,
      location,
      openingHours,
      status;
  final String email;
  final String? cityId;
  final CityRecord? cityRecord;
  final double? latitude, longitude;
  final DateTime createdAt;
  final bool isPromoted;
  final String lifecycleStatus;
  final bool isHidden;
  final DateTime? deletedAt;
  final DateTime? promotionStartAt, promotionEndAt;
  const StoreRecord({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.logo,
    this.cover = '',
    required this.description,
    required this.category,
    required this.phone,
    required this.viber,
    required this.city,
    required this.location,
    required this.openingHours,
    required this.status,
    this.email = '',
    this.cityId,
    this.cityRecord,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.isPromoted = false,
    this.lifecycleStatus = 'active',
    this.isHidden = false,
    this.deletedAt,
    this.promotionStartAt,
    this.promotionEndAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'owner_id': ownerId,
    'name': name,
    'logo_url': logo,
    'cover_url': cover,
    'description': description,
    'category': category,
    'phone': phone,
    'viber_phone': viber,
    'city': city,
    'city_id': cityId,
    if (cityRecord != null) 'cities': cityRecord!.toJson(),
    'location': location,
    'opening_hours': openingHours,
    'opening_time': openingHours.split('-').first.trim(),
    'closing_time': openingHours.split('-').last.trim(),
    'status': status,
    'email': email,
    'latitude': latitude,
    'longitude': longitude,
    'created_at': createdAt.toIso8601String(),
    'is_promoted': isPromoted,
    'lifecycle_status': lifecycleStatus,
    'is_hidden': isHidden,
    'deleted_at': deletedAt?.toIso8601String(),
    'promotion_start_at': promotionStartAt?.toIso8601String(),
    'promotion_end_at': promotionEndAt?.toIso8601String(),
  };
  factory StoreRecord.fromJson(Map<String, dynamic> j) => StoreRecord(
    id: '${j['id']}',
    ownerId: '${j['owner_id'] ?? ''}',
    name: '${j['name'] ?? ''}',
    logo: '${j['logo_url'] ?? ''}',
    cover: '${j['cover_url'] ?? ''}',
    description: '${j['description'] ?? ''}',
    category: '${j['category'] ?? ''}',
    phone: '${j['phone'] ?? ''}',
    viber: '${j['viber_phone'] ?? ''}',
    city: '${j['city'] ?? ''}',
    cityId: j['city_id']?.toString(),
    cityRecord: j['cities'] is Map
        ? CityRecord.fromJson(Map<String, dynamic>.from(j['cities'] as Map))
        : null,
    location: '${j['location'] ?? ''}',
    openingHours:
        '${j['opening_hours'] ?? '${j['opening_time'] ?? ''}-${j['closing_time'] ?? ''}'}',
    status: '${j['status'] ?? 'approved'}',
    email: '${j['email'] ?? ''}',
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
    isPromoted: j['is_promoted'] == true,
    lifecycleStatus: '${j['lifecycle_status'] ?? ''}',
    isHidden: j['is_hidden'] == true,
    deletedAt: DateTime.tryParse('${j['deleted_at']}'),
    promotionStartAt: DateTime.tryParse('${j['promotion_start_at']}'),
    promotionEndAt: DateTime.tryParse('${j['promotion_end_at']}'),
  );
}

class StoreEditRequestRecord {
  final String id, storeId, ownerId, status;
  final Map<String, dynamic> proposedChanges;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  const StoreEditRequestRecord({
    required this.id,
    required this.storeId,
    required this.ownerId,
    required this.proposedChanges,
    this.status = 'pending',
    required this.createdAt,
    this.reviewedAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'store_id': storeId,
    'owner_id': ownerId,
    'proposed_changes': proposedChanges,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'reviewed_at': reviewedAt?.toIso8601String(),
  };
}

class PromotionRequestRecord {
  final String id, storeId, ownerId, status;
  final DateTime createdAt;
  final DateTime? requestedStartAt, requestedEndAt, reviewedAt;
  const PromotionRequestRecord({
    required this.id,
    required this.storeId,
    required this.ownerId,
    this.status = 'pending',
    required this.createdAt,
    this.requestedStartAt,
    this.requestedEndAt,
    this.reviewedAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'store_id': storeId,
    'owner_id': ownerId,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'requested_start_at': requestedStartAt?.toIso8601String(),
    'requested_end_at': requestedEndAt?.toIso8601String(),
    'reviewed_at': reviewedAt?.toIso8601String(),
  };
}

class ReportRecord {
  final String id, reason, targetId, type;
  final DateTime createdAt;
  const ReportRecord({
    required this.id,
    required this.reason,
    required this.targetId,
    required this.type,
    required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'reason': reason,
    'target_id': targetId,
    'type': type,
    'created_at': createdAt.toIso8601String(),
  };
}

class NotificationRecord {
  final String id, eventType;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  const NotificationRecord({
    required this.id,
    required this.eventType,
    required this.payload,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationRecord.fromJson(Map<String, dynamic> json) =>
      NotificationRecord(
        id: '${json['id']}',
        eventType: '${json['event_type'] ?? ''}',
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
        isRead: json['is_read'] == true,
        createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
        readAt: DateTime.tryParse('${json['read_at']}'),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'event_type': eventType,
    'payload': payload,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
    'read_at': readAt?.toIso8601String(),
  };
}

class AdvertisementRecord {
  final String id, title, imageUrl, targetType;
  final String? targetId, externalUrl;
  final DateTime? startAt, endAt;
  final int displayOrder;
  final bool isActive;
  final DateTime createdAt, updatedAt;

  const AdvertisementRecord({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.targetType,
    this.targetId,
    this.externalUrl,
    this.startAt,
    this.endAt,
    this.displayOrder = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isCurrentlyVisible {
    final now = DateTime.now().toUtc();
    return isActive &&
        (startAt == null || !now.isBefore(startAt!.toUtc())) &&
        (endAt == null || !now.isAfter(endAt!.toUtc()));
  }

  factory AdvertisementRecord.fromJson(Map<String, dynamic> json) =>
      AdvertisementRecord(
        id: '${json['id']}',
        title: '${json['title'] ?? ''}',
        imageUrl: '${json['image_url'] ?? ''}',
        targetType: '${json['target_type'] ?? 'external'}',
        targetId: json['target_id']?.toString(),
        externalUrl: (json['external_url'] ?? json['target_url'])?.toString(),
        startAt: DateTime.tryParse('${json['start_at']}'),
        endAt: DateTime.tryParse('${json['end_at']}'),
        displayOrder:
            (json['display_order'] as num?)?.toInt() ??
            (json['sort_order'] as num?)?.toInt() ??
            0,
        isActive: json['is_active'] ?? json['active'] ?? true,
        createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
        updatedAt: DateTime.tryParse('${json['updated_at']}') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'image_url': imageUrl,
    'target_type': targetType,
    'target_id': targetId,
    'external_url': externalUrl,
    'target_url': externalUrl,
    'start_at': startAt?.toUtc().toIso8601String(),
    'end_at': endAt?.toUtc().toIso8601String(),
    'display_order': displayOrder,
    'is_active': isActive,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}

class ShortVideoRecord {
  final String id, tiktokUrl, title;
  final int displayOrder;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt, updatedAt;

  const ShortVideoRecord({
    required this.id,
    required this.tiktokUrl,
    this.title = '',
    this.displayOrder = 0,
    this.isActive = true,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  static bool isValidTikTokUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    final host = uri?.host.toLowerCase() ?? '';
    return uri?.scheme == 'https' &&
        (host == 'tiktok.com' || host.endsWith('.tiktok.com'));
  }

  factory ShortVideoRecord.fromJson(Map<String, dynamic> json) =>
      ShortVideoRecord(
        id: '${json['id']}',
        tiktokUrl: '${json['tiktok_url'] ?? ''}',
        title: '${json['title'] ?? ''}',
        displayOrder:
            (json['sort_order'] as num?)?.toInt() ??
            (json['display_order'] as num?)?.toInt() ??
            0,
        isActive: json['is_active'] == true,
        createdBy: json['created_by']?.toString(),
        createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
        updatedAt: DateTime.tryParse('${json['updated_at']}') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tiktok_url': tiktokUrl,
    'title': title,
    'sort_order': displayOrder,
    'is_active': isActive,
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
