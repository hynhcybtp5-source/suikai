const supabaseProjectHost = 'ppyqkkwfnlyvyzxmhtvz.supabase.co';

/// Rewrites only legacy absolute media URLs from Suikai's Supabase project to
/// the endpoint selected for this app session. Path and query remain intact.
String normalizeSupabaseMediaUrl(String value, Uri selectedEndpoint) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasScheme ||
      !uri.hasAuthority ||
      uri.host != supabaseProjectHost ||
      selectedEndpoint.host == supabaseProjectHost) {
    return value;
  }
  return uri
      .replace(
        scheme: selectedEndpoint.scheme,
        host: selectedEndpoint.host,
        port: selectedEndpoint.hasPort ? selectedEndpoint.port : null,
      )
      .toString();
}
