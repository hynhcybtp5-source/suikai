import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:suikai/core/submission_guard.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('blocks an in-flight submission and remembers a success', () async {
    const key = 'general-listing:test-session';

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

  test('releases a failed submission for a retry', () async {
    const key = 'open-store:test-session';
    expect(await SubmissionGuard.begin(key), SubmissionStartResult.allowed);
    await SubmissionGuard.fail(key);
    expect(await SubmissionGuard.begin(key), SubmissionStartResult.allowed);
  });

  test(
    'allows only one of several concurrent taps for the same form',
    () async {
      const key = 'store-product:store-1:rapid-taps';
      final results = await Future.wait(
        List<Future<SubmissionStartResult>>.generate(
          10,
          (_) => SubmissionGuard.begin(key),
        ),
      );

      expect(
        results.where((result) => result == SubmissionStartResult.allowed),
        hasLength(1),
      );
      expect(
        results.where(
          (result) => result == SubmissionStartResult.alreadySubmitting,
        ),
        hasLength(9),
      );
      await SubmissionGuard.fail(key);
    },
  );

  test(
    'a genuinely new form session is not blocked by an old session',
    () async {
      final oldKey = SubmissionGuard.newSessionKey(flow: 'general-listing');
      final newKey = SubmissionGuard.newSessionKey(flow: 'general-listing');
      expect(oldKey, isNot(newKey));

      expect(
        await SubmissionGuard.begin(oldKey),
        SubmissionStartResult.allowed,
      );
      await SubmissionGuard.succeed(oldKey, referenceId: 'listing-1');
      expect(
        await SubmissionGuard.begin(newKey),
        SubmissionStartResult.allowed,
      );
      await SubmissionGuard.fail(newKey);
    },
  );
}
