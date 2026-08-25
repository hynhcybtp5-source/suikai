class LegalConfig {
  const LegalConfig._();

  static const _privacyPolicyUrl = String.fromEnvironment(
    'SUIKAI_PRIVACY_POLICY_URL',
  );
  static const _termsUrl = String.fromEnvironment('SUIKAI_TERMS_URL');
  static const _communityGuidelinesUrl = String.fromEnvironment(
    'SUIKAI_COMMUNITY_GUIDELINES_URL',
  );
  static const _externalAccountDeletionUrl = String.fromEnvironment(
    'SUIKAI_DELETE_ACCOUNT_URL',
  );
  static const _supportEmail = String.fromEnvironment('SUIKAI_SUPPORT_EMAIL');
  static const _developerName = String.fromEnvironment('SUIKAI_DEVELOPER_NAME');

  static Uri? get privacyPolicyUri => _safeHttpsUri(_privacyPolicyUrl);
  static Uri? get termsUri => _safeHttpsUri(_termsUrl);
  static Uri? get communityGuidelinesUri =>
      _safeHttpsUri(_communityGuidelinesUrl);

  /// Returns a production-safe account-deletion endpoint only. An unset,
  /// placeholder, local, or non-HTTPS value is intentionally hidden from UI.
  static Uri? get externalAccountDeletionUri {
    return _safeHttpsUri(_externalAccountDeletionUrl);
  }

  static String get privacyPolicyUrl => privacyPolicyUri?.toString() ?? '';
  static String get termsUrl => termsUri?.toString() ?? '';
  static String get communityGuidelinesUrl =>
      communityGuidelinesUri?.toString() ?? '';
  static String get externalAccountDeletionUrl =>
      externalAccountDeletionUri?.toString() ?? '';

  /// A missing or placeholder address must never be displayed as contact
  /// information in a production build.
  static String get supportEmail {
    final value = _supportEmail.trim();
    final isEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return isEmail && !_isPlaceholder(value) ? value : '';
  }

  static String get developerName {
    final value = _developerName.trim();
    return value.isNotEmpty && !_isPlaceholder(value) ? value : '';
  }

  /// Values required before submitting a release to Google Play. Keeping this
  /// list centralized prevents a placeholder URL or unmonitored address from
  /// being silently presented as production legal contact information.
  static List<String> get missingProductionValues => [
    if (privacyPolicyUri == null) 'SUIKAI_PRIVACY_POLICY_URL',
    if (termsUri == null) 'SUIKAI_TERMS_URL',
    if (communityGuidelinesUri == null) 'SUIKAI_COMMUNITY_GUIDELINES_URL',
    if (externalAccountDeletionUri == null) 'SUIKAI_DELETE_ACCOUNT_URL',
    if (supportEmail.isEmpty) 'SUIKAI_SUPPORT_EMAIL',
  ];

  static Uri? _safeHttpsUri(String rawValue) {
    final value = rawValue.trim();
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.isAbsolute ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        _isPlaceholder(uri.host) ||
        uri.host == 'localhost' ||
        uri.host.endsWith('.localhost')) {
      return null;
    }
    return uri;
  }

  static bool _isPlaceholder(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('example.') ||
        normalized.contains('your-domain') ||
        normalized.contains('your_email') ||
        normalized.contains('your-email') ||
        normalized.contains('placeholder') ||
        normalized.contains('todo');
  }
}
