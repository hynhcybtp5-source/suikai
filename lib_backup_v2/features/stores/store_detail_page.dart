import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/product_card.dart';

class StoreDetailPage extends StatelessWidget {
  final String storeId;
  const StoreDetailPage({super.key, required this.storeId});

  @override
  Widget build(BuildContext context) {
    final store = stores.firstWhere((s) => s.id == storeId, orElse: () => stores.first);
    final storeProducts = products.where((p) => p.storeId == store.id && p.status != ListingStatus.outOfStock).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดร้าน')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Row(children: [ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(store.logo, width: 92, height: 92, fit: BoxFit.cover)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(store.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))), const Icon(Icons.verified_rounded, color: AppTheme.orange)]), const SizedBox(height: 5), Text('${store.category} • ${store.city}', style: const TextStyle(color: AppTheme.textSecondary)), const SizedBox(height: 5), Text('เปิด ${store.hours}', style: const TextStyle(fontSize: 12))]))]),
                const SizedBox(height: 16),
                Row(children: [Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.call_rounded), label: const Text('โทร'))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline_rounded), label: const Text('Viber')))]),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(16, 18, 16, 10), child: Text('สินค้าในร้าน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)))),
          if (storeProducts.isEmpty)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('ยังไม่มีสินค้าพร้อมขาย'))))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverGrid.builder(
                itemCount: storeProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .70),
                itemBuilder: (_, i) => ProductCard(product: storeProducts[i]),
              ),
            ),
        ],
      ),
    );
  }
}
