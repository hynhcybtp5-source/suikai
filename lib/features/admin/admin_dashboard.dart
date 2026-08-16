import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/category_icons.dart';
import '../../data/models.dart';
import '../../services/suikai_service.dart';
import '../../widgets/location_picker_map.dart';

double? _adminCoordinate(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String adminLocationText(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return 'ไม่มีข้อมูลตำแหน่ง';
  return 'Latitude: ${latitude.toStringAsFixed(6)}\n'
      'Longitude: ${longitude.toStringAsFixed(6)}';
}

Future<void> _showAdminFullScreenMap(
  BuildContext context, {
  required String title,
  required double latitude,
  required double longitude,
}) => showDialog<void>(
  context: context,
  builder: (_) => Dialog.fullscreen(
    child: Scaffold(
      appBar: AppBar(title: Text('แผนที่: $title')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: LocationPickerMap(
          value: LatLng(latitude, longitude),
          height: double.infinity,
        ),
      ),
    ),
  ),
);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> login() async {
    setState(() => busy = true);
    final ok = await SuikaiService.admin.login(email.text, password.text);
    if (!mounted) return;
    setState(() => busy = false);
    if (!ok)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ข้อมูล Admin ไม่ถูกต้อง')));
  }

  @override
  Widget build(BuildContext context) {
    if (SuikaiService.admin.isAuthenticated) return const _AdminPanel();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                size: 76,
                color: AppTheme.orange,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Admin email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Admin password'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: busy ? null : login,
                child: Text(busy ? 'กำลังตรวจสอบ...' : 'เข้าสู่ระบบ Admin'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminPanel extends StatefulWidget {
  const _AdminPanel();
  @override
  State<_AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<_AdminPanel>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Map<String, int> summary = {};
  List<Map<String, dynamic>> users = [],
      listings = [],
      stores = [],
      reports = [],
      editRequests = [],
      promotionRequests = [],
      adminNotifications = [];
  List<CategoryRecord> categories = [];
  List<ShortVideoRecord> videos = [];
  List<AdvertisementRecord> advertisements = [];
  final Map<String, int> categoryUsage = {};
  final Set<int> _loadedTabs = {0};
  final Set<int> _loadingTabs = {};
  final Map<int, int> _pages = {};
  final Map<int, bool> _hasMore = {};
  late final TabController _tabs;
  bool summaryLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabs = TabController(length: 10, vsync: this)..addListener(_tabChanged);
    load();
  }

  @override
  void dispose() {
    _tabs
      ..removeListener(_tabChanged)
      ..dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _tabChanged() {
    if (!_tabs.indexIsChanging) {
      _handleTabChanged(_tabs.index);
    }
  }

  Future<void> _handleTabChanged(int index) async {
    await _refreshHeader();
    await _loadTab(index);
    await _markTabReviewed(index);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshHeader();
  }

  Future<void> _refreshHeader() async {
    final values = await Future.wait([
      SuikaiService.admin.summary(),
      SuikaiService.admin.adminNotifications(),
    ]);
    if (!mounted) return;
    setState(() {
      summary = values[0] as Map<String, int>;
      adminNotifications = values[1] as List<Map<String, dynamic>>;
    });
  }

  Future<void> _markTabReviewed(int index) async {
    final types = switch (index) {
      2 => const {'general_listing'},
      3 || 6 => const {'shop_application'},
      4 => const {'store_product'},
      _ => const <String>{},
    };
    final unread = adminNotifications
        .where((row) => row['is_read'] != true && types.contains(row['type']))
        .toList();
    if (unread.isEmpty) return;
    await Future.wait(
      unread.map(
        (row) => SuikaiService.admin.markAdminNotificationRead('${row['id']}'),
      ),
    );
    if (!mounted) return;
    setState(() {
      for (final row in unread) {
        row['is_read'] = true;
      }
    });
  }

  Future<T> _timed<T>(String name, Future<T> Function() query) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('Admin query $name: start');
    try {
      return await query();
    } finally {
      debugPrint('Admin query $name: end ${stopwatch.elapsedMilliseconds}ms');
    }
  }

  Future<void> load() async {
    if (mounted) setState(() => summaryLoading = true);
    final values = await Future.wait([
      _timed('summary', SuikaiService.admin.summary),
      _timed('admin_notifications', SuikaiService.admin.adminNotifications),
    ]);
    if (!mounted) return;
    setState(() {
      summary = values[0] as Map<String, int>;
      adminNotifications = values[1] as List<Map<String, dynamic>>;
      summaryLoading = false;
    });
    await _loadTab(_tabs.index, refresh: true);
  }

  Future<void> _reloadTab(int index) async {
    await _loadTab(index, refresh: true);
    final values = await Future.wait([
      SuikaiService.admin.summary(),
      SuikaiService.admin.adminNotifications(),
    ]);
    if (!mounted) return;
    setState(() {
      summary = values[0] as Map<String, int>;
      adminNotifications = values[1] as List<Map<String, dynamic>>;
    });
    await _markTabReviewed(index);
  }

  Future<void> _loadTab(int index, {bool refresh = false}) async {
    if ((!refresh && _loadedTabs.contains(index)) ||
        _loadingTabs.contains(index)) {
      return;
    }
    setState(() => _loadingTabs.add(index));
    try {
      switch (index) {
        case 1:
          users = await _timed('profiles.page_1', SuikaiService.admin.users);
          _pages[1] = 0;
          _hasMore[1] = users.length == 50;
        case 2 || 4:
          final values = await Future.wait([
            _timed('listings.page_1', SuikaiService.admin.listings),
            _timed('stores.page_1', SuikaiService.admin.stores),
          ]);
          listings = values[0];
          stores = values[1];
          _loadedTabs.addAll({2, 4});
          _pages[2] = 0;
          _pages[4] = 0;
          _hasMore[2] = listings.length == 50;
          _hasMore[4] = listings.length == 50;
        case 3:
          stores = await _timed('stores.page_1', SuikaiService.admin.stores);
          _pages[3] = 0;
          _hasMore[3] = stores.length == 50;
        case 5:
          reports = await _timed('reports.page_1', SuikaiService.admin.reports);
          _pages[5] = 0;
          _hasMore[5] = reports.length == 50;
        case 6:
          final values = await Future.wait([
            _timed(
              'store_edit_requests.page_1',
              SuikaiService.admin.storeEditRequests,
            ),
            _timed(
              'promotion_requests.page_1',
              SuikaiService.admin.promotionRequests,
            ),
            _timed('stores.page_1', SuikaiService.admin.stores),
            _timed(
              'admin_notifications',
              SuikaiService.admin.adminNotifications,
            ),
          ]);
          editRequests = values[0];
          promotionRequests = values[1];
          stores = values[2];
          adminNotifications = values[3];
        case 7:
          final values = await Future.wait([
            _timed('categories', () async {
              await SuikaiService.refreshCategories();
              return <Object?>[];
            }),
            _timed('stores.page_1', SuikaiService.admin.stores),
            _timed('listings.page_1', SuikaiService.admin.listings),
          ]);
          stores = values[1] as List<Map<String, dynamic>>;
          listings = values[2] as List<Map<String, dynamic>>;
          categories = [
            ...SuikaiService.categoryRecords('store'),
            ...SuikaiService.categoryRecords('listing'),
          ];
          categoryUsage
            ..clear()
            ..addEntries(
              categories.map(
                (category) => MapEntry(
                  category.id,
                  category.type == 'store'
                      ? stores
                            .where(
                              (row) => category.matches(
                                '${row['category_id'] ?? row['category'] ?? ''}',
                              ),
                            )
                            .length
                      : listings
                            .where(
                              (row) =>
                                  row['store_id'] == null &&
                                  category.matches(
                                    '${row['category_id'] ?? row['category'] ?? ''}',
                                  ),
                            )
                            .length,
                ),
              ),
            );
        case 8:
          videos = await _timed(
            'tiktok_videos.page_1',
            SuikaiService.fetchAllShortVideos,
          );
        case 9:
          final values = await Future.wait([
            _timed('banners', SuikaiService.fetchAllAdvertisements),
            _timed('stores.for_banners', SuikaiService.admin.stores),
            _timed('listings.for_banners', SuikaiService.admin.listings),
            _timed('categories.for_banners', () async {
              await SuikaiService.refreshCategories();
              return <Object?>[];
            }),
          ]);
          advertisements = values[0] as List<AdvertisementRecord>;
          stores = values[1] as List<Map<String, dynamic>>;
          listings = values[2] as List<Map<String, dynamic>>;
          categories = [
            ...SuikaiService.categoryRecords('store'),
            ...SuikaiService.categoryRecords('listing'),
          ];
      }
      _loadedTabs.add(index);
    } finally {
      if (mounted) setState(() => _loadingTabs.remove(index));
    }
  }

  Widget _tabBody(int index, Widget child) {
    if (_loadingTabs.contains(index) && !_loadedTabs.contains(index)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!const {1, 2, 3, 4, 5}.contains(index)) return child;
    return Column(
      children: [
        Expanded(child: child),
        if (_hasMore[index] == true)
          SafeArea(
            top: false,
            child: TextButton.icon(
              onPressed: _loadingTabs.contains(index)
                  ? null
                  : () => _loadMore(index),
              icon: const Icon(Icons.expand_more_rounded),
              label: const Text('โหลดเพิ่มเติม'),
            ),
          ),
      ],
    );
  }

  Future<void> _loadMore(int index) async {
    if (_loadingTabs.contains(index) || _hasMore[index] != true) return;
    setState(() => _loadingTabs.add(index));
    final page = (_pages[index] ?? 0) + 1;
    try {
      late final List<Map<String, dynamic>> next;
      switch (index) {
        case 1:
          next = await SuikaiService.admin.users(page: page);
          users.addAll(next);
        case 2 || 4:
          next = await SuikaiService.admin.listings(page: page);
          listings.addAll(next);
          _pages[2] = page;
          _pages[4] = page;
          _hasMore[2] = next.length == 50;
          _hasMore[4] = next.length == 50;
        case 3:
          next = await SuikaiService.admin.stores(page: page);
          stores.addAll(next);
        case 5:
          next = await SuikaiService.admin.reports(page: page);
          reports.addAll(next);
        default:
          return;
      }
      _pages[index] = page;
      _hasMore[index] = next.length == 50;
    } finally {
      if (mounted) setState(() => _loadingTabs.remove(index));
    }
  }

  Future<void> logout() async {
    await SuikaiService.admin.logout();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Suikai Admin'),
      actions: [
        IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded)),
        IconButton(onPressed: logout, icon: const Icon(Icons.logout_rounded)),
      ],
      bottom: TabBar(
        controller: _tabs,
        isScrollable: true,
        tabs: [
          const Tab(text: 'ภาพรวม'),
          const Tab(text: 'สมาชิก'),
          _AdminTabBadge(
            text: 'ประกาศ',
            count: _unreadCount('general_listing'),
          ),
          _AdminTabBadge(text: 'ร้าน', count: _unreadCount('shop_application')),
          _AdminTabBadge(
            text: 'สินค้าในร้าน',
            count: _unreadCount('store_product'),
          ),
          const Tab(text: 'Reports'),
          Tab(
            child: Badge(
              isLabelVisible: adminNotifications.any(
                (value) =>
                    value['type'] == 'shop_application' &&
                    value['is_read'] != true,
              ),
              label: Text(
                '${adminNotifications.where((value) => value['type'] == 'shop_application' && value['is_read'] != true).length}',
              ),
              child: const Text('คำร้องร้าน'),
            ),
          ),
          const Tab(text: 'หมวดหมู่'),
          const Tab(text: 'วิดีโอสั้น'),
          const Tab(text: 'โฆษณา'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: [
        summaryLoading
            ? const Center(child: CircularProgressIndicator())
            : _Summary(summary: summary),
        _tabBody(1, _Users(rows: users, changed: () => _reloadTab(1))),
        _tabBody(
          2,
          _Listings(
            rows: listings.where((e) => e['store_id'] == null).toList(),
            changed: () => _reloadTab(2),
            stores: stores,
          ),
        ),
        _tabBody(3, _Stores(rows: stores, changed: () => _reloadTab(3))),
        _tabBody(
          4,
          _Listings(
            rows: listings.where((e) => e['store_id'] != null).toList(),
            changed: () => _reloadTab(4),
            storeProducts: true,
            stores: stores,
          ),
        ),
        _tabBody(5, _Reports(rows: reports, changed: () => _reloadTab(5))),
        _tabBody(
          6,
          _StoreRequests(
            edits: editRequests,
            promotions: promotionRequests,
            notifications: adminNotifications,
            stores: stores,
            changed: () => _reloadTab(6),
          ),
        ),
        _tabBody(
          7,
          _Categories(
            rows: categories,
            usage: categoryUsage,
            changed: () => _reloadTab(7),
          ),
        ),
        _tabBody(8, _ShortVideos(rows: videos, changed: () => _reloadTab(8))),
        _tabBody(
          9,
          _Advertisements(
            rows: advertisements,
            stores: stores,
            listings: listings,
            categories: categories,
            changed: () => _reloadTab(9),
          ),
        ),
      ],
    ),
  );

  int _unreadCount(String type) => adminNotifications
      .where((row) => row['type'] == type && row['is_read'] != true)
      .length;
}

class _AdminTabBadge extends StatelessWidget {
  final String text;
  final int count;
  const _AdminTabBadge({required this.text, required this.count});

  @override
  Widget build(BuildContext context) => Tab(
    child: Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(text),
      ),
    ),
  );
}

