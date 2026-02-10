# Bill Split App - Setup Instructions

## Prerequisites

1. Flutter SDK (3.0.0 or higher)
2. Android Studio / Xcode (for platform-specific setup)
3. AdMob account (for ads - use test IDs for development)

## Installation Steps

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Android Setup

1. Open `android/app/build.gradle`
2. Set `minSdkVersion` to 21
3. Set `targetSdkVersion` to 34
4. Add your AdMob App ID to `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
   ```

### 3. iOS Setup

1. Open `ios/Runner.xcworkspace` in Xcode
2. Set minimum iOS version to 12.0
3. Add your AdMob App ID to `ios/Runner/Info.plist`:
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
   ```

### 4. AdMob Configuration

Replace test ad unit IDs in `lib/utils/constants.dart` with your actual AdMob ad unit IDs:
- `androidBannerAdId`
- `iosBannerAdId`
- `androidInterstitialAdId`
- `iosInterstitialAdId`

### 5. In-App Purchase Setup

1. Configure products in Google Play Console / App Store Connect:
   - Product ID: `premium_lifetime` ($2.99)
   - Product ID: `premium_monthly` ($0.99/month)
2. Implement purchase verification (currently placeholder)

## Running the App

```bash
# Run on connected device/emulator
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ios
```

## Features Implemented

✅ Manual bill entry with items and people
✅ OCR receipt scanning (Google ML Kit)
✅ Item assignment to multiple people
✅ Proportional tax and tip calculation
✅ Bill history with SQLite storage
✅ Group management (with free tier limits)
✅ Premium subscription system (UI ready, IAP needs implementation)
✅ Ad integration (AdMob - test IDs)
✅ Material Design 3 UI
✅ Dark mode support
✅ Settings screen

## Features Pending Implementation

- In-app purchase actual integration (currently shows placeholder)
- PDF/Excel export functionality
- Share bill functionality
- Cloud backup
- Receipt photo storage

## Testing

Run tests with:
```bash
flutter test
```

## Notes

- The app uses test AdMob IDs by default. Replace with production IDs before release.
- In-app purchases need to be configured in respective app stores.
- OCR accuracy depends on receipt quality and lighting.
