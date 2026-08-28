import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/core/supabase_media_url.dart';

final _direct = Uri.parse('https://ppyqkkwfnlyvyzxmhtvz.supabase.co');
final _fallback = Uri.parse('https://api.suikai.shop');
const _legacyUrl =
    'https://ppyqkkwfnlyvyzxmhtvz.supabase.co/storage/v1/object/sign/listing-thumbnails/a.jpg?token=opaque-token&download=1';

void main() {
  test('rewrites a direct legacy URL when fallback is selected', () {
    expect(
      normalizeSupabaseMediaUrl(_legacyUrl, _fallback),
      'https://api.suikai.shop/storage/v1/object/sign/listing-thumbnails/a.jpg?token=opaque-token&download=1',
    );
  });

  test('keeps a direct legacy URL when direct is selected', () {
    expect(normalizeSupabaseMediaUrl(_legacyUrl, _direct), _legacyUrl);
  });

  test('keeps an existing proxy URL when fallback is selected', () {
    const proxyUrl =
        'https://api.suikai.shop/storage/v1/object/public/listing-images/a.jpg';
    expect(normalizeSupabaseMediaUrl(proxyUrl, _fallback), proxyUrl);
  });

  test('keeps external URLs unchanged', () {
    const externalUrl = 'https://example.com/storage/v1/object/public/a.jpg';
    expect(normalizeSupabaseMediaUrl(externalUrl, _fallback), externalUrl);
  });

  test('preserves path and signed query parameters', () {
    final normalized = Uri.parse(
      normalizeSupabaseMediaUrl(_legacyUrl, _fallback),
    );
    expect(normalized.path, '/storage/v1/object/sign/listing-thumbnails/a.jpg');
    expect(normalized.query, 'token=opaque-token&download=1');
  });

  test('malformed URLs do not throw or change', () {
    expect(
      normalizeSupabaseMediaUrl('://not a uri', _fallback),
      '://not a uri',
    );
  });
}
