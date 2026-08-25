# Suikai Google Play Submission Values

- Privacy Policy URL: `https://suikai-897bb.web.app/privacy-policy`
- Account Deletion URL: `https://suikai-897bb.web.app/delete-account`
- Developer Website: `https://suikai-897bb.web.app`
- Support Email: `suikai.app@gmail.com`

Use these release defines alongside the already verified production Supabase
defines. Do not use staging, localhost, or placeholder values:

```sh
--dart-define=SUIKAI_PRIVACY_POLICY_URL=https://suikai-897bb.web.app/privacy-policy \
--dart-define=SUIKAI_TERMS_URL=https://suikai-897bb.web.app/terms-of-service \
--dart-define=SUIKAI_COMMUNITY_GUIDELINES_URL=https://suikai-897bb.web.app/community-guidelines \
--dart-define=SUIKAI_DELETE_ACCOUNT_URL=https://suikai-897bb.web.app/delete-account \
--dart-define=SUIKAI_SUPPORT_EMAIL=suikai.app@gmail.com
```

Human Play Console declarations, final signed-AAB testing, and final release
approval remain required.
