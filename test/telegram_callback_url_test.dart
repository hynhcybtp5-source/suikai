import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/core/telegram_callback_url.dart';

void main() {
  test('direct endpoint produces the Direct callback URL', () {
    expect(
      telegramCallbackUrlForEndpoint(
        Uri.parse('https://ppyqkkwfnlyvyzxmhtvz.supabase.co'),
      ).toString(),
      'https://ppyqkkwfnlyvyzxmhtvz.supabase.co/functions/v1/telegram-callback',
    );
  });

  test('fallback endpoint produces the proxy callback URL', () {
    expect(
      telegramCallbackUrlForEndpoint(
        Uri.parse('https://api.suikai.shop'),
      ).toString(),
      'https://api.suikai.shop/functions/v1/telegram-callback',
    );
  });

  test('callback keeps its selected origin when a later selection differs', () {
    final frozen = telegramCallbackUrlForEndpoint(
      Uri.parse('https://ppyqkkwfnlyvyzxmhtvz.supabase.co'),
    );
    final laterSelection = telegramCallbackUrlForEndpoint(
      Uri.parse('https://api.suikai.shop'),
    );
    expect(frozen.host, 'ppyqkkwfnlyvyzxmhtvz.supabase.co');
    expect(laterSelection.host, 'api.suikai.shop');
  });

  test('rejects malformed or insecure endpoints', () {
    expect(
      () => telegramCallbackUrlForEndpoint(Uri.parse('not a url')),
      throwsFormatException,
    );
    expect(
      () => telegramCallbackUrlForEndpoint(Uri.parse('http://example.com')),
      throwsFormatException,
    );
  });
}
