# StayCheck IQ

StayCheck IQ is a SwiftUI iOS app for Airbnb and short-let turnover inspections. It includes local SwiftData persistence, mock AI room scans enabled by default, StoreKit 2 subscription scaffolding, photo proof, inventory tracking, issue reports, guest-ready scoring, local reminders, native PDF generation, and sharing.

## Open in Xcode

Open `StayCheckIQ.xcodeproj`, select the `StayCheck IQ` scheme, and run on an iOS 17+ simulator or device.

## Mock AI and backend

The app injects `MockAIService` by default in `StayCheckIQApp.swift`. `RemoteAIService` is scaffolded for:

```text
POST https://YOUR_BACKEND_URL.com/staycheck-iq
```

Never store API keys in the iOS app. Put provider credentials in your backend and have the app call only your secure endpoint.

## StoreKit product IDs

Configured placeholders:

- `com.staycheckiq.pro.monthly`
- `com.staycheckiq.pro.yearly`
- `com.staycheckiq.business.monthly`

Create matching products in App Store Connect or a local StoreKit configuration file before testing real purchases.

## Notes

This workspace was generated on Windows, where `xcodebuild` and `xcrun` are not installed. Static validation was performed here; perform the final compile/run pass in Xcode on macOS.

## App Store Connect assets

Submission assets and metadata drafts live in `AppStoreConnect/`:

- App icon: `AppStoreConnect/AppStoreAssets/AppIcon/staycheck-iq-appstore-1024.png`
- iPhone 6.9-inch screenshots: `AppStoreConnect/AppStoreAssets/Screenshots/en-US/iPhone-6.9/`
- iPad 13-inch screenshots: `AppStoreConnect/AppStoreAssets/Screenshots/en-US/iPad-13/`
- Metadata and registration checklist: `AppStoreConnect/Metadata/`

The repo also includes:

- GitHub Pages support site in `docs/`
- GitHub Actions Xcode simulator build in `.github/workflows/ios-xcodebuild.yml`
- Manual fastlane metadata upload workflow in `.github/workflows/appstore-metadata.yml`
- Filled App Store form drafts in `AppStoreConnect/Forms/`
- Fastlane metadata mirror in `fastlane/metadata/`

The support, privacy, and terms pages are published from the `gh-pages` branch at `https://lanray07.github.io/StayCheck-IQ/`.

Before submitting to App Review, replace `REQUIRED_REAL_PHONE_NUMBER` in `AppStoreConnect/Forms/app-review-information.json` with a real App Review contact number, create the App Store Connect app record, create the subscription products, and add App Store Connect API secrets to GitHub if you want metadata uploads from Actions.
