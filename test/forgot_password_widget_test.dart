import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/features/auth/auth_page.dart';
import 'package:suikai/l10n/app_localizations.dart';
import 'package:suikai/services/suikai_service.dart';

import 'support/in_memory_repositories.dart';

class _RecoveryAuth extends InMemoryAuthRepository {
  Completer<void>? pending;
  @override
  Future<void> requestPasswordReset(String email) {
    passwordResetRequests++;
    return pending?.future ?? Future.value();
  }
}

void main() {
  late _RecoveryAuth auth;
  Future<void> pump(WidgetTester tester) async {
    auth = _RecoveryAuth();
    SuikaiService.auth = auth;
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginPage(pendingRoute: '/', observeAuth: false),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens forgot password dialog', (tester) async {
    await pump(tester);
    await open(tester);
    expect(find.text('Send link'), findsOneWidget);
  });

  testWidgets('invalid email does not call recovery', (tester) async {
    await pump(tester);
    await open(tester);
    await tester.enterText(find.byType(TextField).last, 'bad');
    await tester.tap(find.text('Send link'));
    await tester.pump();
    expect(auth.passwordResetRequests, 0);
  });

  testWidgets('valid email calls recovery once and shows generic success', (
    tester,
  ) async {
    await pump(tester);
    await open(tester);
    await tester.enterText(find.byType(TextField).last, 'a@example.com');
    await tester.tap(find.text('Send link'));
    await tester.pumpAndSettle();
    expect(auth.passwordResetRequests, 1);
    expect(
      find.text(
        'If an account exists for this email, a password reset link has been sent.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('pending recovery ignores duplicate submit', (tester) async {
    await pump(tester);
    auth.pending = Completer<void>();
    await open(tester);
    await tester.enterText(find.byType(TextField).last, 'a@example.com');
    await tester.tap(find.text('Send link'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton).last);
    await tester.pump();
    expect(auth.passwordResetRequests, 1);
    auth.pending!.complete();
    await tester.pumpAndSettle();
  });
}
