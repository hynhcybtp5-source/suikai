import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_theme.dart';
import '../services/suikai_service.dart';

class LocationPickerMap extends StatefulWidget {
  final LatLng? value;
  final ValueChanged<LatLng>? onChanged;
  final Future<LatLng?> Function()? currentLocation;
  final double height;

  const LocationPickerMap({
    super.key,
    this.value,
    this.onChanged,
    this.currentLocation,
    this.height = 300,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  static const _fallback = LatLng(20.8907, 97.1815);
  final MapController _controller = MapController();
  bool _locating = false;

  @override
  void didUpdateWidget(covariant LocationPickerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != oldWidget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.move(widget.value!, 15);
      });
    }
  }

  Future<void> _goToCurrentLocation() async {
    final locate = widget.currentLocation;
    if (locate == null || _locating) return;
    setState(() => _locating = true);
    try {
      final point = await locate();
      if (!mounted || point == null) return;
      widget.onChanged?.call(point);
      _controller.move(point, 16);
    } on LocationFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.userMessage)));
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Location picker current location failed: $error\n$stackTrace',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถอ่านตำแหน่งปัจจุบันได้')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.value;
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: selected ?? _fallback,
                initialZoom: selected == null ? 12 : 15,
                onTap: widget.onChanged == null
                    ? null
                    : (_, point) => widget.onChanged!(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.suikai.app',
                ),
                if (selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: selected,
                        width: 54,
                        height: 54,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on_rounded,
                          size: 48,
                          color: AppTheme.orange,
                        ),
                      ),
                    ],
                  ),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
            if (widget.currentLocation != null)
              Positioned(
                right: 12,
                bottom: 30,
                child: FloatingActionButton.small(
                  heroTag: null,
                  backgroundColor: Colors.white,
                  onPressed: _locating ? null : _goToCurrentLocation,
                  child: _locating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
