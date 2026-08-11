class UserProfile {
  final String id, name, phone, email, avatar;
  final DateTime createdAt;
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.avatar = '',
    required this.createdAt,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'avatar': avatar,
    'created_at': createdAt.toIso8601String(),
  };
  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    id: '${j['id']}',
    name: '${j['name'] ?? ''}',
    phone: '${j['phone'] ?? ''}',
    email: '${j['email'] ?? ''}',
    avatar: '${j['avatar'] ?? ''}',
    createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
  );
}

class CategoryRecord {
  final String id, type, nameTh, nameShn, nameEn, nameMy;
  final bool isActive;
  final int sortOrder;
  const CategoryRecord({
    required this.id,
    required this.type,
    required this.nameTh,
    required this.nameShn,
    required this.nameEn,
    required this.nameMy,
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
    isActive: json['is_active'] != false,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
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
  final String? storeId;
  final double? latitude, longitude;
  final bool isLocationVisible;
  final double price;
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
    required this.images,
    required this.phone,
    required this.viber,
    required this.createdAt,
    required this.updatedAt,
    this.storeId,
    this.latitude,
    this.longitude,
    this.isLocationVisible = true,
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
    'status': status,
    'images': images,
    'phone': phone,
    'viber_phone': viber,
    'likes': likes,
    'views': views,
    'latitude': latitude,
    'longitude': longitude,
    'is_location_visible': isLocationVisible,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_published': true,
  };
  factory ListingRecord.fromJson(Map<String, dynamic> j) => ListingRecord(
    id: '${j['id']}',
    ownerId: '${j['owner_id'] ?? ''}',
    storeId: j['store_id']?.toString(),
    title: '${j['title'] ?? ''}',
    description: '${j['description'] ?? ''}',
    category: '${j['category'] ?? ''}',
    price: (j['price'] as num?)?.toDouble() ?? 0,
    currency: '${j['currency'] ?? 'MMK'}',
    city: '${j['city'] ?? ''}',
    status: '${j['status'] ?? 'available'}',
    images: List<String>.from(j['images'] ?? const []),
    phone: '${j['phone'] ?? ''}',
    viber: '${j['viber_phone'] ?? ''}',
    likes: (j['likes'] as num?)?.toInt() ?? 0,
    views: (j['views'] as num?)?.toInt() ?? 0,
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    isLocationVisible: j['is_location_visible'] != false,
    createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
    updatedAt: DateTime.tryParse('${j['updated_at']}') ?? DateTime.now(),
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
  final double? latitude, longitude;
  final DateTime createdAt;
  final bool isPromoted;
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
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.isPromoted = false,
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
    location: '${j['location'] ?? ''}',
    openingHours:
        '${j['opening_hours'] ?? '${j['opening_time'] ?? ''}-${j['closing_time'] ?? ''}'}',
    status: '${j['status'] ?? 'approved'}',
    email: '${j['email'] ?? ''}',
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
    isPromoted: j['is_promoted'] == true,
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
