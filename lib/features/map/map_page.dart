import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/app_shell.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentIndex: 3,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SimpleMapPainter())),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Color(0x18000000), blurRadius: 14),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search_rounded),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ค้นหาบนแผนที่',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 82,
            top: 210,
            child: _MapPin(label: 'รถยนต์', icon: Icons.directions_car_rounded),
          ),
          const Positioned(
            right: 62,
            top: 310,
            child: _MapPin(label: 'มือถือ', icon: Icons.smartphone_rounded),
          ),
          const Positioned(
            left: 150,
            bottom: 180,
            child: _MapPin(label: 'ร้านค้า', icon: Icons.storefront_rounded),
          ),
          Positioned(
            right: 16,
            bottom: 22,
            child: FloatingActionButton(
              heroTag: 'gps',
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.orange,
              onPressed: () {},
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MapPin({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x18000000), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.orange, size: 16),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.location_on_rounded, color: AppTheme.orange, size: 34),
      ],
    );
  }
}

class _SimpleMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFFF0F1EA);
    canvas.drawRect(Offset.zero & size, bg);

    final block = Paint()..color = const Color(0xFFE1E6D9);
    for (double x = 18; x < size.width; x += 92) {
      for (double y = 24; y < size.height; y += 86) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 64, 48),
            const Radius.circular(8),
          ),
          block,
        );
      }
    }

    final roadEdge = Paint()
      ..color = Colors.white
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final road = Paint()
      ..color = const Color(0xFFD6D8D2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final p1 = Path()
      ..moveTo(-20, size.height * .18)
      ..quadraticBezierTo(
        size.width * .45,
        size.height * .28,
        size.width + 20,
        size.height * .14,
      );
    final p2 = Path()
      ..moveTo(size.width * .25, -20)
      ..quadraticBezierTo(
        size.width * .55,
        size.height * .5,
        size.width * .35,
        size.height + 20,
      );
    final p3 = Path()
      ..moveTo(-20, size.height * .66)
      ..quadraticBezierTo(
        size.width * .55,
        size.height * .52,
        size.width + 20,
        size.height * .75,
      );
    for (final path in [p1, p2, p3]) {
      canvas.drawPath(path, roadEdge);
      canvas.drawPath(path, road);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
