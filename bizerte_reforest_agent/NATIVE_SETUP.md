# Native Android and iOS Setup

Run this after Flutter is installed:

```bash
cd bizerte_reforest_agent
flutter create --platforms=android,ios .
flutter pub get
```

## Android Permissions

Open `android/app/src/main/AndroidManifest.xml` and add these above the `<application>` tag:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
```

Also make sure internet access exists for OpenStreetMap and OpenRouter:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## iOS Permissions

Open `ios/Runner/Info.plist` and add:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses GPS to save field validation points for reforestation planning.</string>
<key>NSCameraUsageDescription</key>
<string>This app uses the camera to document validation sites.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app can attach site photos to field validation records.</string>
```

## Run

Android:

```bash
flutter run
```

iPhone requires macOS and Xcode:

```bash
flutter run -d ios
```
