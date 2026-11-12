# Mobile alerts and private calls

## What users see

| Event | Android | iPhone |
| --- | --- | --- |
| Vehicle report, help, or emergency | High-priority notification with a full-screen intent when Android permits it; the alert screen opens when tapped. | Time Sensitive APNs alert on the lock screen, as a banner over another app, or while this app is foregrounded. The report screen opens after a tap. The alert has View and authenticated acknowledgement actions when the backend signing key is configured. |
| Incoming private app call | Opens the incoming-call screen while foregrounded. In the background, uses the same native full-screen overlay as report alerts when display-over-other-apps access is enabled, plus a high-priority full-screen call notification as fallback. View Incoming Call opens Answer/Decline; expired calls do not open an overlay. | PushKit VoIP push immediately reports a genuine call to CallKit. The system incoming-call screen can appear while the app is suspended or not running. |
| Unacknowledged report/help/emergency | One server-side reminder after 30 seconds by default; it updates the same Android notification ID. | One Time Sensitive reminder after 30 seconds by default. |

These are internet audio calls between app users. They do not dial a phone number or provide IVR. APNs, PushKit, Firebase push and CallKit do not require an IVR provider. Publishing an iOS app still requires the normal Apple developer account, and internet access/server hosting can have costs. STUN-only WebRTC may fail on restrictive networks; a TURN relay improves reliability.

### Android call startup

The native overlay has Answer and Decline buttons. Answer launches directly into a dedicated call navigator and automatically accepts the call without a second tap. This startup reads only local configuration and the signed-in marker; it does not wait for Firebase initialization, splash animation, the update gate, dashboard data, or push-token registration. Normal startup resumes after the call route closes. The full-screen notification also has Answer/Decline actions and uses the same direct entry path.

Overlay Decline sends the token-scoped rejection from Android without opening Flutter. If no HTTPS backend has been configured yet, it falls back to the direct Flutter decline route. Answer still needs Flutter's engine, microphone permission, and the existing WebRTC signaling/media connection; this change does not move Android audio into a Telecom service or promise an instant connection. The iPhone CallKit path is unchanged. Install a freshly rebuilt app to test the native changes.

## Configure the server

1. Deploy the backend with `pip install -r requirements.txt` and apply Alembic through revision `0026_otp_attempt_limit` (or let the startup compatibility schema checks add the same columns).
2. In Apple Developer, enable Push Notifications and VoIP for the app ID. Create an APNs authentication `.p8` key with VoIP push access. Mount that private file on the backend; never bundle or commit it.
3. Set `APNS_TEAM_ID`, `APNS_KEY_ID`, `APNS_BUNDLE_ID`, and `APNS_PRIVATE_KEY_PATH` on the backend. The current Xcode bundle ID is `com.divyanshgupta.parkingmudde`; `APNS_BUNDLE_ID` must match it. The server sends calls to the `<bundle ID>.voip` topic. Debug device tokens go to Apple's sandbox endpoint; release/TestFlight tokens go to production.
4. Set `ALERT_ACTION_SIGNING_KEY` to a separate random secret of at least 32 characters. Without it, alerts still arrive, but native acknowledgement buttons are omitted. `ALERT_REMINDERS_ENABLED=true` and `ALERT_REMINDER_DELAY_SECONDS=30` enable one reminder for a fresh, unacknowledged alert.
5. Keep the backend reachable by HTTPS. The iOS native call bridge deliberately accepts only an HTTPS backend URL.
6. Set `JWT_SECRET_KEY` to a unique random secret of at least 32 characters before enabling calls or push registration. The default development value disables signed mobile sessions. Existing signed-in users must log in again after this update to obtain a session; sessions expire after `MOBILE_SESSION_EXPIRE_DAYS` (seven days by default). Keep the key stable across server restarts.
7. Configure the existing email sender (`RESEND_API_KEY` plus `EMAIL_FROM`, or SMTP credentials) for mobile login codes. The server sends these codes to the account's registered email and never returns them to the client. Password login remains available when email delivery is unavailable.

The signed session is required for user reports, help and emergency submissions, push token registration, alert status changes, and starting a private call. Guard and police report clients must send their existing bearer token. Update the backend and all three clients together; an older signed-in client must log in again.

## Configure the iOS app

Open `ios/Runner.xcworkspace` on a Mac. Use the same bundle ID and signing team as the APNs key, and check the **Push Notifications** and **Background Modes** capabilities (Voice over IP, Audio, Remote notifications). The project already declares `voip`, `audio`, and `remote-notification` background modes and push/time-sensitive entitlements. The iOS Firebase setup must use the same app ID and must upload an APNs key to Firebase for ordinary report alerts.

Build and install on two physical devices with two accounts. A simulator cannot establish the real terminated-app PushKit path. Accept notification, microphone, and Time Sensitive permissions when prompted. After signing in, the app registers both its FCM and PushKit tokens. The backend must show `voip_enabled: true` from `POST /v1/calls/devices/ios` before a VoIP call can wake it; without Apple credentials it falls back to the ordinary FCM call alert.

Test a report alert, acknowledgement, reminder, and a call with the recipient app foregrounded, backgrounded, screen locked, and terminated. On iPhone, answer and hang up from CallKit and confirm two-way audio. On Android 14+, also verify the notification and full-screen intent permissions in system settings. Google Play limits automatic full-screen intent permission to apps providing calls or alarms, so a report alert may be shown as a heads-up notification instead. Android 13+ also presents full-screen intents as heads-up alerts while the device is unlocked. A force-stop from Android Settings prevents FCM delivery until the user opens the app again. OS Focus modes, notification preferences, network delivery, and force-quit behavior can still affect presentation; there is no app API that guarantees covering the screen for every report alert or every Android unlocked state.
