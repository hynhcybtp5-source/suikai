import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suikai/core/submission_guard.dart';
import 'package:suikai/l10n/app_localizations_en.dart';
import 'package:suikai/l10n/app_localizations_my.dart';
import 'package:suikai/l10n/app_localizations_shn.dart';
import 'package:suikai/l10n/app_localizations_th.dart';
import 'package:suikai/l10n/mobile_localizations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('listing submission enters loading once, succeeds, and cannot repeat', () async {
    const key = 'listing:status-test';

    expect(await SubmissionGuard.begin(key), SubmissionStartResult.allowed);
    expect(
      await SubmissionGuard.begin(key),
      SubmissionStartResult.alreadySubmitting,
    );

    await SubmissionGuard.succeed(key, referenceId: 'listing-1');
    expect(
      await SubmissionGuard.begin(key),
      SubmissionStartResult.alreadySubmitted,
    );
  });

  test('listing submission failure releases the form for retry', () async {
    const key = 'listing:retry-test';
    expect(await SubmissionGuard.begin(key), SubmissionStartResult.allowed);
    await SubmissionGuard.fail(key);
    expect(await SubmissionGuard.begin(key), SubmissionStartResult.allowed);
    await SubmissionGuard.fail(key);
  });

  test('shop request enters loading once, succeeds, and cannot repeat', () async {
    const key = 'open-store:status-test';

    expect(await SubmissionGuard.begin(key), SubmissionStartResult.allowed);
    expect(
      await SubmissionGuard.begin(key),
      SubmissionStartResult.alreadySubmitting,
    );

    await SubmissionGuard.succeed(key, referenceId: 'store-1');
    expect(
      await SubmissionGuard.begin(key),
      SubmissionStartResult.alreadySubmitted,
    );
  });

  test('shop request failure releases the form for retry', () async {
    const key = 'open-store:retry-test';
    expect(await SubmissionGuard.begin(key), SubmissionStartResult.allowed);
    await SubmissionGuard.fail(key);
    expect(await SubmissionGuard.begin(key), SubmissionStartResult.allowed);
    await SubmissionGuard.fail(key);
  });

  test('listing and shop status messages exist in all supported languages', () {
    final localizations = [
      AppLocalizationsTh(),
      AppLocalizationsEn(),
      AppLocalizationsMy(),
      AppLocalizationsShn(),
    ];
    const keys = [
      'กำลังส่งประกาศ...',
      'ลงประกาศสำเร็จ',
      'ลงประกาศไม่สำเร็จ กรุณาลองใหม่',
      'กำลังส่งคำขอเปิดร้าน...',
      'ส่งคำขอเปิดร้านแล้ว รอการอนุมัติ',
      'ส่งคำขอเปิดร้านไม่สำเร็จ กรุณาลองใหม่',
    ];

    for (final localization in localizations) {
      for (final key in keys) {
        expect(localization.source(key), isNotEmpty);
      }
    }

    expect(
      AppLocalizationsEn().source('กำลังส่งประกาศ...'),
      'Publishing listing...',
    );
    expect(
      AppLocalizationsMy().source('ส่งคำขอเปิดร้านแล้ว รอการอนุมัติ'),
      isNot('ส่งคำขอเปิดร้านแล้ว รอการอนุมัติ'),
    );
    expect(
      AppLocalizationsShn().source('กำลังส่งคำขอเปิดร้าน...'),
      isNot('กำลังส่งคำขอเปิดร้าน...'),
    );
  });
}
