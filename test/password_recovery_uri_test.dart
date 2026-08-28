import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/core/password_recovery_uri.dart';

void main() {
  test('normalizes and validates recovery email without sending a request', () {
    expect(normalizeAuthEmail(' User@Example.COM '), 'user@example.com');
    expect(isValidAuthEmail('bad-email'), isFalse);
    expect(isValidAuthEmail(' user@example.com '), isTrue);
  });

  test('accepts only the dedicated password recovery deep link', () {
    expect(
      isPasswordRecoveryUri(Uri.parse(passwordRecoveryRedirectUrl)),
      isTrue,
    );
    expect(isPasswordRecoveryUri(Uri.parse('suikai://auth/telegram')), isFalse);
    expect(
      isPasswordRecoveryUri(Uri.parse('suikai://auth/reset-password/extra')),
      isFalse,
    );
  });
}
