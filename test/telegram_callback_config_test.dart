import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const expected = 'https://api.suikai.shop/functions/v1/telegram-callback';
  for (final path in ['dart_defines.json', 'dart_defines.production.json']) {
    test('$path uses the proxy callback and not Direct Supabase', () {
      final file = File(path);
      if (!file.existsSync()) return;
      final config =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final callback = config['TELEGRAM_CALLBACK_URL'] as String?;
      expect(callback, expected);
      expect(
        callback,
        isNot(contains('.supabase.co/functions/v1/telegram-callback')),
      );
    });
  }
}
