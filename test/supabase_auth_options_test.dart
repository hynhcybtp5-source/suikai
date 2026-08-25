import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/data/supabase_repositories.dart';

void main() {
  test('keeps persisted session restore enabled', () {
    expect(SupabaseBackend.authOptions.persistSession, isTrue);
  });
}