String _shortVideoDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}';
}

class _Advertisements extends StatelessWidget {
  final List<AdvertisementRecord> rows;
  final List<Map<String, dynamic>> stores, listings;
  final List<CategoryRecord> categories;
  final Future<void> Function() changed;
  const _Advertisements({
    required this.rows,
    required this.stores,
    required this.listings,
    required this.categories,
    required this.changed,
  });

  Future<void> _edit(
    BuildContext context, [
    AdvertisementRecord? current,
  ]) async {
    final value = await showDialog<AdvertisementRecord>(
      context: context,
      builder: (_) => _AdvertisementDialog(
        current: current,
        stores: stores,
        listings: listings,
        categories: categories,
      ),
    );
    if (value == null) return;
    await SuikaiService.saveAdvertisement(value, create: current == null);
    await changed();
  }

  Future<void> _toggle(AdvertisementRecord value, bool active) async {
    await SuikaiService.saveAdvertisement(
      AdvertisementRecord(
        id: value.id,
        title: value.title,
        imageUrl: value.imageUrl,
        targetType: value.targetType,
        targetId: value.targetId,
        externalUrl: value.externalUrl,
        startAt: value.startAt,
        endAt: value.endAt,
        displayOrder: value.displayOrder,
        isActive: active,
        createdAt: value.createdAt,
        updatedAt: DateTime.now(),
      ),
      create: false,
    );
    await changed();
  }

