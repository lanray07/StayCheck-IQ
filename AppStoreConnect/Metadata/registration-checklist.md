# App Store Connect Registration Checklist

Apple currently requires new app records to be created in App Store Connect on the web.

## New App fields

- Platform: iOS
- Name: StayCheck IQ
- Primary language: English (U.S.) / en-US
- Bundle ID: com.staycheckiq.app
- SKU: STAYCHECK-IQ-IOS-001
- User Access: Full Access

## App Information

- Primary category: Business
- Secondary category: Productivity
- Content rights: The app does not contain, show, or access third-party content.
- Age rating: use the App Store Connect questionnaire; expected result should be 4+ for the current feature set.

## Version 1.0 metadata

- Subtitle: see `en-US/subtitle.txt`
- Promotional text: see `en-US/promotional_text.txt`
- Description: see `en-US/description.txt`
- Keywords: see `en-US/keywords.txt`
- Review notes: see `en-US/review_notes.txt`
- Support URL: `https://lanray07.github.io/StayCheck-IQ/support.html`
- Privacy URL: `https://lanray07.github.io/StayCheck-IQ/privacy.html`
- Terms URL: `https://lanray07.github.io/StayCheck-IQ/terms.html`

## Screenshots

- iPhone 6.9-inch: `AppStoreAssets/Screenshots/en-US/iPhone-6.9`
- iPad 13-inch: `AppStoreAssets/Screenshots/en-US/iPad-13`

## Subscriptions

Create one subscription group named `StayCheck IQ Plans`, then create the products in `subscriptions.json`.

## Before Submit for Review

- Confirm GitHub Pages is live at `https://lanray07.github.io/StayCheck-IQ/`.
- Create the matching StoreKit products in App Store Connect.
- Upload a signed build from Xcode on macOS.
- Replace `REQUIRED_REAL_PHONE_NUMBER` in `AppStoreConnect/Forms/app-review-information.json`.
- Add GitHub repository secrets for metadata upload if using fastlane:
  - `APP_STORE_CONNECT_API_KEY_ID`
  - `APP_STORE_CONNECT_ISSUER_ID`
  - `APP_STORE_CONNECT_API_PRIVATE_KEY`
- Confirm export compliance and encryption answers.
- Confirm app privacy answers match the production backend behavior.
