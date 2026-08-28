/// The OAuth callback must use the same origin as the initialized Supabase
/// client. This keeps browser callbacks on the proxy during a fallback session.
Uri telegramCallbackUrlForEndpoint(Uri selectedEndpoint) {
  if (!selectedEndpoint.hasScheme || !selectedEndpoint.hasAuthority) {
    throw const FormatException('telegram_callback_endpoint_invalid');
  }
  if (selectedEndpoint.scheme != 'https') {
    throw const FormatException('telegram_callback_endpoint_must_use_https');
  }
  return selectedEndpoint.resolve('/functions/v1/telegram-callback');
}
