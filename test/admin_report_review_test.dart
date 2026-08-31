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
      expect(adminReportStatusLabel({'reviewed': false}), 'รอตรวจ');
      expect(adminReportStatusLabel({'reviewed': true}), 'ตรวจแล้ว');
    });
  });
}
