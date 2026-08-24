import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shared presentation components for the Admin workspace.
class AdminTokens {
  AdminTokens._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double sidebarWidth = 244;
}

/// The one canonical ordering for sidebar destinations and TabBarView pages.
/// Never use a display-list position as a page index.
enum AdminSection {
  dashboard,
  users,
  listings,
  stores,
  storeProducts,
  reports,
  storeApprovals,
  categories,
  shortVideos,
  ads,
  analytics,
  map,
}

class AdminDestination {
  final String label;
  final IconData icon;
  final AdminSection section;
  final int badgeCount;
  const AdminDestination(
    this.label,
    this.icon,
    this.section, {
    this.badgeCount = 0,
  });
  int get tab => section.index;
}

class AdminShell extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onSelect;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final int notificationCount;
  final int pendingStores;
  final int pendingReports;
  final bool isBusy;
  final String? statusMessage;
  final String? errorMessage;
  final VoidCallback? onDismissError;
  final Widget child;
  const AdminShell({
    super.key,
    required this.selectedTab,
    required this.onSelect,
    required this.onRefresh,
    required this.onLogout,
    required this.notificationCount,
    this.pendingStores = 0,
    this.pendingReports = 0,
    this.isBusy = false,
    this.statusMessage,
    this.errorMessage,
    this.onDismissError,
    required this.child,
  });

  List<AdminDestination> get _destinations => [
    const AdminDestination(
      'ภาพรวม',
      Icons.dashboard_outlined,
      AdminSection.dashboard,
    ),
    const AdminDestination(
      'Analytics',
      Icons.insights_outlined,
      AdminSection.analytics,
    ),
    const AdminDestination(
      'ผู้ใช้งาน',
      Icons.people_outline_rounded,
      AdminSection.users,
    ),
    AdminDestination(
      'ประกาศสินค้า',
      Icons.sell_outlined,
      AdminSection.listings,
      badgeCount: notificationCount,
    ),
    const AdminDestination(
      'ร้านค้าทั้งหมด',
      Icons.storefront_outlined,
      AdminSection.stores,
    ),
    const AdminDestination(
      'สินค้าในร้าน',
      Icons.inventory_2_outlined,
      AdminSection.storeProducts,
    ),
    AdminDestination(
      'รายงาน',
      Icons.flag_outlined,
      AdminSection.reports,
      badgeCount: pendingReports,
    ),
    AdminDestination(
      'ร้านรออนุมัติ',
      Icons.fact_check_outlined,
      AdminSection.storeApprovals,
      badgeCount: pendingStores,
    ),
    const AdminDestination(
      'หมวดหมู่',
      Icons.category_outlined,
      AdminSection.categories,
    ),
    const AdminDestination(
      'วิดีโอสั้น',
      Icons.smart_display_outlined,
      AdminSection.shortVideos,
    ),
    const AdminDestination('โฆษณา', Icons.campaign_outlined, AdminSection.ads),
    const AdminDestination('แผนที่', Icons.map_outlined, AdminSection.map),
  ];

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    final body = Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AdminHeader(
        title: _destinations
            .firstWhere((item) => item.tab == selectedTab)
            .label,
        notificationCount: notificationCount,
        onRefresh: onRefresh,
        onLogout: onLogout,
      ),
      drawer: compact
          ? Drawer(
              child: AdminSidebar(
                destinations: _destinations,
                selectedTab: selectedTab,
                onSelect: (tab) {
                  Navigator.pop(context);
                  onSelect(tab);
                },
              ),
            )
          : null,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(compact ? AdminTokens.lg : AdminTokens.xl),
          child: Column(
            children: [
              if (isBusy || errorMessage != null)
                _AdminOperationStatus(
                  isBusy: isBusy,
                  message: errorMessage ?? statusMessage ?? 'กำลังดำเนินการ...',
                  isError: errorMessage != null,
                  onDismissError: onDismissError,
                ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
    if (compact) return body;
    return Row(
      children: [
        SizedBox(
          width: AdminTokens.sidebarWidth,
          child: AdminSidebar(
            destinations: _destinations,
            selectedTab: selectedTab,
            onSelect: onSelect,
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: body),
      ],
    );
  }
}

class _AdminOperationStatus extends StatelessWidget {
  final bool isBusy, isError;
  final String message;
  final VoidCallback? onDismissError;
  const _AdminOperationStatus({
    required this.isBusy,
    required this.isError,
    required this.message,
    this.onDismissError,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : AppTheme.orange;
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminTokens.md),
      child: Material(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AdminTokens.sm),
        child: ListTile(
          dense: true,
          leading: isError
              ? Icon(Icons.error_outline_rounded, color: color)
              : const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
          title: Text(message, style: TextStyle(color: color)),
          trailing: isError
              ? IconButton(
                  tooltip: 'ปิดข้อความ',
                  onPressed: onDismissError,
                  icon: const Icon(Icons.close_rounded),
                )
              : null,
        ),
      ),
    );
  }
}

