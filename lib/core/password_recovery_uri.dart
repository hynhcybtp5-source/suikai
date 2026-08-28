const passwordRecoveryRedirectUrl = 'suikai://auth/reset-password';

bool isPasswordRecoveryUri(Uri uri) =>
    uri.scheme == 'suikai' &&
    uri.host == 'auth' &&
    uri.path == '/reset-password';

String normalizeAuthEmail(String value) => value.trim().toLowerCase();

bool isValidAuthEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizeAuthEmail(value));
