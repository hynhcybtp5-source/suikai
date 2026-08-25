# External account-deletion page

Deploy the `web/` legal pages at a public HTTPS host. Before publishing, set
real monitored values in `delete-account-config.js` (or inject them during
deployment): `supportEmail`, the published legal URLs, and the deletion URL.
Do not submit any page to Google Play until that contact channel is configured.

Build the Flutter app with the matching URL so legal screens can reference it:

```sh
flutter build appbundle --release \
  --dart-define=SUIKAI_PRIVACY_POLICY_URL=https://YOUR_DOMAIN/privacy-policy.html \
  --dart-define=SUIKAI_TERMS_URL=https://YOUR_DOMAIN/terms-of-service.html \
  --dart-define=SUIKAI_COMMUNITY_GUIDELINES_URL=https://YOUR_DOMAIN/community-guidelines.html \
  --dart-define=SUIKAI_DELETE_ACCOUNT_URL=https://YOUR_DOMAIN/delete-account \
  --dart-define=SUIKAI_SUPPORT_EMAIL=suikai.app@gmail.com \
  --dart-define=SUIKAI_DEVELOPER_NAME=YOUR_LEGAL_DEVELOPER_NAME
```

The repository intentionally contains no production domain, address, or
service-role secret.

Before sending the app for Google Play review, publish `privacy-policy.html`,
`terms-of-service.html`, `community-guidelines.html`, and `delete-account.html`
at public HTTPS URLs. Add the Privacy Policy and deletion URLs plus Data Safety
and data-deletion declarations in Play Console. Do not use a placeholder URL,
email, or domain.

The Flutter Web app exposes its legal pages on static-hosting-safe hash URLs:

- `https://YOUR_DOMAIN/#/privacy`
- `https://YOUR_DOMAIN/#/terms`
- `https://YOUR_DOMAIN/#/community-guidelines`

Verify each URL in an incognito browser after deployment. If the host supports
Flutter path-route rewrites, the equivalent `/privacy`, `/terms`, and
`/community-guidelines` paths are also supported.
