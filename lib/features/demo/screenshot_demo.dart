// Local-only presentation mode for Google Play screenshot capture.
//
// It is deliberately opt-in at compile time (SUIKAI_SCREENSHOT_DEMO=true)
// and does not initialise SuikaiService or make any network request.
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const screenshotDemoMode = bool.fromEnvironment('SUIKAI_SCREENSHOT_DEMO');
const _requestedScreen = String.fromEnvironment(
  'SUIKAI_SCREENSHOT_SCREEN',
  defaultValue: 'home',
);

class ScreenshotDemoApp extends StatelessWidget {
  const ScreenshotDemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Suikai',
    theme: AppTheme.light,
    home: ScreenshotDemoScreen(screen: _requestedScreen),
  );
}

class ScreenshotDemoScreen extends StatefulWidget {
  const ScreenshotDemoScreen({super.key, required this.screen});
  final String screen;

  @override
  State<ScreenshotDemoScreen> createState() => _ScreenshotDemoScreenState();
}

class _ScreenshotDemoScreenState extends State<ScreenshotDemoScreen> {
  late String _screen = widget.screen;

  @override
  Widget build(BuildContext context) {
    final page = switch (_screen) {
      'detail' => const _ProductDetailDemo(),
      'categories' => const _CategoriesDemo(),
      'nearby' => const _NearbyDemo(),
      'sell' => const _SellDemo(),
      'profile' => const _ProfileShopDemo(),
      _ => const _HomeDemo(),
    };
    return Scaffold(
      body: SafeArea(child: page),
      bottomNavigationBar: _DemoBottomNavigation(
        selected: _screen == 'nearby'
            ? 2
            : _screen == 'profile'
            ? 3
            : _screen == 'categories'
            ? 1
            : 0,
        onSelect: (index) => setState(() {
          _screen = switch (index) {
            1 => 'categories',
            2 => 'nearby',
            3 => 'profile',
            _ => 'home',
          };
        }),
      ),
    );
  }
}

