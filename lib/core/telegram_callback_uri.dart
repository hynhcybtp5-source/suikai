bool isTelegramOAuthCallbackUri(Uri uri) =>
    uri.scheme == 'suikai' && uri.host == 'auth' && uri.path == '/telegram';

/// Keeps Suikai's Telegram authorization-code callback out of Supabase's
/// automatic URL session exchange. Other normal Supabase auth callbacks retain
/// the SDK's documented query/fragment parameter detection.
bool shouldSupabaseHandleAuthDeepLink(Uri uri) {
  if (isTelegramOAuthCallbackUri(uri)) return false;
  final fragmentParameters = Uri.splitQueryString(uri.fragment);
  return const {
    'access_token',
    'code',
    'error',
    'error_code',
    'error_description',
  }.any(
    (key) =>
        uri.queryParameters.containsKey(key) ||
        fragmentParameters.containsKey(key),
  );
}
