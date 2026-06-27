# Panduan Setup Firebase untuk NFC Pet Game

## 1. Setup Firebase Project

### Langkah 1: Buat Project Firebase
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik "Add project" atau "Tambah project"
3. Berikan nama project: `nfc-pet-game`
4. Pilih pengaturan yang sesuai dan tunggu project selesai dibuat

### Langkah 2: Enable Services
1. **Authentication**:
   - Pergi ke "Authentication" > "Sign-in method"
   - Enable "Email/Password"
   
2. **Cloud Firestore**:
   - Pergi ke "Firestore Database"
   - Klik "Create database"
   - Pilih mode "Start in test mode" (sementara)
   - Pilih lokasi server

3. **Cloud Functions**:
   - Pergi ke "Functions"
   - Setup billing (diperlukan untuk Cloud Functions)

4. **Storage** (opsional untuk model 3D):
   - Pergi ke "Storage"
   - Klik "Get started"

## 2. Setup Flutter Project

### Langkah 1: Install Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

### Langkah 2: Install FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
```

### Langkah 3: Configure Firebase untuk Flutter
Di root project, jalankan:
```bash
flutterfire configure
```
- Pilih project Firebase yang sudah dibuat
- Pilih platform (Android/iOS)
- File `firebase_options.dart` akan otomatis dibuat

## 3. Setup Cloud Functions

### Langkah 1: Initialize Functions
Di root project:
```bash
firebase init functions
```
- Pilih project yang sudah dibuat
- Pilih TypeScript
- Install dependencies: Yes

### Langkah 2: Install Dependencies
```bash
cd functions
npm install firebase-admin firebase-functions
```

### Langkah 3: Deploy Functions
```bash
npm run deploy
```

## 4. Setup Database Rules

### Langkah 1: Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### Langkah 2: Seed Data
Di Firestore Console, buat collection `master_hewan` dengan data berikut:

**Document ID**: `04-6E-9C-7A-81-5B-80`
```json
{
  "nama_hewan": "Kucing Api",
  "tipe": "Langka",
  "deskripsi": "Seekor kucing yang diselimuti api abadi.",
  "model_url": "https://modelviewer.dev/shared-assets/models/Astronaut.glb",
  "stats_awal": { "hp": 100, "attack": 15 },
  "id_pemilik": null
}
```

**Document ID**: `AA-BB-CC-DD-EE-FF-00`
```json
{
  "nama_hewan": "Naga Air",
  "tipe": "Epik",
  "deskripsi": "Naga legendaris yang menguasai elemen air.",
  "model_url": "https://modelviewer.dev/shared-assets/models/Horse.glb",
  "stats_awal": { "hp": 150, "attack": 25 },
  "id_pemilik": null
}
```

**Document ID**: `11-22-33-44-55-66-77`
```json
{
  "nama_hewan": "Kelinci Petir",
  "tipe": "Umum",
  "deskripsi": "Kelinci cepat dengan kekuatan listrik.",
  "model_url": "https://modelviewer.dev/shared-assets/models/RobotExpressive.glb",
  "stats_awal": { "hp": 80, "attack": 12 },
  "id_pemilik": null
}
```

## 5. Testing

### Testing di Emulator (Tanpa NFC)
Untuk testing tanpa perangkat NFC fisik, tambahkan button debug sementara di `home_screen.dart`:

```dart
// Tambahkan di _HomeScreenState
FloatingActionButton.extended(
  onPressed: () => _gameService.klaimHewan(context, "04-6E-9C-7A-81-5B-80"),
  label: Text('Test Klaim'),
),
```

### Testing dengan NFC Fisik
1. Gunakan tag NFC kosong
2. Tulis UID tag ke database sebagai document ID
3. Test scan dengan aplikasi

## 6. Troubleshooting

### Error: "FirebaseFunctionsException"
- Pastikan Cloud Functions sudah di-deploy
- Check console.log di Firebase Functions logs

### Error: "Permission denied"
- Periksa Firestore rules
- Pastikan user sudah login

### Error: NFC tidak terdeteksi
- Pastikan permission NFC di AndroidManifest.xml
- Test di perangkat fisik, bukan emulator

### Error: Model 3D tidak muncul
- Periksa URL model valid
- Pastikan internet connection
- Gunakan model .glb yang kompatibel

## 7. Environment Variables

Buat file `.env` di root project (opsional):
```
FIREBASE_PROJECT_ID=nfc-pet-game
FIREBASE_REGION=asia-southeast1
```

## 8. Permissions (Android)

Pastikan permissions berikut ada di `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.NFC" />
<uses-feature 
    android:name="android.hardware.nfc" 
    android:required="false" />
<uses-permission android:name="android.permission.INTERNET" />
```

## 9. Production Checklist

- [ ] Update Firestore rules dari test mode ke production
- [ ] Setup proper billing di Firebase
- [ ] Add error monitoring (Crashlytics)
- [ ] Add analytics (Firebase Analytics)
- [ ] Setup CI/CD pipeline
- [ ] Add proper app icons dan splash screen
