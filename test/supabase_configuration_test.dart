import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/data/supabase_repositories.dart';

void main() {
  test('accepts secure primary and fallback endpoint configuration', () {
    expect(
      SupabaseBackend.endpointForConfiguration(
        'https://ppyqkkwfnlyvyzxmhtvz.supabase.co',
      ).host,
      'ppyqkkwfnlyvyzxmhtvz.supabase.co',
    );
    expect(
      SupabaseBackend.endpointForConfiguration('https://api.suikai.shop').host,
      'api.suikai.shop',
    );
  });

  test('rejects insecure non-local Supabase URLs', () {
    expect(
      () => SupabaseBackend.endpointForConfiguration('http://example.com'),
      throwsA(isA<StateError>()),
    );
  });
}
