import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/core/telegram_callback_uri.dart';

void main() {
  test('accepts only the Telegram OAuth callback URI', () {
    expect(
      isTelegramOAuthCallbackUri(
        Uri(scheme: 'suikai', host: 'auth', path: '/telegram'),
      ),
      isTrue,
    );
    expect(
      isTelegramOAuthCallbackUri(Uri(scheme: 'suikai', host: 'login-callback')),
      isFalse,
    );
    expect(
      isTelegramOAuthCallbackUri(
        Uri(scheme: 'suikai', host: 'auth', path: '/other'),
      ),
      isFalse,
    );
  });

  test('keeps the Telegram callback out of Supabase URL session exchange', () {
    expect(
      shouldSupabaseHandleAuthDeepLink(
        Uri(
          scheme: 'suikai',
          host: 'auth',
          path: '/telegram',
          queryParameters: {'code': 'telegram-code', 'state': 'state'},
        ),
      ),
      isFalse,
    );
    expect(
      shouldSupabaseHandleAuthDeepLink(
        Uri(
          scheme: 'suikai',
          host: 'auth',
          path: '/supabase-callback',
          queryParameters: {'code': 'supabase-code'},
        ),
      ),
      isTrue,
    );
  });
}
