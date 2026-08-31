import 'package:flutter_test/flutter_test.dart';
import 'package:suikai/features/admin/admin_dashboard.dart';

void main() {
  group('admin report review action', () {
    test('allows only pending reports to be marked reviewed', () {
      expect(canMarkReportReviewed({'reviewed': false}), isTrue);
      expect(canMarkReportReviewed({'reviewed': true}), isFalse);
    });
  });
}
