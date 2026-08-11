import 'package:flutter/material.dart';

import '../features/account/account_page.dart';
import '../features/home/home_page.dart';
import '../features/map/map_page.dart';
import '../features/post/post_page.dart';
import '../features/product/product_detail_page.dart';
import '../features/search/search_page.dart';
import '../features/stores/store_detail_page.dart';
import '../features/stores/stores_page.dart';

class AppRoutes {
  static const home = '/';
  static const stores = '/stores';
  static const post = '/post';
  static const map = '/map';
  static const account = '/account';
  static const search = '/search';
  static const productDetail = '/product';
  static const storeDetail = '/store';

  static Map<String, WidgetBuilder> get routes => {
        home: (_) => const HomePage(),
        stores: (_) => const StoresPage(),
        post: (_) => const PostPage(),
        map: (_) => const MapPage(),
        account: (_) => const AccountPage(),
        search: (_) => const SearchPage(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case productDetail:
        return MaterialPageRoute(
          builder: (_) => ProductDetailPage(productId: settings.arguments as String? ?? ''),
          settings: settings,
        );
      case storeDetail:
        return MaterialPageRoute(
          builder: (_) => StoreDetailPage(storeId: settings.arguments as String? ?? ''),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
