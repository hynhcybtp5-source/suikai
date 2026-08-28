/// Maps safe, user-facing listing publish messages without exposing proxy,
/// Storage, or HTTP implementation details in the UI.
class ListingPublishError {
  static String messageKeyFor(Object error) {
    final value = error.toString().toLowerCase();
    if (value.contains('video_duration_exceeds_30_seconds')) {
      return 'วิดีโอต้องยาวไม่เกิน 30 วินาที';
    }
    if (value.contains('video_size_exceeds_5_mb')) {
      return 'วิดีโอมีขนาดใหญ่เกินไป กรุณาเลือกหรือถ่ายวิดีโอใหม่';
    }
    if (value.contains('413') || value.contains('request entity too large')) {
      return 'ไฟล์มีขนาดใหญ่เกินกว่าที่ระบบรองรับ';
    }
    return 'ลงประกาศไม่สำเร็จ กรุณาลองใหม่';
  }
}