class _HomeDemo extends StatelessWidget {
  const _HomeDemo();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _TopBar(location: 'Tachileik, Shan State'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            const _SearchField(hint: 'Search products, shops and services'),
            const SizedBox(height: 22),
            const _SectionHeader(title: 'Browse categories', action: 'See all'),
            const SizedBox(height: 12),
            SizedBox(
              height: 92,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _CategoryChip('Vehicles', Icons.directions_car_outlined),
                  _CategoryChip('Phones', Icons.phone_android_outlined),
                  _CategoryChip('Home', Icons.chair_outlined),
                  _CategoryChip('Fashion', Icons.checkroom_outlined),
                  _CategoryChip('Food', Icons.fastfood_outlined),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
              title: 'Fresh finds near you',
              action: 'View all',
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: .67,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              children: const [
                _ProductCard(
                  title: 'City commuter bicycle',
                  price: 'MMK 280,000',
                  location: 'Tachileik',
                  icon: Icons.pedal_bike_outlined,
                  palette: _ProductPalette.sky,
                ),
                _ProductCard(
                  title: 'Handwoven market bag',
                  price: 'MMK 32,000',
                  location: 'Kengtung',
                  icon: Icons.shopping_bag_outlined,
                  palette: _ProductPalette.peach,
                ),
                _ProductCard(
                  title: 'Wooden side table',
                  price: 'MMK 95,000',
                  location: 'Muse',
                  icon: Icons.table_restaurant_outlined,
                  palette: _ProductPalette.mint,
                ),
                _ProductCard(
                  title: 'Travel coffee set',
                  price: 'MMK 46,000',
                  location: 'Lashio',
                  icon: Icons.coffee_maker_outlined,
                  palette: _ProductPalette.lilac,
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

class _ProductDetailDemo extends StatelessWidget {
  const _ProductDetailDemo();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: 24),
    children: [
      Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Icon(Icons.arrow_back_ios_new_rounded),
            Spacer(),
            Icon(Icons.ios_share_outlined),
            SizedBox(width: 16),
            Icon(Icons.favorite_border_rounded),
          ],
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: _ProductArt(
          icon: Icons.pedal_bike_outlined,
          palette: _ProductPalette.sky,
          height: 280,
        ),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'City commuter bicycle',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'MMK 280,000',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.orange,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 19,
                  color: AppTheme.textMuted,
                ),
                SizedBox(width: 5),
                Text(
                  'Tachileik, Shan State',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                Spacer(),
                Text(
                  'Posted today',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
            Divider(height: 30),
            Text(
              'Description',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 7),
            Text(
              'A clean, reliable bicycle for everyday trips around town. Includes a front basket and working lights.',
              style: TextStyle(height: 1.45, color: AppTheme.textSecondary),
            ),
            SizedBox(height: 18),
            _SellerCard(),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.favorite_border_rounded),
                    label: Text('Like'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    label: Text('Contact seller'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: Icon(Icons.flag_outlined, size: 18),
                label: Text(
                  'Report listing',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _CategoriesDemo extends StatelessWidget {
  const _CategoriesDemo();
  @override
  Widget build(BuildContext context) {
    const cats = [
      ('Vehicles', Icons.directions_car_outlined),
      ('Phones & tablets', Icons.phone_android_outlined),
      ('Home & garden', Icons.chair_outlined),
      ('Fashion', Icons.checkroom_outlined),
      ('Tools', Icons.handyman_outlined),
      ('Food & drinks', Icons.fastfood_outlined),
      ('Electronics', Icons.devices_outlined),
      ('Other', Icons.category_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(
            'Explore Suikai',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: _SearchField(hint: 'Search marketplace'),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 20),
            children: [
              const Text(
                'Categories',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 4,
                childAspectRatio: .82,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final item in cats)
                    _CategoryGridTile(label: item.$1, icon: item.$2),
                ],
              ),
              const SizedBox(height: 22),
              const _SectionHeader(
                title: 'Popular in Electronics',
                action: 'See all',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 176,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    SizedBox(
                      width: 154,
                      child: _ProductCard(
                        title: 'Compact speaker',
                        price: 'MMK 58,000',
                        location: 'Muse',
                        icon: Icons.speaker_outlined,
                        palette: _ProductPalette.lilac,
                      ),
                    ),
                    SizedBox(width: 12),
                    SizedBox(
                      width: 154,
                      child: _ProductCard(
                        title: 'Desk lamp',
                        price: 'MMK 25,000',
                        location: 'Lashio',
                        icon: Icons.lightbulb_outline,
                        palette: _ProductPalette.peach,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NearbyDemo extends StatelessWidget {
  const _NearbyDemo();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Text(
          'Nearby listings',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.orangeSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.my_location_rounded, color: AppTheme.orange),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Showing general results around Tachileik',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.tune_rounded, color: AppTheme.orange),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: const [
            _MapPreview(),
            SizedBox(height: 20),
            _SectionHeader(
              title: 'Within your selected area',
              action: 'Sort: Nearby',
            ),
            SizedBox(height: 12),
            _NearbyTile(
              title: 'Fresh garden herbs',
              price: 'MMK 8,000',
              place: 'Tachileik · 1.2 km',
              icon: Icons.eco_outlined,
              palette: _ProductPalette.mint,
            ),
            _NearbyTile(
              title: 'Bamboo storage basket',
              price: 'MMK 18,000',
              place: 'Tachileik · 2.4 km',
              icon: Icons.inventory_2_outlined,
              palette: _ProductPalette.peach,
            ),
            _NearbyTile(
              title: 'Motorcycle helmet',
              price: 'MMK 42,000',
              place: 'Tachileik · 3.1 km',
              icon: Icons.two_wheeler_outlined,
              palette: _ProductPalette.sky,
            ),
          ],
        ),
      ),
    ],
  );
}

class _SellDemo extends StatelessWidget {
  const _SellDemo();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
    children: [
      const Text(
        'Create listing',
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 6),
      const Text(
        'Share an item with your local community.',
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      const SizedBox(height: 20),
      Row(
        children: const [
          _PhotoSlot(icon: Icons.add_a_photo_outlined, label: 'Add photos'),
          SizedBox(width: 10),
          _PhotoSlot(icon: Icons.chair_outlined, label: 'Cover'),
          SizedBox(width: 10),
          _PhotoSlot(icon: Icons.image_outlined, label: 'Photo 2'),
        ],
      ),
      const SizedBox(height: 22),
      const _FormLabel('Title'),
      const _DemoInput(value: 'Handcrafted bamboo stool'),
      const SizedBox(height: 15),
      const _FormLabel('Category'),
      const _DemoInput(
        value: 'Home & garden',
        icon: Icons.chair_outlined,
        trailing: Icons.keyboard_arrow_down_rounded,
      ),
      const SizedBox(height: 15),
      const _FormLabel('Price'),
      const _DemoInput(value: 'MMK 75,000', icon: Icons.payments_outlined),
      const SizedBox(height: 15),
      const _FormLabel('Description'),
      const _DemoInput(
        value: 'Handmade bamboo stool in excellent condition.',
        multiline: true,
      ),
      const SizedBox(height: 15),
      const _FormLabel('Location'),
      const _DemoInput(
        value: 'Tachileik, Shan State',
        icon: Icons.location_on_outlined,
        trailing: Icons.map_outlined,
      ),
      const SizedBox(height: 22),
      ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.publish_outlined),
        label: const Text('Publish listing'),
      ),
      const SizedBox(height: 10),
      const Center(
        child: Text(
          'You review and accept the Terms & Community Guidelines before publishing.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ),
    ],
  );
}

class _ProfileShopDemo extends StatelessWidget {
  const _ProfileShopDemo();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
    children: [
      const Row(
        children: [
          Text(
            'My profile',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          Spacer(),
          Icon(Icons.settings_outlined),
        ],
      ),
      const SizedBox(height: 22),
      const Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: AppTheme.orangeSoft,
            child: Icon(
              Icons.person_outline_rounded,
              size: 38,
              color: AppTheme.orange,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'May Thiri',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 4),
                Text(
                  'Community seller · Tachileik',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                SizedBox(height: 8),
                _SellerBadge(),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      const Row(
        children: [
          Expanded(
            child: _Stat(value: '6', label: 'Listings'),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _Stat(value: '14', label: 'Likes'),
          ),
          SizedBox(width: 10),
          Expanded(
            child: _Stat(value: '4.9', label: 'Rating'),
          ),
        ],
      ),
      const SizedBox(height: 26),
      const Text(
        'My shop',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFFFEEE5),
                  child: Icon(
                    Icons.storefront_outlined,
                    color: AppTheme.orange,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Golden Bamboo Home',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Home & garden',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded),
              ],
            ),
            SizedBox(height: 15),
            Text(
              'Manage your shop details, listings, and customer messages.',
              style: TextStyle(color: AppTheme.textSecondary, height: 1.35),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const _SectionHeader(title: 'Active listings', action: 'Manage'),
      const SizedBox(height: 12),
      const _NearbyTile(
        title: 'Handcrafted bamboo stool',
        price: 'MMK 75,000',
        place: 'Active · Tachileik',
        icon: Icons.chair_outlined,
        palette: _ProductPalette.peach,
      ),
      const _NearbyTile(
        title: 'Woven floor mat',
        price: 'MMK 45,000',
        place: 'Active · Tachileik',
        icon: Icons.grid_4x4_outlined,
        palette: _ProductPalette.mint,
      ),
    ],
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.location});
  final String location;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Row(
      children: [
        const Spacer(),
        Icon(Icons.location_on_outlined, size: 18, color: AppTheme.orange),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            location,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint});
  final String hint;
  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Row(
      children: [
        const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
        const SizedBox(width: 10),
        Text(hint, style: const TextStyle(color: AppTheme.textSecondary)),
        const Spacer(),
        const Icon(Icons.tune_rounded, color: AppTheme.orange),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});
  final String title, action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const Spacer(),
      Text(
        action,
        style: const TextStyle(
          color: AppTheme.orange,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(this.label, this.icon);
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12),
    child: SizedBox(
      width: 74,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppTheme.orangeSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.orange),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _CategoryGridTile extends StatelessWidget {
  const _CategoryGridTile({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          color: AppTheme.orangeSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.orange),
      ),
      const SizedBox(height: 7),
      Text(
        label,
        maxLines: 2,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

enum _ProductPalette { sky, peach, mint, lilac }

extension on _ProductPalette {
  List<Color> get colors => switch (this) {
    _ProductPalette.sky => const [Color(0xFFD8F0FF), Color(0xFFB5DDF5)],
    _ProductPalette.peach => const [Color(0xFFFFE1CA), Color(0xFFFFC49B)],
    _ProductPalette.mint => const [Color(0xFFDDF6E5), Color(0xFFA8DDB8)],
    _ProductPalette.lilac => const [Color(0xFFEAE0FF), Color(0xFFCFC0F5)],
  };
}

class _ProductArt extends StatelessWidget {
  const _ProductArt({
    required this.icon,
    required this.palette,
    this.height = 130,
  });
  final IconData icon;
  final _ProductPalette palette;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: palette.colors,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Stack(
      children: [
        Positioned(
          right: -16,
          top: -18,
          child: Container(
            width: height * .58,
            height: height * .58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .35),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Center(
          child: Icon(
            icon,
            size: height * .43,
            color: AppTheme.textPrimary.withValues(alpha: .72),
          ),
        ),
      ],
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.title,
    required this.price,
    required this.location,
    required this.icon,
    required this.palette,
  });
  final String title, price, location;
  final IconData icon;
  final _ProductPalette palette;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ProductArt(icon: icon, palette: palette),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                price,
                style: const TextStyle(
                  color: AppTheme.orange,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 13,
                    color: AppTheme.textMuted,
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      location,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SellerCard extends StatelessWidget {
  const _SellerCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      border: Border.all(color: AppTheme.divider),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          backgroundColor: AppTheme.orangeSoft,
          child: Icon(Icons.person_outline, color: AppTheme.orange),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('May Thiri', style: TextStyle(fontWeight: FontWeight.w800)),
              SizedBox(height: 2),
              Text(
                'Community seller · Responds quickly',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
      ],
    ),
  );
}

class _MapPreview extends StatelessWidget {
  const _MapPreview();
  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    decoration: BoxDecoration(
      color: const Color(0xFFE6F2E7),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _MapLinesPainter())),
        const Positioned(left: 24, top: 24, child: _MapPin(label: '1.2 km')),
        const Positioned(right: 38, top: 78, child: _MapPin(label: '2.4 km')),
        const Positioned(
          left: 115,
          bottom: 26,
          child: _MapPin(label: '3.1 km'),
        ),
        Positioned(
          right: 14,
          bottom: 14,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: AppTheme.orange,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const Icon(Icons.location_on_rounded, color: AppTheme.orange, size: 26),
    ],
  );
}

class _MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final a = Path()
      ..moveTo(0, size.height * .73)
      ..cubicTo(
        size.width * .2,
        size.height * .5,
        size.width * .33,
        size.height * .95,
        size.width * .52,
        size.height * .5,
      )
      ..cubicTo(
        size.width * .72,
        size.height * .1,
        size.width * .84,
        size.height * .62,
        size.width,
        size.height * .28,
      );
    canvas.drawPath(a, p);
    final q = Paint()
      ..color = const Color(0xFFB9D6BB)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, size.height * .25),
      Offset(size.width, size.height * .82),
      q,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NearbyTile extends StatelessWidget {
  const _NearbyTile({
    required this.title,
    required this.price,
    required this.place,
    required this.icon,
    required this.palette,
  });
  final String title, price, place;
  final IconData icon;
  final _ProductPalette palette;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      height: 92,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: _ProductArt(icon: icon, palette: palette, height: 74),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    color: AppTheme.orange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  place,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
        ],
      ),
    ),
  );
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.orangeSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.orange.withValues(alpha: .22)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.orange),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.orange,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
  );
}

class _DemoInput extends StatelessWidget {
  const _DemoInput({
    required this.value,
    this.icon,
    this.trailing,
    this.multiline = false,
  });
  final String value;
  final IconData? icon, trailing;
  final bool multiline;
  @override
  Widget build(BuildContext context) => Container(
    height: multiline ? 72 : 50,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Row(
      crossAxisAlignment: multiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppTheme.orange, size: 20),
          const SizedBox(width: 9),
        ],
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: multiline ? 13 : 0),
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ),
        if (trailing != null) Icon(trailing, color: AppTheme.textMuted),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.divider),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.orange,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
        ),
      ],
    ),
  );
}

class _SellerBadge extends StatelessWidget {
  const _SellerBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF8EE),
      borderRadius: BorderRadius.circular(99),
    ),
    child: const Text(
      'Verified seller',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppTheme.success,
      ),
    ),
  );
}

class _DemoBottomNavigation extends StatelessWidget {
  const _DemoBottomNavigation({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selected,
    onDestinationSelected: onSelect,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'หน้าแรก',
      ),
      NavigationDestination(
        icon: Icon(Icons.storefront_outlined),
        selectedIcon: Icon(Icons.storefront_rounded),
        label: 'ร้านค้า',
      ),
      NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map_rounded),
        label: 'แผนที่',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline_rounded),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'โปรไฟล์',
      ),
    ],
  );
}
