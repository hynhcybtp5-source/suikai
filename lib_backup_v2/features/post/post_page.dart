import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/app_shell.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});
  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  bool storeProduct = false;
  String status = 'พร้อมขาย';
  String category = 'รถยนต์';

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 2,
      title: 'ลงประกาศขาย',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('ประเภทประกาศ', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            segments: const [ButtonSegment(value: false, icon: Icon(Icons.person_outline_rounded), label: Text('ประกาศทั่วไป')), ButtonSegment(value: true, icon: Icon(Icons.storefront_rounded), label: Text('สินค้าร้านค้า'))],
            selected: {storeProduct},
            onSelectionChanged: (v) => setState(() { storeProduct = v.first; status = 'พร้อมขาย'; }),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppTheme.orangeSoft, borderRadius: BorderRadius.circular(15)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.info_outline_rounded, color: AppTheme.orange), const SizedBox(width: 10), Expanded(child: Text(storeProduct ? 'สินค้าร้านค้าต้องมาจากร้านที่ได้รับอนุมัติแล้ว และมีสถานะ พร้อมขาย / หมด / ลบ' : 'ประกาศทั่วไปเผยแพร่ได้ทันที และมีสถานะ พร้อมขาย / จอง / ขายแล้ว', style: const TextStyle(fontSize: 12, height: 1.4)))]),
          ),
          const SizedBox(height: 18),
          const Text('รูปสินค้า', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          SizedBox(height: 98, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 5, separatorBuilder: (_, __) => const SizedBox(width: 10), itemBuilder: (_, i) => Container(width: 98, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(15)), child: i == 0 ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_outlined, color: AppTheme.orange), SizedBox(height: 5), Text('เพิ่มรูป', style: TextStyle(fontSize: 11))]) : const Icon(Icons.image_outlined, color: AppTheme.textSecondary)))),
          const SizedBox(height: 18),
          const TextField(decoration: InputDecoration(labelText: 'ชื่อสินค้า *', hintText: 'เช่น iPhone 13 Pro Max')),
          const SizedBox(height: 12),
          const TextField(keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'ราคา *', suffixText: 'Ks')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: category, decoration: const InputDecoration(labelText: 'หมวดหมู่'), items: const ['รถยนต์', 'มอเตอร์ไซค์', 'มือถือ', 'คอมพิวเตอร์', 'บ้าน', 'เสื้อผ้า', 'อื่นๆ'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => category = v!)),
          const SizedBox(height: 12),
          const TextField(maxLines: 4, decoration: InputDecoration(labelText: 'รายละเอียดสินค้า', alignLabelWithHint: true)),
          const SizedBox(height: 12),
          const TextField(decoration: InputDecoration(labelText: 'เมือง', hintText: 'Nam Chan', prefixIcon: Icon(Icons.location_city_outlined))),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: status, decoration: const InputDecoration(labelText: 'สถานะสินค้า'), items: (storeProduct ? ['พร้อมขาย', 'หมด', 'ลบ'] : ['พร้อมขาย', 'จอง', 'ขายแล้ว']).map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => status = v!)),
          const SizedBox(height: 12),
          const TextField(keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'เบอร์โทรศัพท์ *', prefixIcon: Icon(Icons.call_outlined))),
          const SizedBox(height: 12),
          const TextField(keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Viber', prefixIcon: Icon(Icons.chat_bubble_outline_rounded))),
          const SizedBox(height: 20),
          ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.publish_rounded), label: Text(storeProduct ? 'ลงสินค้าในร้าน' : 'เผยแพร่ประกาศ')),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
