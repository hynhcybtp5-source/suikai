import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock_data.dart';
import '../../widgets/product_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final result = products.where((p) => p.status != ListingStatus.sold && (query.isEmpty || p.title.toLowerCase().contains(query.toLowerCase()) || p.category.toLowerCase().contains(query.toLowerCase()))).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('ค้นหา')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: TextField(autofocus: true, onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(hintText: 'ค้นหาสินค้า หรือหมวดหมู่', prefixIcon: Icon(Icons.search_rounded), suffixIcon: Icon(Icons.tune_rounded, color: AppTheme.orange)))),
        Expanded(
          child: result.isEmpty
              ? const Center(child: Text('ไม่พบสินค้า'))
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  itemCount: result.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .70),
                  itemBuilder: (_, i) => ProductCard(product: result[i]),
                ),
        ),
      ]),
    );
  }
}
