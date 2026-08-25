import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/core/operation_status.dart';

void main() {
  testWidgets('LoadingStatusView explains the active operation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LoadingStatusView(message: 'กำลังโหลดข้อมูลเริ่มต้น...'),
        ),
      ),
    );

    expect(find.text('กำลังโหลดข้อมูลเริ่มต้น...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(LoadingStatusView)).label,
      contains('กำลังโหลดข้อมูลเริ่มต้น...'),
    );
  });
}
