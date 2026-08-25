/// Versioned legal documents required before a user publishes UGC.
///
/// Raise either value when its corresponding document changes. Existing users
/// will then be asked to explicitly accept the new pair before publishing.
class LegalVersions {
  const LegalVersions._();

  static const termsOfService = '1.0';
  static const communityGuidelines = '1.0';
}
