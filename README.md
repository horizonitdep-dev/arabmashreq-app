# Arab Mashreq Mobile (Flutter)

## Overview
Arabic RTL news app connected to two data sources:
- WordPress for editorial content (articles, categories, details)
- Laravel backend for app features (breaking news, ads, preferences, analytics, notifications)

## Requirements
- Flutter SDK
- Android Studio / Android SDK
- Xcode (required for final iOS builds on macOS)

## Setup
1. Install dependencies:
   - `flutter pub get`
2. Configure environment (optional):
   - copy `env.example.json` to `env.json`
3. Run app:
   - Android: `flutter run --dart-define-from-file=env.json`
   - iOS (macOS only): `flutter run --dart-define-from-file=env.json`

## Firebase
- Android file: `google-services.json`
- iOS file: `GoogleService-Info.plist`
- Push notifications are enabled with `firebase_messaging` and safe fallback handling.

## Implemented Features
- Splash + Bottom Navigation
- Home (sections, slider, breaking ticker, latest news, ads)
- Categories + category details
- Breaking news page
- Article details with HTML rendering + share + related posts
- Local bookmarks
- More tab: dark mode, font scaling, static pages
- Full RTL support

## iOS Note
Final iOS release generation requires macOS + Xcode.
