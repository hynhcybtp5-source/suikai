import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/features/legal/legal_pages.dart';

void main() {
  Future<void> pumpLegalPage(WidgetTester tester, Widget page) =>
      tester.pumpWidget(MaterialApp(home: page));

  testWidgets('privacy policy opens without an authenticated session', (
    tester,
  ) async {
    await pumpLegalPage(tester, const PrivacyPolicyPage());
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Information We Use'), findsOneWidget);
  });

  testWidgets(
    'terms and community guidelines open without an authenticated session',
    (tester) async {
      await pumpLegalPage(tester, const TermsOfServicePage());
      expect(find.text('Terms of Service'), findsOneWidget);
      await pumpLegalPage(tester, const CommunityGuidelinesPage());
      expect(find.text('Community Guidelines'), findsOneWidget);
      expect(find.text('Report, Block, and Moderation'), findsOneWidget);
    },
  );
}
