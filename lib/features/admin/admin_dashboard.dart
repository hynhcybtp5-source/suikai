import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models.dart';
import '../../services/suikai_service.dart';

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
              const Text(
                'Local Mock: admin@suikai.local / admin1234',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
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

class _AdminPanelState extends State<_AdminPanel> {
  Map<String, int> summary = {};
  List<Map<String, dynamic>> users = [],
      listings = [],
      stores = [],
      reports = [],
      editRequests = [],
      promotionRequests = [];
  List<CategoryRecord> categories = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final values = await Future.wait([
      SuikaiService.admin.summary(),
      SuikaiService.admin.users(),
      SuikaiService.admin.listings(),
      SuikaiService.admin.stores(),
      SuikaiService.admin.reports(),
      SuikaiService.admin.storeEditRequests(),
      SuikaiService.admin.promotionRequests(),
      SuikaiService.refreshCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      summary = values[0] as Map<String, int>;
      users = values[1] as List<Map<String, dynamic>>;
      listings = values[2] as List<Map<String, dynamic>>;
      stores = values[3] as List<Map<String, dynamic>>;
      reports = values[4] as List<Map<String, dynamic>>;
      editRequests = values[5] as List<Map<String, dynamic>>;
      promotionRequests = values[6] as List<Map<String, dynamic>>;
      categories = [
        ...SuikaiService.categoryRecords('store'),
        ...SuikaiService.categoryRecords('listing'),
      ];
      loading = false;
    });
  }

  Future<void> logout() async {
    await SuikaiService.admin.logout();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 8,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Suikai Admin'),
        actions: [
          IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded)),
          IconButton(onPressed: logout, icon: const Icon(Icons.logout_rounded)),
        ],
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: 'ภาพรวม'),
            Tab(text: 'สมาชิก'),
            Tab(text: 'ประกาศ'),
            Tab(text: 'ร้าน'),
            Tab(text: 'สินค้าในร้าน'),
            Tab(text: 'Reports'),
            Tab(text: 'คำร้องร้าน'),
            Tab(text: 'หมวดหมู่'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              children: [
                _Summary(summary: summary),
                _Users(rows: users, changed: load),
                _Listings(
                  rows: listings.where((e) => e['store_id'] == null).toList(),
                  changed: load,
                ),
                _Stores(rows: stores, changed: load),
                _Listings(
                  rows: listings.where((e) => e['store_id'] != null).toList(),
                  changed: load,
                  storeProducts: true,
                ),
                _Reports(rows: reports, changed: load),
                _StoreRequests(
                  edits: editRequests,
                  promotions: promotionRequests,
                  stores: stores,
                  changed: load,
                ),
                _Categories(rows: categories, changed: load),
              ],
            ),
    ),
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
                leading: CircleAvatar(
                  child: Text('${u['name'] ?? '?'}'.characters.first),
                ),
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
  final Future<void> Function() changed;
  final bool storeProducts;
  const _Listings({
    required this.rows,
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
                            ? const ['available', 'reserved', 'sold', 'hidden']
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

  Future<void> details(Map<String, dynamic> p) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
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
              'ID: ${p['id']}\nOwner: ${p['owner_id']}\nStore: ${p['store_id'] ?? '-'}\nCategory: ${p['category']}\nStatus: ${p['status']}\nPrice: ${p['price']} ${p['currency']}\n\n${p['description']}',
            ),
          ],
        ),
      ),
    ),
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
                leading: _Thumb(images: [s['logo_url']]),
                title: Text(
                  '${s['name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${s['status']} • ${s['category']} • Promote: ${s['is_promoted'] == true ? 'ON' : 'OFF'}\nOwner: ${s['owner_id']}',
                ),
                isThreeLine: true,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/store-detail',
                  arguments: s['id'],
                ),
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
  final List<Map<String, dynamic>> edits, promotions, stores;
  final Future<void> Function() changed;
  const _StoreRequests({
    required this.edits,
    required this.promotions,
    required this.stores,
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
  final Future<void> Function() changed;
  const _Categories({required this.rows, required this.changed});

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
              _CategoryList(type: 'store', rows: rows, changed: changed),
              _CategoryList(type: 'listing', rows: rows, changed: changed),
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
  final Future<void> Function() changed;
  const _CategoryList({
    required this.type,
    required this.rows,
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
          return ListTile(
            title: Text(category.nameTh),
            subtitle: Text(
              '${category.nameShn} • ${category.nameEn} • ${category.nameMy}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'เลื่อนขึ้น',
                  onPressed: index == 0 ? null : () => _move(index, -1),
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'เลื่อนลง',
                  onPressed: index == values.length - 1
                      ? null
                      : () => _move(index, 1),
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
            trailing: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FutureBuilder<int>(
                  future: SuikaiService.categoryUsageCount(category),
                  builder: (_, snapshot) => Tooltip(
                    message: 'จำนวนรายการที่ใช้งาน',
                    child: Chip(label: Text('${snapshot.data ?? 0}')),
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
                  tooltip: 'แก้ไข',
                  onPressed: () => _edit(context, category),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
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

  @override
  void initState() {
    super.initState();
    th = TextEditingController(text: widget.current?.nameTh ?? '');
    shn = TextEditingController(text: widget.current?.nameShn ?? '');
    en = TextEditingController(text: widget.current?.nameEn ?? '');
    my = TextEditingController(text: widget.current?.nameMy ?? '');
  }

  @override
  void dispose() {
    th.dispose();
    shn.dispose();
    en.dispose();
    my.dispose();
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
              id:
                  current?.id ??
                  '${widget.type}_${const Uuid().v4().replaceAll('-', '')}',
              type: widget.type,
              nameTh: th.text.trim(),
              nameShn: shn.text.trim(),
              nameEn: en.text.trim(),
              nameMy: my.text.trim(),
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
