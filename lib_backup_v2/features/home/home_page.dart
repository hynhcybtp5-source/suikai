import 'package:flutter/material.dart';

import '../../core/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/product_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  RangeValues _price = const RangeValues(0, 100);
  int _category = 0;
  String _language = 'TH';

  @override
  Widget build(BuildContext context) {
    final visibleProducts = products.where((p) => p.status != ListingStatus.sold).toList();
    return AppShell(
      currentIndex: 0,
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: AppTheme.orange, borderRadius: BorderRadius.circular(13)),
                      child: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('Suikai', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -.5))),
                    PopupMenuButton<String>(
                      tooltip: 'ภาษา',
                      initialValue: _language,
                      onSelected: (value) => setState(() => _language = value),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'TH', child: Text('ไทย')),
                        PopupMenuItem(value: 'EN', child: Text('English')),
                        PopupMenuItem(value: 'MM', child: Text('မြန်မာ')),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [const Icon(Icons.language_rounded, size: 18), const SizedBox(width: 5), Text(_language, style: const TextStyle(fontWeight: FontWeight.w700))]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.search),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                    child: const Row(children: [Icon(Icons.search_rounded, color: AppTheme.textSecondary), SizedBox(width: 10), Expanded(child: Text('ค้นหาสินค้า', style: TextStyle(color: AppTheme.textSecondary))), Icon(Icons.tune_rounded, color: AppTheme.orange)]),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [const Text('ช่วงราคาที่ต้องการ', style: TextStyle(fontWeight: FontWeight.w700)), const Spacer(), Text('${_price.start.round()}M - ${_price.end.round()}M Ks', style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w800))]),
                      RangeSlider(values: _price, min: 0, max: 100, divisions: 100, labels: RangeLabels('${_price.start.round()}M', '${_price.end.round()}M'), onChanged: (v) => setState(() => _price = v)),
                      const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('0 Ks', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)), Text('100 ล้าน Ks', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary))]),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 18, 16, 10), child: Text('หมวดหมู่', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 88,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final selected = _category == i;
                    final item = categories[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _category = i),
                      child: Container(
                        width: 76,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(color: selected ? AppTheme.orangeSoft : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? AppTheme.orange : AppTheme.border)),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(item.icon, color: selected ? AppTheme.orange : AppTheme.textPrimary, size: 26), const SizedBox(height: 7), Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, color: selected ? AppTheme.orange : AppTheme.textPrimary))]),
                      ),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                height: 132,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF7A33), Color(0xFFF04F00)]), borderRadius: BorderRadius.circular(22)),
                child: const Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text('พื้นที่โฆษณา', style: TextStyle(color: Colors.white70, fontSize: 12)), SizedBox(height: 6), Text('โปรโมตร้านค้าของคุณ\nให้คนในพื้นที่เห็นมากขึ้น', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.25))])), Icon(Icons.campaign_rounded, color: Colors.white, size: 54)]),
              ),
            ),
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 10), child: Row(children: [Text('ประกาศล่าสุด', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Spacer(), Text('ดูทั้งหมด', style: TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w700))]))),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              sliver: SliverGrid.builder(
                itemCount: visibleProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .70),
                itemBuilder: (_, i) => ProductCard(product: visibleProducts[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