  Future<void> _delete(BuildContext context, AdvertisementRecord value) async {
    if (!await _confirm(context, 'ลบโฆษณา “${value.title}” หรือไม่?')) return;
    await SuikaiService.deleteAdvertisement(value.id);
    await changed();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('เพิ่มโฆษณา'),
          ),
        ),
      ),
      Expanded(
        child: rows.isEmpty
            ? const Center(child: Text('ยังไม่มีโฆษณา'))
            : ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final value = rows[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        value.imageUrl,
                        width: 92,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 92,
                          height: 52,
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ),
                    title: Text(value.title),
                    subtitle: Text(
                      '${value.targetType} • ลำดับ ${value.displayOrder}',
                    ),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Switch(
                          value: value.isActive,
                          onChanged: (active) => _toggle(value, active),
                        ),
                        IconButton(
                          tooltip: 'แก้ไข',
                          onPressed: () => _edit(context, value),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'ลบ',
                          onPressed: () => _delete(context, value),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    ],
  );
}

class _AdvertisementDialog extends StatefulWidget {
  final AdvertisementRecord? current;
  final List<Map<String, dynamic>> stores, listings;
  final List<CategoryRecord> categories;
  const _AdvertisementDialog({
    this.current,
    required this.stores,
    required this.listings,
    required this.categories,
  });

  @override
  State<_AdvertisementDialog> createState() => _AdvertisementDialogState();
}

class _AdvertisementDialogState extends State<_AdvertisementDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController title, url, order, productLink;
  late String targetType;
  String? targetId;
  DateTime? startAt, endAt;
  late bool active;
  SelectedImage? selectedImage;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    title = TextEditingController(text: current?.title ?? '');
    url = TextEditingController(text: current?.externalUrl ?? '');
    productLink = TextEditingController(
      text: current?.targetType == 'product' && current?.targetId != null
          ? _productLink(current!.targetId!)
          : '',
    );
    order = TextEditingController(text: '${current?.displayOrder ?? 0}');
    targetType = current?.targetType ?? 'external';
    targetId = current?.targetId;
    startAt = current?.startAt;
    endAt = current?.endAt;
    active = current?.isActive ?? true;
  }

  @override
  void dispose() {
    title.dispose();
    url.dispose();
    order.dispose();
    productLink.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> get _targets => switch (targetType) {
    'shop' => [
      for (final row in widget.stores)
        DropdownMenuItem(
          value: '${row['id']}',
          child: Text('${row['name'] ?? ''}', overflow: TextOverflow.ellipsis),
        ),
    ],
    'product' => [
      for (final row in widget.listings)
        DropdownMenuItem(
          value: '${row['id']}',
          child: Text('${row['title'] ?? ''}', overflow: TextOverflow.ellipsis),
        ),
    ],
    'category' => [
      for (final value in widget.categories)
        DropdownMenuItem(
          value: value.id,
          child: Text(value.nameTh, overflow: TextOverflow.ellipsis),
        ),
    ],
    _ => const [],
  };

  String _productLink(String productId) => Uri.base
      .replace(
        path: Uri.base.path.isEmpty ? '/' : Uri.base.path,
        queryParameters: {'product': productId},
      )
      .toString();

  String? _productIdFromLink(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    return uri?.queryParameters['product']?.trim();
  }

  Future<void> _pickImage() async {
    final image = await SuikaiService.pickImage();
    if (image != null && mounted) setState(() => selectedImage = image);
  }

  Future<void> _pickDate(bool start) async {
    final value = await showDatePicker(
      context: context,
      initialDate: (start ? startAt : endAt) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null) {
      setState(() {
        if (start) {
          startAt = DateTime(value.year, value.month, value.day);
        } else {
          endAt = DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
        }
      });
    }
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    if (targetType != 'external' && targetId == null) return;
    if (startAt != null && endAt != null && endAt!.isBefore(startAt!)) return;
    setState(() => saving = true);
    try {
      final imageUrl = selectedImage == null
          ? widget.current?.imageUrl ?? ''
          : await SuikaiService.uploadAdvertisementImage(selectedImage!);
      if (imageUrl.isEmpty) return;
      final now = DateTime.now();
      if (!mounted) return;
      Navigator.pop(
        context,
        AdvertisementRecord(
          id: widget.current?.id ?? const Uuid().v4(),
          title: title.text.trim(),
          imageUrl: imageUrl,
          targetType: targetType,
          targetId: targetType == 'external' ? null : targetId,
          externalUrl: targetType == 'external' ? url.text.trim() : null,
          startAt: startAt,
          endAt: endAt,
          displayOrder: int.tryParse(order.text) ?? 0,
          isActive: active,
          createdAt: widget.current?.createdAt ?? now,
          updatedAt: now,
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.current == null ? 'เพิ่มโฆษณา' : 'แก้ไขโฆษณา'),
    content: SizedBox(
      width: 620,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: selectedImage != null
                      ? Image.memory(selectedImage!.bytes, fit: BoxFit.cover)
                      : widget.current?.imageUrl.isNotEmpty == true
                      ? Image.network(
                          widget.current!.imageUrl,
                          fit: BoxFit.cover,
                        )
                      : const ColoredBox(
                          color: AppTheme.orangeSoft,
                          child: Icon(Icons.image_outlined),
                        ),
                ),
              ),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_outlined),
                label: const Text('เลือกรูป Banner'),
              ),
              TextFormField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'ชื่อ/ข้อความสั้น *',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'กรุณากรอกชื่อโฆษณา'
                    : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: targetType,
                decoration: const InputDecoration(labelText: 'ประเภทปลายทาง'),
                items: const [
                  DropdownMenuItem(value: 'shop', child: Text('ร้านค้า')),
                  DropdownMenuItem(value: 'product', child: Text('สินค้า')),
                  DropdownMenuItem(value: 'category', child: Text('หมวดหมู่')),
                  DropdownMenuItem(
                    value: 'external',
                    child: Text('URL ภายนอก'),
                  ),
                ],
                onChanged: (value) => setState(() {
                  targetType = value ?? 'external';
                  targetId = null;
                }),
              ),
              const SizedBox(height: 10),
              if (targetType == 'external')
                TextFormField(
                  controller: url,
                  decoration: const InputDecoration(labelText: 'External URL'),
                  validator: (value) {
                    final uri = Uri.tryParse(value ?? '');
                    return uri == null ||
                            (uri.scheme != 'https' && uri.scheme != 'http')
                        ? 'กรุณากรอก URL ที่ถูกต้อง'
                        : null;
                  },
                )
              else if (targetType == 'product') ...[
                TextFormField(
                  controller: productLink,
                  decoration: const InputDecoration(
                    labelText: 'วางลิงก์สินค้า',
                    hintText: 'วางลิงก์ที่คัดลอกจากปุ่มลิงก์สินค้า',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  onChanged: (value) =>
                      setState(() => targetId = _productIdFromLink(value)),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return _productIdFromLink(value) == null
                        ? 'ไม่พบรหัสสินค้าในลิงก์'
                        : null;
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('หรือเลือกสินค้าจากรายการด้านล่าง'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _targets.any((item) => item.value == targetId)
                      ? targetId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'เลือกสินค้า'),
                  items: _targets,
                  onChanged: (value) => setState(() => targetId = value),
                  validator: (value) =>
                      targetId == null ? 'กรุณาวางลิงก์หรือเลือกสินค้า' : null,
                ),
              ] else
                DropdownButtonFormField<String>(
                  initialValue: _targets.any((item) => item.value == targetId)
                      ? targetId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'เลือกปลายทาง'),
                  items: _targets,
                  onChanged: (value) => targetId = value,
                  validator: (value) =>
                      value == null ? 'กรุณาเลือกปลายทาง' : null,
                ),
              const SizedBox(height: 10),
              TextFormField(
                controller: order,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ลำดับการแสดง'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickDate(true),
                      child: Text(
                        'เริ่ม: ${startAt?.toLocal().toString().split(' ').first ?? 'ไม่กำหนด'}',
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickDate(false),
                      child: Text(
                        'สิ้นสุด: ${endAt?.toLocal().toString().split(' ').first ?? 'ไม่กำหนด'}',
                      ),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: active,
                onChanged: (value) => setState(() => active = value),
                title: const Text('เปิดแสดงผล'),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      ElevatedButton(
        onPressed: saving ? null : _save,
        child: Text(saving ? 'กำลังบันทึก...' : 'บันทึก'),
      ),
    ],
  );
}

