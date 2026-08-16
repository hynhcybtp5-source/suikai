import 'package:flutter/material.dart';

class CategoryIconOption {
  final String key, group, keywords;
  final IconData icon;
  const CategoryIconOption(
    this.key,
    this.group,
    this.icon, [
    this.keywords = '',
  ]);

  bool matches(String query) {
    final value = query.trim().toLowerCase();
    return value.isEmpty ||
        key.toLowerCase().contains(value) ||
        group.toLowerCase().contains(value) ||
        keywords.toLowerCase().contains(value);
  }
}

/// Stable Material icon identifiers persisted in Supabase. Categories refer to
/// these identifiers and never rely on their names or Flutter code points.
const categoryIconCatalog = <CategoryIconOption>[
  CategoryIconOption(
    'restaurant',
    'Food',
    Icons.restaurant_outlined,
    'food ร้านอาหาร',
  ),
  CategoryIconOption('fastfood', 'Food', Icons.fastfood_outlined, 'meal อาหาร'),
  CategoryIconOption(
    'local_cafe',
    'Food',
    Icons.local_cafe_outlined,
    'coffee cafe กาแฟ',
  ),
  CategoryIconOption(
    'bakery_dining',
    'Food',
    Icons.bakery_dining_outlined,
    'bread bakery ขนมปัง',
  ),
  CategoryIconOption(
    'local_pizza',
    'Food',
    Icons.local_pizza_outlined,
    'pizza',
  ),
  CategoryIconOption(
    'agriculture',
    'Agriculture',
    Icons.agriculture_outlined,
    'farm เกษตร',
  ),
  CategoryIconOption('grass', 'Agriculture', Icons.grass_outlined, 'plant พืช'),
  CategoryIconOption(
    'compost',
    'Agriculture',
    Icons.compost_outlined,
    'organic fertilizer',
  ),
  CategoryIconOption(
    'forest',
    'Agriculture',
    Icons.forest_outlined,
    'tree ป่า ไม้',
  ),
  CategoryIconOption(
    'water_drop',
    'Agriculture',
    Icons.water_drop_outlined,
    'water irrigation น้ำ',
  ),
  CategoryIconOption(
    'construction',
    'Construction',
    Icons.construction_outlined,
    'build ก่อสร้าง',
  ),
  CategoryIconOption(
    'engineering',
    'Construction',
    Icons.engineering_outlined,
    'engineer วิศวกร',
  ),
  CategoryIconOption(
    'hardware',
    'Construction',
    Icons.hardware_outlined,
    'tools เครื่องมือ',
  ),
  CategoryIconOption(
    'foundation',
    'Construction',
    Icons.foundation_outlined,
    'building อาคาร',
  ),
  CategoryIconOption(
    'architecture',
    'Construction',
    Icons.architecture_outlined,
    'design แบบ',
  ),
  CategoryIconOption(
    'directions_car',
    'Automotive',
    Icons.directions_car_outlined,
    'car รถยนต์',
  ),
  CategoryIconOption(
    'two_wheeler',
    'Automotive',
    Icons.two_wheeler_outlined,
    'motorcycle มอเตอร์ไซค์',
  ),
  CategoryIconOption(
    'local_gas_station',
    'Automotive',
    Icons.local_gas_station_outlined,
    'fuel น้ำมัน',
  ),
  CategoryIconOption(
    'car_repair',
    'Automotive',
    Icons.car_repair_outlined,
    'garage ซ่อมรถ',
  ),
  CategoryIconOption(
    'electric_car',
    'Automotive',
    Icons.electric_car_outlined,
    'ev vehicle',
  ),
  CategoryIconOption('build', 'Repair', Icons.build_outlined, 'repair ซ่อม'),
  CategoryIconOption(
    'handyman',
    'Repair',
    Icons.handyman_outlined,
    'technician ช่าง',
  ),
  CategoryIconOption(
    'home_repair_service',
    'Repair',
    Icons.home_repair_service_outlined,
    'maintenance',
  ),
  CategoryIconOption(
    'plumbing',
    'Repair',
    Icons.plumbing_outlined,
    'pipe ประปา',
  ),
  CategoryIconOption(
    'electrical_services',
    'Repair',
    Icons.electrical_services_outlined,
    'electric ไฟฟ้า',
  ),
  CategoryIconOption(
    'devices',
    'Electronics',
    Icons.devices_outlined,
    'electronics อิเล็กทรอนิกส์',
  ),
  CategoryIconOption(
    'phone_android',
    'Electronics',
    Icons.phone_android_outlined,
    'mobile โทรศัพท์',
  ),
  CategoryIconOption(
    'computer',
    'Electronics',
    Icons.computer_outlined,
    'pc laptop คอมพิวเตอร์',
  ),
  CategoryIconOption('tv', 'Electronics', Icons.tv_outlined, 'television'),
  CategoryIconOption(
    'memory',
    'Electronics',
    Icons.memory_outlined,
    'chip component',
  ),
  CategoryIconOption(
    'checkroom',
    'Fashion',
    Icons.checkroom_outlined,
    'clothes เสื้อผ้า',
  ),
  CategoryIconOption(
    'shopping_bag',
    'Fashion',
    Icons.shopping_bag_outlined,
    'bag กระเป๋า',
  ),
  CategoryIconOption('watch', 'Fashion', Icons.watch_outlined, 'นาฬิกา'),
  CategoryIconOption(
    'diamond',
    'Fashion',
    Icons.diamond_outlined,
    'jewelry เครื่องประดับ',
  ),
  CategoryIconOption(
    'dry_cleaning',
    'Fashion',
    Icons.dry_cleaning_outlined,
    'garment',
  ),
  CategoryIconOption(
    'beauty',
    'Beauty',
    Icons.face_retouching_natural_outlined,
    'salon ความงาม',
  ),
  CategoryIconOption('spa', 'Beauty', Icons.spa_outlined, 'massage นวด'),
  CategoryIconOption(
    'content_cut',
    'Beauty',
    Icons.content_cut_outlined,
    'hair haircut ตัดผม',
  ),
  CategoryIconOption(
    'brush',
    'Beauty',
    Icons.brush_outlined,
    'makeup cosmetic',
  ),
  CategoryIconOption(
    'self_improvement',
    'Beauty',
    Icons.self_improvement_outlined,
    'wellness yoga',
  ),
  CategoryIconOption(
    'local_hospital',
    'Health',
    Icons.local_hospital_outlined,
    'hospital โรงพยาบาล',
  ),
  CategoryIconOption(
    'medical_services',
    'Health',
    Icons.medical_services_outlined,
    'clinic คลินิก',
  ),
  CategoryIconOption(
    'medication',
    'Health',
    Icons.medication_outlined,
    'pharmacy medicine ยา',
  ),
  CategoryIconOption(
    'health_and_safety',
    'Health',
    Icons.health_and_safety_outlined,
    'health สุขภาพ',
  ),
  CategoryIconOption(
    'fitness_center',
    'Health',
    Icons.fitness_center_outlined,
    'gym exercise',
  ),
  CategoryIconOption(
    'school',
    'Education',
    Icons.school_outlined,
    'school การศึกษา',
  ),
  CategoryIconOption(
    'book',
    'Education',
    Icons.menu_book_outlined,
    'book หนังสือ',
  ),
  CategoryIconOption(
    'science',
    'Education',
    Icons.science_outlined,
    'lab วิทยาศาสตร์',
  ),
  CategoryIconOption(
    'calculate',
    'Education',
    Icons.calculate_outlined,
    'math บัญชี',
  ),
  CategoryIconOption(
    'language',
    'Education',
    Icons.language_outlined,
    'language ภาษา',
  ),
  CategoryIconOption(
    'code',
    'IT',
    Icons.code_outlined,
    'software developer โปรแกรม',
  ),
  CategoryIconOption(
    'terminal',
    'IT',
    Icons.terminal_outlined,
    'command developer',
  ),
  CategoryIconOption(
    'storage',
    'IT',
    Icons.storage_outlined,
    'database server',
  ),
  CategoryIconOption('cloud', 'IT', Icons.cloud_outlined, 'hosting internet'),
  CategoryIconOption('router', 'IT', Icons.router_outlined, 'network wifi'),
  CategoryIconOption(
    'business_center',
    'Business',
    Icons.business_center_outlined,
    'business ธุรกิจ',
  ),
  CategoryIconOption(
    'storefront',
    'Business',
    Icons.storefront_outlined,
    'shop ร้านค้า',
  ),
  CategoryIconOption(
    'inventory_2',
    'Business',
    Icons.inventory_2_outlined,
    'warehouse stock',
  ),
  CategoryIconOption(
    'point_of_sale',
    'Business',
    Icons.point_of_sale_outlined,
    'pos retail',
  ),
  CategoryIconOption(
    'corporate_fare',
    'Business',
    Icons.corporate_fare_outlined,
    'company office',
  ),
  CategoryIconOption(
    'account_balance',
    'Finance',
    Icons.account_balance_outlined,
    'bank finance ธนาคาร',
  ),
  CategoryIconOption(
    'payments',
    'Finance',
    Icons.payments_outlined,
    'money payment เงิน',
  ),
  CategoryIconOption(
    'savings',
    'Finance',
    Icons.savings_outlined,
    'saving piggy',
  ),
  CategoryIconOption(
    'currency_exchange',
    'Finance',
    Icons.currency_exchange_outlined,
    'exchange แลกเงิน',
  ),
  CategoryIconOption(
    'receipt_long',
    'Finance',
    Icons.receipt_long_outlined,
    'tax invoice',
  ),
  CategoryIconOption('home', 'Property', Icons.home_outlined, 'house บ้าน'),
  CategoryIconOption(
    'apartment',
    'Property',
    Icons.apartment_outlined,
    'condo building',
  ),
  CategoryIconOption(
    'real_estate_agent',
    'Property',
    Icons.real_estate_agent_outlined,
    'property estate',
  ),
  CategoryIconOption(
    'landscape',
    'Property',
    Icons.landscape_outlined,
    'land ที่ดิน',
  ),
  CategoryIconOption(
    'warehouse',
    'Property',
    Icons.warehouse_outlined,
    'storage property',
  ),
  CategoryIconOption(
    'local_shipping',
    'Transport',
    Icons.local_shipping_outlined,
    'truck delivery ขนส่ง',
  ),
  CategoryIconOption(
    'directions_bus',
    'Transport',
    Icons.directions_bus_outlined,
    'bus รถโดยสาร',
  ),
  CategoryIconOption(
    'local_taxi',
    'Transport',
    Icons.local_taxi_outlined,
    'taxi',
  ),
  CategoryIconOption('train', 'Transport', Icons.train_outlined, 'rail รถไฟ'),
  CategoryIconOption(
    'flight',
    'Transport',
    Icons.flight_outlined,
    'air plane เครื่องบิน',
  ),
  CategoryIconOption(
    'travel_explore',
    'Travel',
    Icons.travel_explore_outlined,
    'travel ท่องเที่ยว',
  ),
  CategoryIconOption('luggage', 'Travel', Icons.luggage_outlined, 'trip bag'),
  CategoryIconOption('map', 'Travel', Icons.map_outlined, 'tour แผนที่'),
  CategoryIconOption(
    'beach_access',
    'Travel',
    Icons.beach_access_outlined,
    'beach holiday',
  ),
  CategoryIconOption('hiking', 'Travel', Icons.hiking_outlined, 'trek outdoor'),
  CategoryIconOption('hotel', 'Hotel', Icons.hotel_outlined, 'hotel โรงแรม'),
  CategoryIconOption('bed', 'Hotel', Icons.bed_outlined, 'room accommodation'),
  CategoryIconOption(
    'meeting_room',
    'Hotel',
    Icons.meeting_room_outlined,
    'room',
  ),
  CategoryIconOption(
    'room_service',
    'Hotel',
    Icons.room_service_outlined,
    'service',
  ),
  CategoryIconOption('pool', 'Hotel', Icons.pool_outlined, 'resort swimming'),
  CategoryIconOption(
    'movie',
    'Entertainment',
    Icons.movie_outlined,
    'cinema ภาพยนตร์',
  ),
  CategoryIconOption(
    'music_note',
    'Entertainment',
    Icons.music_note_outlined,
    'music เพลง',
  ),
  CategoryIconOption(
    'sports_esports',
    'Entertainment',
    Icons.sports_esports_outlined,
    'game gaming',
  ),
  CategoryIconOption(
    'theater_comedy',
    'Entertainment',
    Icons.theater_comedy_outlined,
    'show theater',
  ),
  CategoryIconOption(
    'celebration',
    'Entertainment',
    Icons.celebration_outlined,
    'party event',
  ),
  CategoryIconOption(
    'work',
    'Professional Services',
    Icons.work_outline,
    'career job อาชีพ',
  ),
  CategoryIconOption(
    'gavel',
    'Professional Services',
    Icons.gavel_outlined,
    'law lawyer กฎหมาย',
  ),
  CategoryIconOption(
    'design_services',
    'Professional Services',
    Icons.design_services_outlined,
    'designer',
  ),
  CategoryIconOption(
    'translate',
    'Professional Services',
    Icons.translate_outlined,
    'translation แปล',
  ),
  CategoryIconOption(
    'campaign',
    'Professional Services',
    Icons.campaign_outlined,
    'marketing advertising',
  ),
  CategoryIconOption(
    'home_services',
    'Home Services',
    Icons.home_work_outlined,
    'home service บ้าน',
  ),
  CategoryIconOption(
    'yard',
    'Home Services',
    Icons.yard_outlined,
    'garden gardening สวน',
  ),
  CategoryIconOption(
    'ac_unit',
    'Home Services',
    Icons.ac_unit_outlined,
    'air conditioning แอร์',
  ),
  CategoryIconOption(
    'pest_control',
    'Home Services',
    Icons.pest_control_outlined,
    'pest แมลง',
  ),
  CategoryIconOption(
    'delivery_dining',
    'Home Services',
    Icons.delivery_dining_outlined,
    'delivery ส่ง',
  ),
  CategoryIconOption(
    'security',
    'Security',
    Icons.security_outlined,
    'security รักษาความปลอดภัย',
  ),
  CategoryIconOption('shield', 'Security', Icons.shield_outlined, 'protection'),
  CategoryIconOption(
    'lock',
    'Security',
    Icons.lock_outline,
    'lock locksmith กุญแจ',
  ),
  CategoryIconOption(
    'videocam',
    'Security',
    Icons.videocam_outlined,
    'cctv camera',
  ),
  CategoryIconOption(
    'verified_user',
    'Security',
    Icons.verified_user_outlined,
    'guard verify',
  ),
  CategoryIconOption(
    'cleaning_services',
    'Cleaning',
    Icons.cleaning_services_outlined,
    'clean ทำความสะอาด',
  ),
  CategoryIconOption(
    'local_laundry_service',
    'Cleaning',
    Icons.local_laundry_service_outlined,
    'laundry ซักรีด',
  ),
  CategoryIconOption('wash', 'Cleaning', Icons.wash_outlined, 'washing'),
  CategoryIconOption(
    'delete_sweep',
    'Cleaning',
    Icons.delete_sweep_outlined,
    'waste garbage',
  ),
  CategoryIconOption('soap', 'Cleaning', Icons.soap_outlined, 'hygiene'),
  CategoryIconOption('pets', 'Pets', Icons.pets_outlined, 'pet สัตว์เลี้ยง'),
  CategoryIconOption(
    'cruelty_free',
    'Pets',
    Icons.cruelty_free_outlined,
    'rabbit animal',
  ),
  CategoryIconOption(
    'set_meal',
    'Pets',
    Icons.set_meal_outlined,
    'fish อาหารสัตว์',
  ),
  CategoryIconOption('park', 'Pets', Icons.park_outlined, 'nature animal'),
  CategoryIconOption(
    'category',
    'General',
    Icons.category,
    'general category ทั่วไป',
  ),
  CategoryIconOption('more_horiz', 'General', Icons.more_horiz, 'other อื่นๆ'),
  CategoryIconOption(
    'public',
    'General',
    Icons.public_outlined,
    'world global',
  ),
  CategoryIconOption(
    'location_on',
    'General',
    Icons.location_on_outlined,
    'place location',
  ),
  CategoryIconOption('event', 'General', Icons.event_outlined, 'calendar date'),
  CategoryIconOption(
    'people',
    'General',
    Icons.people_outline,
    'community group',
  ),
  CategoryIconOption(
    'sell',
    'General',
    Icons.sell_outlined,
    'product sale สินค้า',
  ),
];

final Map<String, IconData> categoryIconOptions = {
  for (final option in categoryIconCatalog) option.key: option.icon,
};

List<String> get categoryIconGroups => {
  for (final option in categoryIconCatalog) option.group,
}.toList(growable: false);

IconData categoryIconData(String? iconKey) =>
    categoryIconOptions[iconKey] ?? Icons.category;
