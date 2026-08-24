import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suikai/core/locale_controller.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('new install defaults to English', () async {
    await localeController.load();
    expect(localeController.locale.languageCode, 'en');
  });

  test('saved Thai locale is preserved', () async {
    SharedPreferences.setMockInitialValues({'selected_locale': 'th'});
    await localeController.load();
    expect(localeController.locale.languageCode, 'th');
  });

  test('saved Burmese locale is preserved', () async {
    SharedPreferences.setMockInitialValues({'selected_locale': 'my'});
    await localeController.load();
    expect(localeController.locale.languageCode, 'my');
  });

  test('saved Shan locale is preserved', () async {
    SharedPreferences.setMockInitialValues({'selected_locale': 'shn'});
    await localeController.load();
    expect(localeController.locale.languageCode, 'shn');
  });
}
