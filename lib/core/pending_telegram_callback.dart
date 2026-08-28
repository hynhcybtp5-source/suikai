import 'telegram_callback_uri.dart';

/// Holds at most one Telegram OAuth callback until Supabase is initialized.
/// It deliberately stores only the authorization callback URI: PKCE verifier
/// and state remain in their existing secure preference storage.
class PendingTelegramCallback {
  Uri? _pending;
  String? _handledFingerprint;
  bool _processing = false;

  bool get hasPending => _pending != null;

  /// Returns false for malformed or duplicate app-link delivery.
  bool capture(Uri uri) {
    if (!isTelegramOAuthCallbackUri(uri)) return false;
    if (!uri.queryParameters.containsKey('code') &&
        !uri.queryParameters.containsKey('error')) {
      return false;
    }
    final fingerprint = _fingerprint(uri);
    if (_processing ||
        _handledFingerprint == fingerprint ||
        (_pending != null && _fingerprint(_pending!) == fingerprint)) {
      return false;
    }
    _pending = uri;
    return true;
  }

  /// Claims and processes the pending callback exactly once. Bootstrap errors
  /// never call this method, so Network Blocked retry leaves it intact.
  Future<void> process(Future<void> Function(Uri uri) processor) async {
    final callback = _pending;
    if (callback == null || _processing) return;
    _processing = true;
    final fingerprint = _fingerprint(callback);
    try {
      await processor(callback);
    } finally {
      _pending = null;
      _handledFingerprint = fingerprint;
      _processing = false;
    }
  }

  String _fingerprint(Uri uri) {
    const keys = ['code', 'state', 'error', 'error_description'];
    final values = <String>[
      '${uri.scheme}://${uri.host}${uri.path}',
      for (final key in keys)
        if (uri.queryParameters.containsKey(key))
          '$key=${uri.queryParameters[key]}',
    ];
    return values.join('&');
  }
}