class AdminSidebar extends StatelessWidget {
  final List<AdminDestination> destinations;
  final int selectedTab;
  final ValueChanged<int> onSelect;
  const AdminSidebar({
    super.key,
    required this.destinations,
    required this.selectedTab,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.white,
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AdminTokens.md),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AdminTokens.md,
              AdminTokens.md,
              AdminTokens.md,
              AdminTokens.xl,
            ),
            child: Row(
              children: [
                _BrandMark(),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suikai',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'ADMIN CONSOLE',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (final item in destinations) ...[
            if (item.tab == 2 || item.tab == 6 || item.tab == 8)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AdminTokens.md,
                  AdminTokens.lg,
                  AdminTokens.md,
                  AdminTokens.sm,
                ),
                child: Divider(height: 1),
              ),
            _AdminNavItem(
              item: item,
              selected: item.tab == selectedTab,
              onTap: () => onSelect(item.tab),
            ),
          ],
        ],
      ),
    ),
  );
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: AppTheme.orange,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 22),
  );
}

class _AdminNavItem extends StatelessWidget {
  final AdminDestination item;
  final bool selected;
  final VoidCallback onTap;
  const _AdminNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Material(
      color: selected ? AppTheme.orangeSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: selected ? AppTheme.orangeDark : AppTheme.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? AppTheme.orangeDark
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (item.badgeCount > 0) AdminCountBadge(count: item.badgeCount),
            ],
          ),
        ),
      ),
    ),
  );
}

class AdminHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int notificationCount;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  const AdminHeader({
    super.key,
    required this.title,
    required this.notificationCount,
    required this.onRefresh,
    required this.onLogout,
  });
  @override
  Size get preferredSize => const Size.fromHeight(72);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: MediaQuery.sizeOf(context).width < 900,
    titleSpacing: 24,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const Text(
          'Suikai Admin',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    ),
    actions: [
      IconButton(
        tooltip: 'รีเฟรชข้อมูล',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
      Badge(
        isLabelVisible: notificationCount > 0,
        label: Text('$notificationCount'),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.notifications_none_rounded),
        ),
      ),
      const SizedBox(width: 8),
      PopupMenuButton<String>(
        tooltip: 'บัญชีผู้ดูแล',
        onSelected: (value) {
          if (value == 'logout') onLogout();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'logout', child: Text('ออกจากระบบ')),
        ],
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: CircleAvatar(
            radius: 17,
            backgroundColor: AppTheme.orangeSoft,
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: AppTheme.orangeDark,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
    ],
  );
}

class AdminPageTitle extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? action;
  const AdminPageTitle({
    super.key,
    required this.title,
    this.description,
    this.action,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AdminTokens.xl),
    child: LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 560
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description!,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
                if (action != null) ...[const SizedBox(height: 12), action!],
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: const TextStyle(color: AppTheme.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
                ?action,
              ],
            ),
    ),
  );
}

class AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? note;
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.note,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AdminTokens.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.orangeSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.orangeDark),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textMuted)),
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(
              note!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.orangeDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class AdminCountBadge extends StatelessWidget {
  final int count;
  const AdminCountBadge({super.key, required this.count});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: AppTheme.orange,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        fontSize: 11,
        color: Colors.white,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class AdminStatusChip extends StatelessWidget {
  final String status;
  const AdminStatusChip({super.key, required this.status});
  @override
  Widget build(BuildContext context) {
    final value = status.toLowerCase();
    final color = value.contains('pending') || value.contains('reserved')
        ? AppTheme.warning
        : value.contains('approved') ||
              value.contains('available') ||
              value.contains('active')
        ? AppTheme.success
        : value.contains('rejected') ||
              value.contains('hidden') ||
              value.contains('suspended')
        ? AppTheme.danger
        : AppTheme.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(value),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _label(String value) => switch (value) {
    'pending' => 'รออนุมัติ',
    'approved' => 'อนุมัติแล้ว',
    'rejected' => 'ปฏิเสธ',
    'available' => 'พร้อมขาย',
    'reserved' => 'จองแล้ว',
    'sold' => 'ขายแล้ว',
    'hidden' => 'ถูกซ่อน',
    'suspended' => 'ระงับ',
    _ => status,
  };
}

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const AdminEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppTheme.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    ),
  );
}

class AdminFilterBar extends StatelessWidget {
  final Widget search;
  final Widget? filter;
  final VoidCallback? onClear;
  const AdminFilterBar({
    super.key,
    required this.search,
    this.filter,
    this.onClear,
  });
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AdminTokens.md),
      child: LayoutBuilder(
        builder: (context, c) => c.maxWidth < 620
            ? Column(
                children: [
                  search,
                  if (filter != null) ...[const SizedBox(height: 8), filter!],
                  if (onClear != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: onClear,
                        child: const Text('ล้างตัวกรอง'),
                      ),
                    ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: search),
                  if (filter != null) ...[
                    const SizedBox(width: 12),
                    SizedBox(width: 170, child: filter!),
                  ],
                  if (onClear != null)
                    TextButton(
                      onPressed: onClear,
                      child: const Text('ล้างตัวกรอง'),
                    ),
                ],
              ),
      ),
    ),
  );
}
