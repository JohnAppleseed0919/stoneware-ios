# Stoneware - Project Instructions

## App Overview
iOS app (SwiftUI + SwiftData). Pottery studio diary — track every piece from
idea to finished. Local-first, no accounts, no ads.

- **Bundle ID:** `com.stoneware.app`
- **Team ID:** `6G3Q27J6NB`
- **App Store Connect ID:** `ASC_ID_HERE` (fill in after manual ASC creation — see below)
- **Domain:** https://stoneware.app (Vercel, project `stoneware`)
- **GitHub:** https://github.com/JohnAppleseed0919/stoneware-ios

## Project Layout
- **Xcode project:** `Stoneware.xcodeproj/` (regenerate with `xcodegen generate` from repo root)
- **Source:** `Stoneware/Stoneware/` (SwiftUI views, SwiftData models)
- **UI tests / screenshots:** `Stoneware/StonewareUITests/`
- **Fastlane:** `Stoneware/fastlane/`
- **Website:** `website/`
- **App Store screenshots:** `appstore_screenshots/` (also auto-generated under `Stoneware/fastlane/screenshots/`)

## Manual step required (one time)
Apple's ASC API does **not** allow creating apps via API. Register once in the
App Store Connect web UI:

1. Go to https://appstoreconnect.apple.com/apps → "+" → "New App"
2. Platforms: iOS
3. Name: `Stoneware: Pottery Studio Log`
4. Primary Language: English (U.S.)
5. Bundle ID: `com.stoneware.app` (already registered at Developer Portal)
6. SKU: `STONEWARE001`
7. User Access: Full Access
8. After creation, grab the numeric Apple ID (ASC ID) and drop it into this
   file's `ASC_ID_HERE` placeholder.

Bundle ID `com.stoneware.app` was registered via ASC API — no Developer Portal step needed.

## Build, screenshot, submit

```bash
# Regenerate Xcode project (after editing project.yml)
xcodegen generate

# Build for sim (smoke test)
xcodebuild -project Stoneware.xcodeproj -scheme Stoneware \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Capture App Store screenshots via the UI test target (iPhone 17 Pro Max,
# iPhone 17, iPad Pro 13")
cd Stoneware && fastlane snapshot run

# Upload metadata + screenshots (requires ASC app to exist first)
cd Stoneware && fastlane metadata

# Build, upload, and submit for review
cd Stoneware && fastlane release
```

Fastlane uses the ASC API key at `Stoneware/fastlane/api_key.json` — no password
or 2FA required for anything except the one-time app creation above.

## Key Details
- Category: Lifestyle
- Pricing: Free
- Privacy: No data collected (everything local via SwiftData)
- Encryption: None (`ITSAppUsesNonExemptEncryption: false`)

## User Preferences
- Maximize automation, minimize manual steps
- Account: Rick Anderson / anderson.rh@icloud.com (Apple Dev) / support@stoneware.app / Claya LLC
