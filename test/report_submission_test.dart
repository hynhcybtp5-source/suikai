import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/data/models.dart';
import 'package:suikai/data/repositories.dart';
import 'package:suikai/services/suikai_service.dart';

class _RecordingReportRepository implements ReportRepository {
  final List<ReportRecord> values = [];
  bool rejectRepeats = false;

  @override
  Future<void> create(ReportRecord report) async {
    if (rejectRepeats && values.isNotEmpty) {
      throw StateError('rate_limited');
    }
    values.add(report);
  }
}

void main() {
  late _RecordingReportRepository reports;

  setUp(() {
    reports = _RecordingReportRepository();
    SuikaiService.reports = reports;
    SuikaiService.deviceId = 'report-submission-test-device';
  });

  test(
    'submits listing, store, and user targets with exactly one target',
    () async {
      await SuikaiService.submitReport(
        reason: 'Incorrect information',
        details: 'Listing detail',
        listingId: 'listing-id',
      );
      await SuikaiService.submitReport(
        reason: 'Misleading shop',
        details: '',
        storeId: 'store-id',
      );
      await SuikaiService.submitReport(
        reason: 'Impersonation',
        details: '',
        userId: 'user-id',
      );

      expect(reports.values.map((report) => report.type), [
        'listing',
        'store',
        'user',
      ]);
      expect(
        reports.values.first.reason,
        'Incorrect information: Listing detail',
      );
      expect(
        reports.values.every((report) => report.deviceId?.isNotEmpty == true),
        isTrue,
      );
    },
  );

  test(
    'does not require a local authenticated session before submission',
    () async {
      await SuikaiService.submitReport(
        reason: 'Anonymous report',
        details: '',
        listingId: 'listing-id',
      );

      expect(reports.values, hasLength(1));
    },
  );

  test('surfaces server duplicate throttling to the caller', () async {
    reports.rejectRepeats = true;
    await SuikaiService.submitReport(
      reason: 'Spam',
      details: '',
      listingId: 'listing-id',
    );

    await expectLater(
      SuikaiService.submitReport(
        reason: 'Spam',
        details: '',
        listingId: 'listing-id',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'rejects missing or multiple targets before calling the repository',
    () async {
      await expectLater(
        SuikaiService.submitReport(reason: 'Missing', details: ''),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        SuikaiService.submitReport(
          reason: 'Multiple',
          details: '',
          listingId: 'listing-id',
          storeId: 'store-id',
        ),
        throwsA(isA<StateError>()),
      );
      expect(reports.values, isEmpty);
    },
  );
}
