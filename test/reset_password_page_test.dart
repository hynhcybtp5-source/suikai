import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/features/auth/auth_page.dart';
import 'package:suikai/l10n/app_localizations.dart';
import 'package:suikai/services/suikai_service.dart';

import 'support/in_memory_repositories.dart';

class _RecordingAuth extends InMemoryAuthRepository {
  @override
  Future<void> updatePassword(String password) async {
    passwordUpdates++;
    if (passwordUpdateError != null) throw passwordUpdateError!;
  }
}

void main() {
  late _RecordingAuth auth;

  setUp(() {
    auth = _RecordingAuth();
    SuikaiService.auth = auth;
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ResetPasswordPage(),
    ),
  );

  testWidgets('short password is blocked before update', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).at(0), '12345');
    await tester.enterText(find.byType(TextField).at(1), '12345');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(auth.passwordUpdates, 0);
  });

  testWidgets('mismatched password is blocked before update', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).at(0), '123456');
    await tester.enterText(find.byType(TextField).at(1), '654321');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(auth.passwordUpdates, 0);
  });

  testWidgets('valid password updates once and returns to root', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField).at(0), '123456');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    expect(auth.passwordUpdates, 1);
  });
}
