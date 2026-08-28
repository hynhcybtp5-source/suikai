import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/core/password_recovery_navigation_guard.dart';

void main() {
  test('deep link and recovery event open one reset page', () {
    final guard = PasswordRecoveryNavigationGuard();
    expect(guard.tryOpen(), isTrue); // deep link
    expect(guard.tryOpen(), isFalse); // PASSWORD_RECOVERY event
    guard.close();
    expect(guard.tryOpen(), isTrue);
  });
}
