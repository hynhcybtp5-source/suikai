# Suikai Google Play Data Safety Mapping

This is a source-code-based preparation document, not a submitted Play Console declaration. Reconfirm the deployed Supabase, proxy, hosting, and SDK configuration before submission.

## Collection and use

| Data category | Collected | Shared | Purpose | Required | Encrypted in transit | Deletion |
| --- | --- | --- | --- | --- | --- | --- |
| Name, profile photo, city | Yes | Public with a profile/listing where displayed; Supabase processes it | Account, marketplace profile, moderation | Name/city required for email registration; photo optional | Yes for production endpoints | In-app account deletion |
| Email address | Yes for email sign-up/profile | Supabase Auth/database | Account management, support/contact where supplied | Required for email sign-up; Telegram uses an internal synthetic auth address | Yes | In-app account deletion |
| Phone number and Viber number | Yes | Public on a listing/shop when the owner provides it; Supabase processes it; Viber is opened only by user action | Seller/customer contact, marketplace operation | Phone optional in code; Viber optional | Yes to Suikai | In-app account deletion |
| User IDs | Yes | Supabase; exposed in public listing payloads where needed by marketplace features | Account, ownership, moderation, abuse prevention | Required to use authenticated UGC features | Yes | In-app account deletion |
| Precise location | Yes when the user grants location permission and chooses location features | Supabase; public listing/shop/map data only when location visibility is enabled; map providers receive map requests | Nearby listings, map and location selection | Optional | Yes to Suikai and HTTPS map services | In-app account deletion for owned content; public visibility is user-controlled |
| Approximate location | Possibly derived from precise location or city; no separate coarse collector found | Same as above | Location-based marketplace features | Optional | Yes | Same as above |
| Photos and videos | Yes when a user uploads profile, shop, listing, or listing-video media | Supabase Storage; public media or signed video URLs are delivered to viewers as applicable | UGC marketplace content, profile/shop display | Optional except a current video listing requires video | Yes | In-app account deletion |
| User-generated content | Yes: listings, shops, descriptions, contact fields, reports, legal acceptance | Public where published; Supabase; administrators for moderation | Marketplace operation, moderation, fraud/abuse prevention | Required only for the feature used | Yes | Owned content is deleted by account deletion; report/security retention needs manual confirmation |
| App interactions | Yes: listing views, likes, blocks, reports, notification read state | Supabase | Marketplace operation, ranking, abuse prevention, notifications | Optional except feature actions | Yes | Account-linked actions are deleted; de-identified security/view data may remain as necessary |
| Device/application identifiers | Yes: locally generated random device ID; server stores hashes for likes, views, reports and rate limiting | Supabase | Counting interaction, rate limiting, anti-spam/abuse prevention | Automatic for relevant actions | Yes | **NEEDS MANUAL VERIFICATION** for retention/deletion of hashed anonymous identifiers |
| Notification-related data | Yes: in-app notification event type, payload, read state, recipient ID | Supabase | Inform users of marketplace/moderation events | Optional feature | Yes | In-app account deletion |
| Telegram identity data | If Telegram sign-in is used: Telegram subject ID, name, username, photo URL, phone number if supplied by Telegram | Telegram during OAuth; Suikai Edge Function and Supabase Auth metadata | Authentication/profile initialization | Optional sign-in method | Yes | In-app account deletion; Telegram's own retention is governed by Telegram |

## External services and links

- **Supabase** provides authentication, PostgreSQL data storage, Edge Functions, and Storage.
- **Telegram** processes the OAuth/OpenID sign-in flow when selected.
- **TikTok** receives a request when an administrator-provided embedded TikTok video is played.
- **OpenStreetMap** receives map tile requests. A user may open a Google Maps/map-direction link; that external app/site then applies its own privacy terms.
- **Viber** is opened only when a user elects to contact a seller. Telephone links likewise open the device dialer.
- **ExchangeRate-API** (`open.er-api.com`) is requested for THB exchange-rate display. The source does not send account fields in that request.

## Play Console decisions still requiring manual verification

- **Does the deployed proxy/logging layer collect IP addresses, user-agent, crash, or diagnostic data?** The Flutter repository does not establish this; mark **NEEDS MANUAL VERIFICATION**.
- **Is an advertising SDK, Analytics SDK, or Advertising ID present in the release AAB?** None is declared in `pubspec.yaml`; verify the resolved Android dependency tree and release manifest.
- **Are all production endpoints HTTPS and are TLS termination/proxies configured correctly?** Required before answering “encrypted in transit.”
- **Retention for reports, audit logs, and hashed anonymous identifiers** must be confirmed against deployed operations and backups.
- In Play Console, select purposes and sharing answers that match the deployed behavior, not this document alone.
