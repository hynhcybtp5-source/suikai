import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/app_shell.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 4,
      title: 'จัดการ',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppTheme.orangeSoft, borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [CircleAvatar(radius: 27, backgroundColor: AppTheme.orange, child: Icon(Icons.person_outline_rounded, color: Colors.white, size: 30)), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ลูกค้าทั่วไปไม่ต้องล็อกอิน', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), SizedBox(height: 4), Text('เลือกดูสินค้า โทร หรือ Viber หาผู้ขายได้ทันที', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4))]))]),
          ),
          const SizedBox(height: 20),
          const Text('สำหรับผู้ขายและร้านค้า', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _MenuTile(icon: Icons.receipt_long_outlined, title: 'จัดการประกาศของฉัน', subtitle: 'ดูสถานะ พร้อมขาย / จอง / ขายแล้ว', onTap: () {}),
          _MenuTile(icon: Icons.storefront_outlined, title: 'เปิดร้านค้า', subtitle: 'สมัครร้านและรอการอนุมัติจาก Admin', onTap: () => _openShopSheet(context)),
          _MenuTile(icon: Icons.inventory_2_outlined, title: 'จัดการสินค้าในร้าน', subtitle: 'พร้อมขาย / หมด / ลบ', onTap: () {}),
          _MenuTile(icon: Icons.bar_chart_rounded, title: 'สถิติสินค้า', subtitle: 'ดูจำนวน Like และ View ของสินค้า', onTap: () {}),
          const SizedBox(height: 18),
          const Text('ระบบ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _MenuTile(icon: Icons.language_rounded, title: 'ภาษา', subtitle: 'ไทย / English / မြန်မာ', onTap: () {}),
          _MenuTile(icon: Icons.help_outline_rounded, title: 'ช่วยเหลือและรายงานปัญหา', subtitle: 'ติดต่อทีม Suikai', onTap: () {}),
          _MenuTile(icon: Icons.admin_panel_settings_outlined, title: 'City Admin', subtitle: 'เข้าสู่ระบบสำหรับผู้ดูแลพื้นที่', onTap: () {}),
        ],
      ),
    );
  }

  void _openShopSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('สมัครเปิดร้านค้า', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('ร้านค้าจะเริ่มแสดงหลัง Admin อนุมัติ', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 18),
          const TextField(decoration: InputDecoration(labelText: 'ชื่อร้าน *')),
          const SizedBox(height: 10),
          const TextField(decoration: InputDecoration(labelText: 'เบอร์โทร')),
          const SizedBox(height: 10),
          const TextField(decoration: InputDecoration(labelText: 'ประเภทร้าน')),
          const SizedBox(height: 10),
          const TextField(decoration: InputDecoration(labelText: 'เวลาเปิด - ปิด')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('ส่งคำขอเปิดร้าน'))),
        ]),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: Container(width: 42, height: 42, decoration: BoxDecoration(color: AppTheme.orangeSoft, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.orange)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