class _ShortVideos extends StatelessWidget {
  final List<ShortVideoRecord> rows;
  final Future<void> Function() changed;
  const _ShortVideos({required this.rows, required this.changed});

  Future<void> _edit(BuildContext context, [ShortVideoRecord? current]) async {
    final value = await showDialog<ShortVideoRecord>(
      context: context,
      builder: (_) => _ShortVideoDialog(current: current),
    );
    if (value == null) return;
    await SuikaiService.saveShortVideo(value, create: current == null);
    await changed();
  }

  Future<void> _toggle(ShortVideoRecord value, bool active) async {
    await SuikaiService.saveShortVideo(
      ShortVideoRecord(
        id: value.id,
        tiktokUrl: value.tiktokUrl,
        title: value.title,
        sortOrder: value.sortOrder,
        isActive: active,
        createdBy: value.createdBy,
        createdAt: value.createdAt,
        updatedAt: DateTime.now(),
      ),
      create: false,
    );
    await changed();
  }

  Future<void> _delete(BuildContext context, ShortVideoRecord value) async {
    if (!await _confirm(
      context,
      'ลบวิดีโอวันที่ ${_shortVideoDate(value.createdAt)} หรือไม่?',
    )) {
      return;
    }
    await SuikaiService.deleteShortVideo(value.id);
    await changed();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('เพิ่ม TikTok'),
          ),
        ),
      ),
      Expanded(
        child: rows.isEmpty
            ? const Center(child: Text('ยังไม่มีวิดีโอสั้น'))
            : ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final value = rows[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.orangeSoft,
                      foregroundColor: AppTheme.orange,
                      child: Text('${value.sortOrder}'),
                    ),
                    title: Text(
                      _shortVideoDate(value.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      value.tiktokUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Chip(label: Text(value.isActive ? 'Active' : 'Hidden')),
                        Switch(
                          value: value.isActive,
                          onChanged: (active) => _toggle(value, active),
                        ),
                        IconButton(
                          tooltip: 'แก้ไข',
                          onPressed: () => _edit(context, value),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'ลบ',
                          onPressed: () => _delete(context, value),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    ],
  );
}

class _ShortVideoDialog extends StatefulWidget {
  final ShortVideoRecord? current;
  const _ShortVideoDialog({this.current});

  @override
  State<_ShortVideoDialog> createState() => _ShortVideoDialogState();
}

class _ShortVideoDialogState extends State<_ShortVideoDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController url, order;
  late final DateTime createdAt;
  late bool active;

  @override
  void initState() {
    super.initState();
    url = TextEditingController(text: widget.current?.tiktokUrl ?? '');
    createdAt = widget.current?.createdAt ?? DateTime.now();
    order = TextEditingController(text: '${widget.current?.sortOrder ?? 0}');
    active = widget.current?.isActive ?? true;
  }

  @override
  void dispose() {
    url.dispose();
    order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.current == null ? 'เพิ่ม TikTok' : 'แก้ไข TikTok'),
    content: SizedBox(
      width: 520,
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: url,
              decoration: const InputDecoration(labelText: 'TikTok URL *'),
              validator: (value) =>
                  ShortVideoRecord.isValidTikTokUrl(value ?? '')
                  ? null
                  : 'กรุณาใส่ HTTPS TikTok URL ที่ถูกต้อง',
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'วันที่'),
              child: Text(_shortVideoDate(createdAt)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: order,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ลำดับ'),
              validator: (value) =>
                  int.tryParse(value ?? '') == null ? 'กรุณาใส่ตัวเลข' : null,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('แสดงในแอป'),
              value: active,
              onChanged: (value) => setState(() => active = value),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      ElevatedButton(
        onPressed: () {
          if (!formKey.currentState!.validate()) return;
          final now = DateTime.now();
          Navigator.pop(
            context,
            ShortVideoRecord(
              id: widget.current?.id ?? const Uuid().v4(),
              tiktokUrl: url.text.trim(),
              title: widget.current?.title ?? '',
              sortOrder: int.parse(order.text),
              isActive: active,
              createdBy: widget.current?.createdBy,
              createdAt: createdAt,
              updatedAt: now,
            ),
          );
        },
        child: const Text('บันทึก'),
      ),
    ],
  );
}

