const allowedParameters = [
  "code",
  "state",
  "error",
  "error_description",
] as const;

/// Builds the app hand-off without forwarding arbitrary query parameters.
/// PKCE verifier and tokens are intentionally never placed in this URL.
export function telegramAppRedirect(
  callbackUrl: URL,
  appRedirectUrl: string | undefined,
): Response {
  if (!appRedirectUrl) {
    return new Response("Missing TELEGRAM_APP_REDIRECT_URL", { status: 500 });
  }
  let target: URL;
  try {
    target = new URL(appRedirectUrl);
  } catch {
    return new Response("Invalid TELEGRAM_APP_REDIRECT_URL", { status: 500 });
  }
  for (const parameter of allowedParameters) {
    const value = callbackUrl.searchParams.get(parameter);
    if (value != null) target.searchParams.set(parameter, value);
  }
  return Response.redirect(target.toString(), 302);
}
