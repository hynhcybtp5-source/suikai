import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/features/admin/admin_dashboard.dart';

void main() {
  group('admin report review action', () {
    test('allows only pending reports to be marked reviewed', () {
      expect(canMarkReportReviewed({'reviewed': false}), isTrue);
      expect(canMarkReportReviewed({'reviewed': true}), isFalse);
    });

    test('filters reviewed reports from the pending queue', () {
      final reports = [
        {'id': 'pending', 'reviewed': false},
        {'id': 'reviewed', 'reviewed': true},
      ];

      expect(
        filterAdminReports(
          reports,
          AdminReportFilter.pending,
        ).map((report) => report['id']),
        ['pending'],
      );
      expect(filterAdminReports(reports, AdminReportFilter.all), reports);
    });

    test('uses clear labels for report status', () {
      expect(
        adminReportStatusLabel(
          {'reviewed': false},
          pendingLabel: 'Pending review',
          reviewedLabel: 'Reviewed',
        ),
        'Pending review',
      );
      expect(
        adminReportStatusLabel(
          {'reviewed': true},
          pendingLabel: 'Pending review',
          reviewedLabel: 'Reviewed',
        ),
        'Reviewed',
      );
    });

    test('uses listing and store names as report targets', () {
      expect(
        adminReportTargetName({
          'type': 'listing',
          'target_name': 'โทรศัพท์มือสอง',
        }, missingLabel: 'Information unavailable'),
        'โทรศัพท์มือสอง',
      );
      expect(
        adminReportTargetName({
          'type': 'store',
          'target_name': 'Suikai Phone Shop',
        }, missingLabel: 'Information unavailable'),
        'Suikai Phone Shop',
      );
      expect(
        adminReportTargetName({
          'type': 'user',
          'target_name': 'Nok',
        }, missingLabel: 'Information unavailable'),
        'Nok',
      );
    });

    test('uses a readable fallback for a missing target', () {
      const missing = 'Information unavailable';
      final report = {
        'target_name': '',
        'target_id': '12345678-90ab-cdef-1234-567890abcdef',
      };

      expect(adminReportTargetName(report, missingLabel: missing), missing);
      expect(adminReportTargetIdDetail(report), '12345678…');
    });

    test(
      'shows target moderation status without changing report review state',
      () {
        expect(adminReportTargetStatus({'target': null}), 'ถูกลบแล้ว');
        expect(
          adminReportTargetStatus({
            'target': {'status': 'available', 'is_hidden': true},
          }),
          'ซ่อนแล้ว',
        );
        expect(
          adminReportTargetStatus({
            'target': {'status': 'suspended'},
          }),
          'ระงับแล้ว',
        );
        expect(
          adminReportTargetStatus({
            'target': {'status': 'sold'},
          }),
          'ขายแล้ว',
        );
      },
    );
  });
}
