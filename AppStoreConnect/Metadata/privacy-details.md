# App Privacy Draft

Use this as a starting point for App Store Connect privacy questions. Confirm with your production privacy policy before submission.

## Current local mock build

- Data is stored locally on device with SwiftData.
- Mock AI mode is enabled by default.
- No account login is required.
- No API keys are stored in the iOS app.

## Data types the app may handle

- User Content: room photos, issue notes, checklist notes, inventory notes, report text.
- Identifiers: App Store subscription transaction data through StoreKit.
- Diagnostics: only if you add crash or analytics tooling later.

## Suggested privacy posture

- Photos and notes are used for app functionality.
- Photos and notes should not be used for third-party advertising.
- Production remote AI scanning should send images only to your secure backend endpoint.
- If production AI scanning stores or logs uploaded images, disclose that collection and retention clearly.

## Required production URLs

- Privacy Policy URL: replace `https://example.com/staycheck-iq/privacy`.
- Support URL: replace `https://example.com/staycheck-iq/support`.
