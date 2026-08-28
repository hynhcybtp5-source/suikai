import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/core/pending_telegram_callback.dart';

Uri callback({String state = 'state'}) => Uri(
  scheme: 'suikai',
  host: 'auth',
  path: '/telegram',
  queryParameters: {'code': 'synthetic', 'state': state},
);

void main() {
  test('cold-start callback is preserved until bootstrap is ready', () async {
    final pending = PendingTelegramCallback();
    expect(pending.capture(callback()), isTrue);
    expect(pending.hasPending, isTrue);
    var calls = 0;
    await pending.process((_) async => calls++);
    expect(calls, 1);
    expect(pending.hasPending, isFalse);
  });

  test('duplicate app-link delivery processes only once', () async {
    final pending = PendingTelegramCallback();
    final uri = callback();
    expect(pending.capture(uri), isTrue);
    expect(pending.capture(uri), isFalse);
    var calls = 0;
    await pending.process((_) async => calls++);
    expect(pending.capture(uri), isFalse);
    expect(calls, 1);
  });

  test(
    'duplicate delivery with reordered query parameters processes once',
    () async {
      final pending = PendingTelegramCallback();
      final first = Uri.parse(
        'suikai://auth/telegram?code=synthetic&state=state',
      );
      final reordered = Uri.parse(
        'suikai://auth/telegram?state=state&code=synthetic',
      );
      expect(pending.capture(first), isTrue);
      var calls = 0;
      await pending.process((_) async => calls++);
      expect(pending.capture(reordered), isFalse);
      expect(calls, 1);
    },
  );

  test(
    'different callback stays pending after a failed bootstrap attempt',
    () async {
      final pending = PendingTelegramCallback();
      expect(pending.capture(callback()), isTrue);
      // No process call models Network Blocked before Supabase is ready.
      expect(pending.hasPending, isTrue);
      var receivedState = '';
      await pending.process((uri) async {
        receivedState = uri.queryParameters['state']!;
      });
      expect(receivedState, 'state');
    },
  );

  test('invalid state-shaped or malformed app links are rejected', () {
    final pending = PendingTelegramCallback();
    expect(pending.capture(Uri.parse('suikai://auth/telegram')), isFalse);
    expect(pending.capture(Uri.parse('suikai://auth/wrong?code=x')), isFalse);
  });
}
