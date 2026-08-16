import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:suikai/widgets/location_picker_map.dart';

void main() {
  testWidgets('tapping the map moves the selected marker', (tester) async {
    LatLng? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LocationPickerMap(
              value: selected,
              onChanged: (point) => setState(() => selected = point),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.location_on_rounded), findsNothing);
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    map.options.onTap!(
      const TapPosition(Offset.zero, Offset.zero),
      const LatLng(20.91, 97.19),
    );
    await tester.pump();

    expect(selected, isNotNull);
    expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
  });
}
