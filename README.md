# 💬 ChatLoc

> Real-time chat with location sharing — built with Flutter & Firebase.

![Android](https://img.shields.io/badge/Android-API%2021+-green?logo=android)
![iOS](https://img.shields.io/badge/iOS-14+-blue?logo=apple)
![Flutter](https://img.shields.io/badge/Flutter-3.19+-blue?logo=flutter)
[![Build Android](https://github.com/yourorg/chatloc/actions/workflows/build_android.yml/badge.svg)](https://github.com/yourorg/chatloc/actions/workflows/build_android.yml)
[![Build iOS](https://github.com/yourorg/chatloc/actions/workflows/build_ios.yml/badge.svg)](https://github.com/yourorg/chatloc/actions/workflows/build_ios.yml)

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔐 Auth | Email/password login & register via Firebase Auth |
| 💬 Chat | Real-time 1-on-1 & group messaging via Firestore |
| 📍 Location | Share precise or live location inside any chat |
| 🗺 Map View | See shared locations on an interactive Google Map |
| 🖼 Media | Send images with Firebase Storage |
| 🔔 Push | FCM push notifications |
| 🌙 Dark mode | Full system / manual dark mode support |
| ✅ Read receipts | Sent → Delivered → Read message status |
| 😂 Reactions | Emoji reactions on any message |

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.19+
- Firebase project (Firestore, Auth, Storage, FCM enabled)
- Google Maps API key (Android + iOS)

### 1. Clone & install
```bash
git clone https://github.com/yourorg/chatloc.git
cd chatloc
flutter pub get
```

### 2. Configure Firebase
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Connect to your Firebase project
flutterfire configure
```
This generates `lib/firebase_options.dart` automatically.

### 3. Create `.env`
```bash
cp .env.example .env
# Fill in your values
```

### 4. Run code generation
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5. Run the app
```bash
flutter run --flavor development
```

---

## 🔑 GitHub Secrets Required

Add these in **Settings → Secrets → Actions**:

### Firebase
| Secret | Description |
|---|---|
| `FIREBASE_API_KEY` | Firebase Web API key |
| `FIREBASE_AUTH_DOMAIN` | `projectid.firebaseapp.com` |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_STORAGE_BUCKET` | `projectid.appspot.com` |
| `FIREBASE_MESSAGING_SENDER_ID` | FCM sender ID |
| `FIREBASE_APP_ID_ANDROID` | Android app ID |
| `FIREBASE_APP_ID_IOS` | iOS app ID |
| `FIREBASE_APP_ID_WEB` | Web app ID |
| `GOOGLE_SERVICES_JSON` | Contents of `google-services.json` |
| `GOOGLE_SERVICE_INFO_PLIST` | Base64 of `GoogleService-Info.plist` |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase service account JSON (for App Distribution) |

### Android Signing
| Secret | Description |
|---|---|
| `KEYSTORE_BASE64` | Base64-encoded `.jks` keystore |
| `STORE_PASSWORD` | Keystore store password |
| `KEY_PASSWORD` | Key password |
| `KEY_ALIAS` | Key alias |

### Maps
| Secret | Description |
|---|---|
| `GOOGLE_MAPS_API_KEY` | Google Maps Platform API key |

### iOS Signing
| Secret | Description |
|---|---|
| `IOS_CERTIFICATE_P12_BASE64` | Base64-encoded `.p12` distribution cert |
| `IOS_CERTIFICATE_PASSWORD` | Certificate password |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64-encoded `.mobileprovision` |
| `KEYCHAIN_PASSWORD` | Temp keychain password (any string) |
| `APPLE_TEAM_ID` | Apple Developer Team ID |

### App Store Connect (for TestFlight)
| Secret | Description |
|---|---|
| `APPSTORE_ISSUER_ID` | App Store Connect issuer ID |
| `APPSTORE_API_KEY_ID` | API key ID |
| `APPSTORE_API_PRIVATE_KEY` | API private key (`.p8` contents) |

### Play Store (optional)
| Secret | Description |
|---|---|
| `PLAY_STORE_SERVICE_ACCOUNT` | Service account JSON for Play API |

---

## 🏗 Project Structure

```
lib/
├── main.dart
├── firebase_options.dart
├── router/
│   └── app_router.dart         # GoRouter navigation
├── theme/
│   └── app_theme.dart          # Light & dark themes
├── models/
│   ├── user_model.dart
│   ├── chat_model.dart
│   └── message_model.dart
├── services/
│   ├── auth_service.dart
│   ├── chat_service.dart
│   ├── location_service.dart
│   ├── notification_service.dart
│   └── storage_service.dart
├── providers/
│   └── theme_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   ├── home/
│   ├── chat/
│   ├── map/
│   ├── profile/
│   └── settings/
├── widgets/
│   ├── message_bubble.dart
│   ├── chat_list_tile.dart
│   ├── location_picker_sheet.dart
│   ├── user_avatar.dart
│   ├── custom_text_field.dart
│   └── loading_button.dart
└── utils/
    ├── validators.dart
    ├── time_util.dart
    └── snackbar_util.dart
```

---

## 🔄 CI/CD Workflows

| Workflow | Trigger | Output |
|---|---|---|
| `pr_check.yml` | PR to main/develop | Format, analyze, test |
| `build_android.yml` | Push to main / tags | APK + AAB → Play Store |
| `build_ios.yml` | Push to main / tags | IPA → TestFlight |

**Tag a release** to auto-publish:
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## 🔥 Firestore Rules (deploy separately)

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }
    match /chats/{chatId} {
      allow read, write: if request.auth.uid in resource.data.memberIds;
      match /messages/{msgId} {
        allow read, write: if request.auth.uid in
          get(/databases/$(database)/documents/chats/$(chatId)).data.memberIds;
      }
    }
  }
}
```

---

## 📄 License

MIT © 2024 Your Company
