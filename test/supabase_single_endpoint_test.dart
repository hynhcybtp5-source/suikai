import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/data/supabase_repositories.dart';

void main() {
  test('uses the configured production URL as the sole Supabase endpoint', () {
    final endpoint = SupabaseBackend.endpointForConfiguration(
      'https://ppyqkkwfnlyvyzxmhtvz.supabase.co',
    );

    expect(endpoint.host, 'ppyqkkwfnlyvyzxmhtvz.supabase.co');
    expect(endpoint.scheme, 'https');
  });

  test('rejects insecure non-local Supabase URLs', () {
    expect(
      () => SupabaseBackend.endpointForConfiguration('http://example.com'),
      throwsA(isA<StateError>()),
    );
  });
}
