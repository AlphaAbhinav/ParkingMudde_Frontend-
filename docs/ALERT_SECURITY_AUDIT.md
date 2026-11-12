# Alert and private-call security audit

## Fixed in this round

- A forged `x-user-id` can no longer start a private call or create a user report. User reports, help and emergency submissions, push-token registration, and iOS VoIP registration require a signed mobile session.
- Guard and police reports require their existing role-specific bearer token. A pending report's plate can only be attached by its authenticated author; report confirmation now requires an admin session.
- A public caller can no longer create an urgent notification for another account, alter its status, mark it read, read its inbox/history, or delete it. Signed-in users and the matching guard/police wallet identity can access their own inbox.
- A pending emergency or help activity can only be attached once by its creator. Help completion cannot award the same reward twice. PostgreSQL row locks serialize these state changes and call creation for the same report.
- Login codes are sent to the registered email, never returned in the API response. Login, contact, and password-reset codes use cryptographic randomness, a resend cooldown, and a five-guess limit. The mobile client no longer shows or logs login codes or session tokens.
- Each report can initiate at most three private calls, and each recipient can receive at most five such calls per hour. Signaling is capped at 512 messages per participant per call.

## Deployment requirements

Set a unique `JWT_SECRET_KEY` with at least 32 characters on the backend and configure login email delivery. Apply Alembic revision `0026_otp_attempt_limit` or use the startup compatibility migration. Deploy the backend and updated user, guard, and police clients together. Existing mobile users must sign in again to receive a signed session; it expires after `MOBILE_SESSION_EXPIRE_DAYS` (seven by default).

## Remaining risks and verification

- Account registration does not verify ownership of the entered email or phone number. An attacker can create multiple accounts and submit reports, including repeated alerts about one vehicle across accounts. Add account verification and a per-target abuse limit before large-scale release.
- Mobile sessions are currently saved in `SharedPreferences`. A compromised or backed-up device can expose a token until it expires. Move tokens to Keychain/Android secure storage and add server-side session revocation.
- Other legacy API routes outside alerts still identify users using numeric IDs. Audit these before claiming account-wide protection.
- Push delivery after commit uses in-process threads. A backend restart between commit and send can lose a notification; a durable outbox is needed for stronger delivery guarantees.
- The iOS PushKit/CallKit path still needs physical iPhone tests with real APNs credentials. Test locked, foreground, background, and terminated states on both platforms, including network loss, token rotation, Focus/notification settings, and a rejected or expired call. The OS controls final full-screen presentation.

Targeted backend tests cover forged user/role headers, push-token takeover, urgent-push creation, inbox read/delete, status changes, plate attachment, OTP guessing, call limits and call expiry. Flutter tests cover an expired incoming call and the app shell. Static Dart analysis reported no errors or warnings in the touched API and alert files.
