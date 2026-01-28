# KresAI - AI-Powered Kindergarten Management

KresAI, anaokulu yönetimi için yapay zeka destekli bir mobil uygulamadır.

## Özellikler

### ✅ Tamamlanan
- 🔐 Firebase Authentication (Email/Password)
- 📱 Role-based navigation (Teacher/Parent/Admin)
- 🤖 AI Program Parsing (Gemini Vision API)
- 📊 Daily plan generation
- 📸 Image-based program upload
- 👥 Parent/Teacher registration system
- ⚙️ Settings & Profile screens
- 🚪 Secure logout functionality

### 🏗️ Geliştirme Aşamasında
- ☁️ Cloud Functions integration
- 💾 Firestore real-time sync
- 📷 Cloud Storage uploads
- 🔔 Push notifications (FCM)

## Teknolojiler

- **Framework**: Flutter
- **Backend**: Firebase (Auth, Firestore, Cloud Storage)
- **AI**: Google Gemini 2.0 Flash
- **State**: MobX (planned) / SharedPreferences (current)
- **Design**: Material 3 with custom tokens

## Kurulum

```bash
# Dependencies
flutter pub get

# Firebase configuration (already set up)
# firebase_options.dart includes project credentials

# Build
flutter build apk --debug

# Run
flutter run
```

## Environment Variables

For production builds with custom API key:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_api_key
```

See `docs/API_KEY_SETUP.md` for details.

## Proje Yapısı

```
lib/
├── config/          # API configuration
├── models/          # Data models
├── screens/         # UI screens (parent, teacher, admin, auth)
├── services/        # Business logic & stores
├── navigation/      # Shell navigation
└── theme/           # Design tokens & themes
```

## Kullanım

1. **İlk Kurulum**:
   - Signup ile hesap oluştur
   - Role seç (Teacher/Parent)
   - Invite code gir
   - Admin onayını bekle

2. **Teacher**:
   - Program yükle (text veya fotoğraf)
   - Günlük plan onayla
   - Veli onayları yönet
   - Canlı yayın başlat

3. **Parent**:
   - Günlük aktiviteleri görüntüle
   - Canlı yayına katıl
   - Foto/video izinlerini yönet
   - Mesajlaşma

## Lisans

Private project - All rights reserved

## İletişim

KresAI Development Team