class _Summary extends StatelessWidget {
  final Map<String, int> summary;
  const _Summary({required this.summary});
  @override
  Widget build(BuildContext context) {
    const labels = {
      'users': 'สมาชิก',
      'listings': 'ประกาศ',
      'stores': 'ร้าน',
      'store_products': 'สินค้าในร้าน',
      'reports': 'Reports',
    };
    const icons = {
      'users': Icons.people_alt_outlined,
      'listings': Icons.sell_outlined,
      'stores': Icons.storefront_outlined,
      'store_products': Icons.inventory_2_outlined,
      'reports': Icons.flag_outlined,
    };
    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 3 : 2,
      childAspectRatio: MediaQuery.sizeOf(context).width > 700 ? 1.45 : 1.18,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        for (final key in labels.keys)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icons[key], color: AppTheme.orange, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '${summary[key] ?? 0}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    labels[key]!,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Users extends StatefulWidget {
  final List<Map<String, dynamic>> rows;
  final Future<void> Function() changed;
  const _Users({required this.rows, required this.changed});
  @override
  State<_Users> createState() => _UsersState();
}

class _UsersState extends State<_Users> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final rows = widget.rows
        .where((e) => '$e'.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Column(
      children: [
        _Search(
          onChanged: (v) => setState(() => query = v),
          hint: 'ค้นหาชื่อ อีเมล หรือเบอร์โทร',
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final u = rows[i];
              return ListTile(
                leading: _ProfileAvatar(user: u),
                title: Text(
                  '${u['name'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${u['email'] ?? ''}\n${u['id']}'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => action(u, v),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: u['status'] == 'suspended'
                          ? 'active'
                          : 'suspended',
                      child: Text(
                        u['status'] == 'suspended' ? 'เปิดใช้งาน' : 'ระงับ',
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'details',
                      child: Text('รายละเอียด'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('ลบ')),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> action(Map<String, dynamic> u, String value) async {
    if (value == 'details') {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('${u['name']}'),
          content: SelectableText(
            'ID: ${u['id']}\nEmail: ${u['email']}\nPhone: ${u['phone']}\nStatus: ${u['status']}\nCreated: ${u['created_at']}',
          ),
        ),
      );
      return;
    }
    if (value == 'delete' &&
        !await _confirm(context, 'ลบสมาชิกและข้อมูลที่เป็นเจ้าของทั้งหมด?'))
      return;
    if (value == 'delete')
      await SuikaiService.admin.deleteUser('${u['id']}');
    else
      await SuikaiService.admin.setUserStatus('${u['id']}', value);
    await widget.changed();
  }
}

class _Listings extends StatefulWidget {
  final List<Map<String, dynamic>> rows;
  final List<Map<String, dynamic>> stores;
  final Future<void> Function() changed;
  final bool storeProducts;
  const _Listings({
    required this.rows,
    required this.stores,
    required this.changed,
    this.storeProducts = false,
  });
  @override
  State<_Listings> createState() => _ListingsState();
}

class _ListingsState extends State<_Listings> {
  String query = '', filter = 'all';
  @override
  Widget build(BuildContext context) {
    if (widget.storeProducts) return _buildStoreGroups(context);
    final rows = widget.rows
        .where(
          (e) =>
              (filter == 'all' || e['status'] == filter) &&
              '$e'.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return Column(
      children: [
        _Search(
          onChanged: (v) => setState(() => query = v),
          hint: 'ค้นหาชื่อ หมวดหมู่ หรือ ownerId',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            initialValue: filter,
            items: const [
              'all',
              'available',
              'reserved',
              'sold',
              'out_of_stock',
              'hidden',
              'deleted',
            ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => filter = v ?? 'all'),
            decoration: const InputDecoration(
              labelText: 'กรองสถานะ',
              isDense: true,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final p = rows[i];
              return ListTile(
                leading: _Thumb(images: p['images']),
                title: Text(
                  '${p['title'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${p['status']} • ${p['currency']} ${p['price']}\nOwner: ${p['owner_id']}',
                ),
                isThreeLine: true,
                onTap: () => details(p),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => action(p, v),
                  itemBuilder: (_) => [
                    for (final s
                        in widget.storeProducts
                            ? const [
                                'available',
                                'out_of_stock',
                                'deleted',
                                'hidden',
                              ]
                            : const ['available', 'reserved', 'sold', 'hidden'])
                      PopupMenuItem(value: s, child: Text(s)),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'delete', child: Text('ลบ')),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStoreGroups(BuildContext context) {
    final productsByStore = <String, List<Map<String, dynamic>>>{};
    for (final product in widget.rows) {
      final storeId = '${product['store_id'] ?? ''}';
      if (storeId.isNotEmpty) {
        productsByStore.putIfAbsent(storeId, () => []).add(product);
      }
    }
    final storeById = {
      for (final store in widget.stores) '${store['id']}': store,
    };
    final groups = productsByStore.entries.where((entry) {
      final store = storeById[entry.key];
      final text = '${store?['name'] ?? ''} ${entry.value}'.toLowerCase();
      return text.contains(query.toLowerCase());
    }).toList();
    return Column(
      children: [
        _Search(
          onChanged: (value) => setState(() => query = value),
          hint: 'ค้นหาชื่อร้านหรือสินค้า',
        ),
        Expanded(
          child: ListView.builder(
            itemCount: groups.length,
            itemBuilder: (_, index) {
              final group = groups[index];
              final store = storeById[group.key] ?? const <String, dynamic>{};
              final name = '${store['name'] ?? 'ร้านค้าไม่พบข้อมูล'}';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: _StoreLogo(store: store),
                  title: Text(name),
                  subtitle: Text('สินค้า ${group.value.length} รายการ'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      _showStoreProducts(context, name, store, group.value),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showStoreProducts(
    BuildContext context,
    String name,
    Map<String, dynamic> store,
    List<Map<String, dynamic>> products,
  ) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(
        children: [
          _StoreLogo(store: store),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
        ],
      ),
      content: SizedBox(
        width: 620,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (_, index) {
            final product = products[index];
            return ListTile(
              leading: _Thumb(images: product['images']),
              title: Text('${product['title'] ?? ''}'),
              subtitle: Text(
                '${product['currency'] ?? ''} ${product['price'] ?? ''} • ${product['status'] ?? ''}',
              ),
              onTap: () => details(product),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
      ],
    ),
  );

  Future<void> details(Map<String, dynamic> p) => showDialog(
    context: context,
    builder: (dialogContext) {
      final latitude = _adminCoordinate(p['latitude']);
      final longitude = _adminCoordinate(p['longitude']);
      return AlertDialog(
        title: Text('${p['title']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 180,
                width: double.maxFinite,
                child: _FullImage(images: p['images']),
              ),
              const SizedBox(height: 12),
              SelectableText(
                'ID: ${p['id']}\nOwner: ${p['owner_id']}\nStore: ${p['store_id'] ?? '-'}\nCategory: ${p['category']}\nStatus: ${p['status']}\nPrice: ${p['price']} ${p['currency']}\n${adminLocationText(latitude, longitude)}\n\n${p['description']}',
              ),
              const SizedBox(height: 12),
              if (latitude != null && longitude != null) ...[
                LocationPickerMap(
                  value: LatLng(latitude, longitude),
                  height: 260,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _showAdminFullScreenMap(
                      dialogContext,
                      title: '${p['title']}',
                      latitude: latitude,
                      longitude: longitude,
                    ),
                    icon: const Icon(Icons.fullscreen_rounded),
                    label: const Text('ดูแผนที่เต็มจอ'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
  Future<void> action(Map<String, dynamic> p, String value) async {
    if (value == 'delete' && !await _confirm(context, 'ลบรายการนี้ถาวร?'))
      return;
    if (value == 'delete')
      await SuikaiService.admin.deleteListing('${p['id']}');
    else
      await SuikaiService.admin.setListingStatus('${p['id']}', value);
    await widget.changed();
  }
}

class _Stores extends StatefulWidget {
  final List<Map<String, dynamic>> rows;
  final Future<void> Function() changed;
  const _Stores({required this.rows, required this.changed});
  @override
  State<_Stores> createState() => _StoresState();
}

class _StoresState extends State<_Stores> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final rows = widget.rows
        .where((e) => '$e'.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Column(
      children: [
        _Search(
          onChanged: (v) => setState(() => query = v),
          hint: 'ค้นหาร้าน เจ้าของ หรือหมวดหมู่',
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (_, i) {
              final s = rows[i];
              return ListTile(
                leading: _StoreLogo(store: s),
                title: Text(
                  '${s['name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${s['status']} • ${s['category']} • Promote: ${s['is_promoted'] == true ? 'ON' : 'OFF'}\nOwner: ${s['owner_id']}',
                ),
                isThreeLine: true,
                onTap: () => details(s),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => action(s, v),
                  itemBuilder: (_) =>
                      [
                            s['is_promoted'] == true
                                ? 'promote_off'
                                : 'promote_on',
                            'approved',
                            'pending',
                            'rejected',
                            'hidden',
                            'delete',
                          ]
                          .map((v) => PopupMenuItem(value: v, child: Text(v)))
                          .toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> details(Map<String, dynamic> store) => showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final latitude = _adminCoordinate(store['latitude']);
      final longitude = _adminCoordinate(store['longitude']);
      return AlertDialog(
        title: Text('${store['name'] ?? ''}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _StoreLogo(store: store, size: 88)),
                const SizedBox(height: 14),
                SelectableText(
                  'สถานะ: ${store['status']}\n'
                  'วันที่สมัคร: ${store['created_at'] ?? '-'}\n'
                  'เจ้าของ: ${store['owner_id'] ?? '-'}\n'
                  'โทร: ${store['phone'] ?? '-'}\n'
                  'หมวดหมู่: ${store['category_id'] ?? store['category'] ?? '-'}\n'
                  '${adminLocationText(latitude, longitude)}',
                ),
                const SizedBox(height: 14),
                if (latitude != null && longitude != null) ...[
                  LocationPickerMap(
                    value: LatLng(latitude, longitude),
                    height: 260,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _showAdminFullScreenMap(
                        dialogContext,
                        title: '${store['name'] ?? 'ร้าน'}',
                        latitude: latitude,
                        longitude: longitude,
                      ),
                      icon: const Icon(Icons.fullscreen_rounded),
                      label: const Text('ดูแผนที่เต็มจอ'),
                    ),
                  ),
                ] else
                  const Text('ไม่มีข้อมูลตำแหน่ง'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      );
    },
  );

  Future<void> action(Map<String, dynamic> s, String v) async {
    if (v == 'promote_on' || v == 'promote_off') {
      await SuikaiService.admin.setStorePromoted(
        '${s['id']}',
        v == 'promote_on',
      );
      await widget.changed();
      return;
    }
    if (v == 'delete' &&
        !await _confirm(context, 'ลบร้านและสินค้าในร้านทั้งหมด?'))
      return;
    if (v == 'delete')
      await SuikaiService.admin.deleteStore('${s['id']}');
    else
      await SuikaiService.admin.setStoreStatus('${s['id']}', v);
    await widget.changed();
  }
}

class _StoreRequests extends StatelessWidget {
  final List<Map<String, dynamic>> edits, promotions, stores, notifications;
  final Future<void> Function() changed;
  const _StoreRequests({
    required this.edits,
    required this.promotions,
    required this.stores,
    required this.notifications,
    required this.changed,
  });

  Map<String, dynamic> _store(String id) => stores.firstWhere(
    (store) => '${store['id']}' == id,
    orElse: () => <String, dynamic>{},
  );

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'คำขอเปิดร้านใหม่',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      if (_applications.isEmpty) const Text('ไม่มีคำขอเปิดร้าน'),
      for (final store in _applications)
        Card(
          child: ListTile(
            leading: _StoreLogo(store: store),
            title: Text(
              '${store['name'] ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${store['phone'] ?? '-'} • ${_category(store)}\n${store['created_at'] ?? '-'} • ${store['status']}',
            ),
            isThreeLine: true,
            onTap: () => _openApplication(context, store),
            trailing: store['status'] == 'pending'
                ? Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'ปฏิเสธ',
                        onPressed: () => _reviewApplication(store, false),
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                      IconButton(
                        tooltip: 'อนุมัติ',
                        onPressed: () => _reviewApplication(store, true),
                        icon: const Icon(Icons.check, color: Colors.green),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      const SizedBox(height: 20),
      const Text(
        'Store edit requests',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      if (edits.isEmpty) const Text('ไม่มีคำร้องแก้ไขร้าน'),
      for (final request in edits)
        Card(
          child: ListTile(
            title: Text(
              '${_store('${request['store_id']}')['name'] ?? request['store_id']}',
            ),
            subtitle: Text(
              '${request['status']} • Owner: ${request['owner_id']}\n${request['created_at']}',
            ),
            isThreeLine: true,
            onTap: () => _showEdit(context, request),
            trailing: request['status'] == 'pending'
                ? Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Reject',
                        onPressed: () => _reviewEdit(request, false),
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                      IconButton(
                        tooltip: 'Approve',
                        onPressed: () => _reviewEdit(request, true),
                        icon: const Icon(Icons.check, color: Colors.green),
                      ),
                    ],
                  )
                : null,
          ),
        ),
      const SizedBox(height: 20),
      const Text(
        'Promotion requests',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      if (promotions.isEmpty) const Text('ไม่มีคำขอโปรโมตร้าน'),
      for (final request in promotions)
        Card(
          child: ListTile(
            title: Text(
              '${_store('${request['store_id']}')['name'] ?? request['store_id']}',
            ),
            subtitle: Text(
              '${request['status']} • Owner: ${request['owner_id']}\n${request['created_at']}',
            ),
            isThreeLine: true,
            trailing: request['status'] == 'pending'
                ? Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: 'Reject',
                        onPressed: () => _reviewPromotion(request, false),
                        icon: const Icon(Icons.close, color: Colors.red),
                      ),
                      IconButton(
                        tooltip: 'Approve',
                        onPressed: () => _reviewPromotion(request, true),
                        icon: const Icon(Icons.check, color: Colors.green),
                      ),
                    ],
                  )
                : null,
          ),
        ),
    ],
  );

  bool _isApplication(Map<String, dynamic> store) =>
      const {'pending', 'approved', 'rejected'}.contains(store['status']);

  List<Map<String, dynamic>> get _applications =>
      stores.where(_isApplication).toList()..sort((a, b) {
        final pending = (b['status'] == 'pending' ? 1 : 0).compareTo(
          a['status'] == 'pending' ? 1 : 0,
        );
        return pending != 0
            ? pending
            : '${b['created_at']}'.compareTo('${a['created_at']}');
      });

  String _category(Map<String, dynamic> store) {
    final value = '${store['category_id'] ?? store['category'] ?? ''}';
    return SuikaiService.categoryForValue('store', value)?.nameTh ??
        (value.isEmpty ? '-' : value);
  }

  Map<String, dynamic>? _notification(String shopId) => notifications
      .where(
        (value) =>
            value['type'] == 'shop_application' &&
            '${value['shop_id']}' == shopId,
      )
      .firstOrNull;

  Future<void> _openApplication(
    BuildContext context,
    Map<String, dynamic> store,
  ) async {
    final notification = _notification('${store['id']}');
    if (notification != null && notification['is_read'] != true) {
      await SuikaiService.admin.markAdminNotificationRead(
        '${notification['id']}',
      );
      await changed();
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${store['name'] ?? 'คำขอเปิดร้าน'}'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _StoreLogo(store: store, size: 88)),
                const SizedBox(height: 14),
                SelectableText(
                  'Shop ID: ${store['id']}\nOwner: ${store['owner_id']}\nPhone: ${store['phone'] ?? '-'}\nViber: ${store['viber_phone'] ?? '-'}\nCategory: ${_category(store)}\nCity: ${store['city'] ?? '-'}\nApplied: ${store['created_at'] ?? '-'}\nStatus: ${store['status']}\n\n${store['description'] ?? ''}',
                ),
                const SizedBox(height: 14),
                if (_adminCoordinate(store['latitude']) != null &&
                    _adminCoordinate(store['longitude']) != null) ...[
                  LocationPickerMap(
                    value: LatLng(
                      _adminCoordinate(store['latitude'])!,
                      _adminCoordinate(store['longitude'])!,
                    ),
                    height: 260,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAdminFullScreenMap(
                      dialogContext,
                      title: '${store['name'] ?? 'ร้าน'}',
                      latitude: _adminCoordinate(store['latitude'])!,
                      longitude: _adminCoordinate(store['longitude'])!,
                    ),
                    icon: const Icon(Icons.fullscreen_rounded),
                    label: const Text('ดูแผนที่เต็มจอ'),
                  ),
                ] else
                  const Text('ไม่มีข้อมูลตำแหน่งร้าน'),
              ],
            ),
          ),
        ),
        actions: [
          if (store['status'] == 'pending') ...[
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _reviewApplication(store, false);
              },
              child: const Text('ปฏิเสธ'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _reviewApplication(store, true);
              },
              child: const Text('อนุมัติ'),
            ),
          ] else
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
        ],
      ),
    );
  }

  Future<void> _reviewApplication(
    Map<String, dynamic> store,
    bool approved,
  ) async {
    await SuikaiService.admin.setStoreStatus(
      '${store['id']}',
      approved ? 'approved' : 'rejected',
    );
    final notification = _notification('${store['id']}');
    if (notification != null && notification['is_read'] != true) {
      await SuikaiService.admin.markAdminNotificationRead(
        '${notification['id']}',
      );
    }
    await changed();
  }

  Future<void> _showEdit(BuildContext context, Map<String, dynamic> request) =>
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Before / After'),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SelectableText(
                      'Before\n${_store('${request['store_id']}')}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SelectableText(
                      'After\n${request['proposed_changes']}',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Future<void> _reviewEdit(Map<String, dynamic> request, bool approved) async {
    await SuikaiService.admin.reviewStoreEditRequest(
      '${request['id']}',
      approved,
    );
    await changed();
  }

  Future<void> _reviewPromotion(
    Map<String, dynamic> request,
    bool approved,
  ) async {
    await SuikaiService.admin.reviewPromotionRequest(
      '${request['id']}',
      approved,
    );
    await changed();
  }
}

class _Reports extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final Future<void> Function() changed;
  const _Reports({required this.rows, required this.changed});
  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: rows.length,
    itemBuilder: (_, i) {
      final r = rows[i];
      return CheckboxListTile(
        value: r['reviewed'] == true,
        onChanged: (v) async {
          await SuikaiService.admin.reviewReport('${r['id']}', v ?? false);
          await changed();
        },
        title: Text('${r['reason']}'),
        subtitle: Text('${r['type']} • ${r['target_id']}\n${r['created_at']}'),
        isThreeLine: true,
        secondary: IconButton(
          icon: const Icon(Icons.open_in_new_rounded),
          onPressed: () => Navigator.pushNamed(
            context,
            r['type'] == 'store' ? '/store-detail' : '/product-detail',
            arguments: r['target_id'],
          ),
        ),
      );
    },
  );
}

class _Categories extends StatelessWidget {
  final List<CategoryRecord> rows;
  final Map<String, int> usage;
  final Future<void> Function() changed;
  const _Categories({
    required this.rows,
    required this.usage,
    required this.changed,
  });

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Column(
      children: [
        const Material(
          color: Colors.white,
          child: TabBar(
            tabs: [
              Tab(text: 'หมวดหมู่ร้านค้า'),
              Tab(text: 'หมวดหมู่สินค้าทั่วไป'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            children: [
              _CategoryList(
                type: 'store',
                rows: rows,
                usage: usage,
                changed: changed,
              ),
              _CategoryList(
                type: 'listing',
                rows: rows,
                usage: usage,
                changed: changed,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CategoryList extends StatelessWidget {
  final String type;
  final List<CategoryRecord> rows;
  final Map<String, int> usage;
  final Future<void> Function() changed;
  const _CategoryList({
    required this.type,
    required this.rows,
    required this.usage,
    required this.changed,
  });

  List<CategoryRecord> get items =>
      rows.where((value) => value.type == type).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Future<void> _edit(BuildContext context, [CategoryRecord? current]) async {
    final result = await showDialog<CategoryRecord>(
      context: context,
      builder: (_) => _CategoryEditor(type: type, current: current),
    );
    if (result == null) return;
    if (current == null) {
      await SuikaiService.addCategory(result);
    } else {
      await SuikaiService.updateCategory(result);
    }
    await changed();
  }

  Future<void> _move(int index, int offset) async {
    final ordered = items;
    final next = index + offset;
    if (next < 0 || next >= ordered.length) return;
    final value = ordered.removeAt(index);
    ordered.insert(next, value);
    await SuikaiService.reorderCategories(
      type,
      ordered.map((category) => category.id).toList(),
    );
    await changed();
  }

  @override
  Widget build(BuildContext context) {
    final values = items;
    return Scaffold(
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
        itemCount: values.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final category = values[index];
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.orangeSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryIconData(category.iconKey),
                      color: AppTheme.orangeDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.nameTh,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${category.nameShn} • ${category.nameEn} • ${category.nameMy}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ],
          );
          final controls = Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              Tooltip(
                message: 'จำนวนรายการที่ใช้งาน',
                child: Chip(
                  avatar: const Icon(Icons.inventory_2_outlined, size: 16),
                  label: Text('${usage[category.id] ?? 0}'),
                ),
              ),
              Switch(
                value: category.isActive,
                onChanged: (active) async {
                  await SuikaiService.setCategoryActive(category.id, active);
                  await changed();
                },
              ),
              IconButton(
                tooltip: 'เลื่อนขึ้น',
                onPressed: index == 0 ? null : () => _move(index, -1),
                icon: const Icon(Icons.keyboard_arrow_up_rounded),
              ),
              IconButton(
                tooltip: 'เลื่อนลง',
                onPressed: index == values.length - 1
                    ? null
                    : () => _move(index, 1),
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
              IconButton(
                tooltip: 'แก้ไข',
                onPressed: () => _edit(context, category),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          );
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth >= 680
                    ? Row(
                        children: [
                          Expanded(child: details),
                          const SizedBox(width: 24),
                          controls,
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          details,
                          const SizedBox(height: 12),
                          controls,
                        ],
                      ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มหมวดหมู่'),
      ),
    );
  }
}

class _CategoryEditor extends StatefulWidget {
  final String type;
  final CategoryRecord? current;
  const _CategoryEditor({required this.type, this.current});

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController th;
  late final TextEditingController shn;
  late final TextEditingController en;
  late final TextEditingController my;
  late final TextEditingController iconSearch;
  late String iconKey;

  @override
  void initState() {
    super.initState();
    th = TextEditingController(text: widget.current?.nameTh ?? '');
    shn = TextEditingController(text: widget.current?.nameShn ?? '');
    en = TextEditingController(text: widget.current?.nameEn ?? '');
    my = TextEditingController(text: widget.current?.nameMy ?? '');
    iconSearch = TextEditingController();
    iconKey = widget.current?.iconKey ?? 'category';
  }

  @override
  void dispose() {
    th.dispose();
    shn.dispose();
    en.dispose();
    my.dispose();
    iconSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.current == null ? 'เพิ่มหมวดหมู่' : 'แก้ไขหมวดหมู่'),
    content: SizedBox(
      width: 520,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(th, 'ชื่อภาษาไทย'),
              _field(shn, 'ชื่อภาษาไทยใหญ่ (Shan)'),
              _field(en, 'ชื่อภาษาอังกฤษ'),
              _field(my, 'ชื่อภาษาพม่า'),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('เลือกไอคอน'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: iconSearch,
                decoration: const InputDecoration(
                  labelText: 'ค้นหาไอคอน',
                  hintText: 'เช่น food, repair, รถ, ร้านค้า',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              ..._iconPickerGroups(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    categoryIconData(iconKey),
                    size: 40,
                    color: AppTheme.orange,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      iconKey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      ElevatedButton(
        onPressed: () {
          if (!formKey.currentState!.validate()) return;
          final current = widget.current;
          Navigator.pop(
            context,
            CategoryRecord(
              id: current?.id ?? const Uuid().v4(),
              type: widget.type,
              nameTh: th.text.trim(),
              nameShn: shn.text.trim(),
              nameEn: en.text.trim(),
              nameMy: my.text.trim(),
              iconKey: iconKey,
              isActive: current?.isActive ?? true,
              sortOrder:
                  current?.sortOrder ??
                  SuikaiService.categoryRecords(widget.type).length,
            ),
          );
        },
        child: const Text('บันทึก'),
      ),
    ],
  );

  List<Widget> _iconPickerGroups() {
    final filtered = categoryIconCatalog
        .where((option) => option.matches(iconSearch.text))
        .toList();
    if (filtered.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text('ไม่พบไอคอน'),
        ),
      ];
    }
    return [
      for (final group in categoryIconGroups)
        if (filtered.any((option) => option.group == group)) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 5),
              child: Text(
                group,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final option in filtered.where(
                  (option) => option.group == group,
                ))
                  Tooltip(
                    message: option.key,
                    child: ChoiceChip(
                      selected: iconKey == option.key,
                      avatar: Icon(option.icon, size: 19),
                      label: Text(option.key),
                      onSelected: (_) => setState(() => iconKey = option.key),
                    ),
                  ),
              ],
            ),
          ),
        ],
    ];
  }

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? 'กรุณากรอกข้อมูล' : null,
    ),
  );
}

class _Search extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String hint;
  const _Search({required this.onChanged, required this.hint});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: hint,
      ),
    ),
  );
}

class _ProfileAvatar extends StatelessWidget {
  final Map<String, dynamic> user;
  const _ProfileAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = '${user['name'] ?? ''}'.trim();
    final url = '${user['avatar_url'] ?? user['avatar'] ?? ''}'.trim();
    return CircleAvatar(
      backgroundImage: url.isEmpty ? null : NetworkImage(url),
      onBackgroundImageError: url.isEmpty ? null : (_, __) {},
      child: url.isEmpty
          ? Text(name.isEmpty ? '?' : name.characters.first)
          : null,
    );
  }
}

class _StoreLogo extends StatelessWidget {
  final Map<String, dynamic> store;
  final double size;
  const _StoreLogo({required this.store, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final url = '${store['logo_url'] ?? ''}'.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? const ColoredBox(
                color: AppTheme.orangeSoft,
                child: Icon(Icons.storefront_outlined),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppTheme.orangeSoft,
                  child: Icon(Icons.storefront_outlined),
                ),
              ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final dynamic images;
  const _Thumb({required this.images});
  @override
  Widget build(BuildContext context) {
    final list = images is List ? images as List : const [];
    final path = list.isEmpty ? '' : '${list.first ?? ''}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: path.isEmpty
            ? const ColoredBox(
                color: AppTheme.orangeSoft,
                child: Icon(Icons.image_outlined),
              )
            : Image.network(
                path,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.broken_image_outlined),
              ),
      ),
    );
  }
}

class _FullImage extends StatelessWidget {
  final dynamic images;
  const _FullImage({required this.images});
  @override
  Widget build(BuildContext context) {
    final list = images is List ? images as List : const [];
    if (list.isEmpty)
      return const ColoredBox(
        color: AppTheme.orangeSoft,
        child: Icon(Icons.image_outlined, size: 48),
      );
    final path = '${list.first}';
    return Image.network(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
    );
  }
}

Future<bool> _confirm(BuildContext context, String text) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยัน'),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    ) ??
    false;
