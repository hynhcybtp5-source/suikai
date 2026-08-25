# Suikai Google Play Console Publishing Checklist

Complete and retain evidence for each item before production submission.

## Hosted legal-page verification

The permanent Firebase Hosting URLs were verified over HTTPS on 2026-08-23:

- Privacy Policy: `https://suikai-897bb.web.app/privacy-policy`
- Terms of Service: `https://suikai-897bb.web.app/terms-of-service`
- Community Guidelines: `https://suikai-897bb.web.app/community-guidelines`
- Account Deletion: `https://suikai-897bb.web.app/delete-account`

## Exact Google Play values

- Privacy Policy URL: `https://suikai-897bb.web.app/privacy-policy`
- Account Deletion URL: `https://suikai-897bb.web.app/delete-account`
- Developer Website: `https://suikai-897bb.web.app`
- Support Email: `suikai.app@gmail.com`

The permanent legal pages were promoted by cloning a preview built from the
existing live Flutter assets, with the reviewed legal files added. The live
`main.dart.js` SHA-256 remained `518a25453ad79f848105f49dd5476cc5f8f5e381a5063c6f9b73f8880729457c`.

- [ ] Publish an HTTPS English Privacy Policy and configure `SUIKAI_PRIVACY_POLICY_URL`.
- [ ] Publish an HTTPS English account-deletion page and configure `SUIKAI_DELETE_ACCOUNT_URL`.
- [x] Use `suikai.app@gmail.com` as the real monitored `SUIKAI_SUPPORT_EMAIL` release define and Google Play support contact.
- [ ] Configure external Terms and Community Guidelines URLs if used: `SUIKAI_TERMS_URL` and `SUIKAI_COMMUNITY_GUIDELINES_URL`.
- [ ] Complete Data Safety from [DATA_SAFETY.md](DATA_SAFETY.md), including deletion and encryption answers.
- [ ] Complete the Data deletion questionnaire and verify account deletion using a non-admin test account.
- [ ] Provide App Access instructions and reviewer credentials/test account if any feature is gated. State how to test email and Telegram sign-in and UGC reporting.
- [ ] Complete Ads declaration. Verify whether advertisements are served and whether any release dependency uses an Advertising ID.
- [ ] Complete Content rating questionnaire accurately for a moderated marketplace with UGC, external contact links, and TikTok embeds.
- [ ] Select target audience; do not designate the app as Families unless all Families requirements are intentionally met.
- [ ] Complete store listing: English app name, short/full descriptions, category, support email, privacy-policy URL, contact details.
- [ ] Upload final app icon, feature graphic, phone screenshots, and any tablet/other-device screenshots claimed by the listing.
- [ ] Enroll in Play App Signing and upload a signed release AAB with the intended package name/version code.
- [ ] Complete closed testing and tester-feedback requirements applicable to the developer account before production access.
- [ ] Re-test report, block, moderation, account deletion, UGC legal acceptance, location permission denial, external links, and video upload on the release build.
- [ ] Verify public legal/deletion URLs in an incognito browser and on mobile without signing in.
