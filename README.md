# NFC Pet Game - MVP

Game koleksi hewan peliharaan digital berbasis teknologi NFC dengan Flutter dan Firebase.

## Fitur Utama

- 🔐 **Autentikasi** - Login/Register dengan Firebase Auth
- 📱 **Pemindaian NFC** - Scan tag NFC untuk mendapatkan hewan
- 🎮 **Koleksi Hewan** - Tampilkan hewan yang sudah diklaim
- 🎯 **Model 3D** - Lihat hewan dalam model 3D yang dapat diputar 360°
- 🔒 **Keamanan** - Sistem backend yang aman dengan Cloud Functions

## Teknologi yang Digunakan

- **Frontend**: Flutter 3.x
- **Backend**: Firebase (Firestore, Cloud Functions, Auth, Storage)
- **NFC**: nfc_manager
- **3D Viewer**: model_viewer_plus
- **State Management**: provider

## Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/                   # Data models
│   ├── pet.dart             # Model hewan peliharaan
│   └── user.dart            # Model user
├── screens/                  # UI Screens
│   ├── login_screen.dart    # Layar login/register
│   ├── home_screen.dart     # Dashboard utama
│   └── pet_detail_screen.dart # Detail hewan 3D
└── services/                 # Business logic
    ├── auth_service.dart    # Service autentikasi
    ├── nfc_service.dart     # Service NFC
    └── game_service.dart    # Service game logic

functions/
└── src/
    └── index.ts             # Cloud Functions (TypeScript)
```

## Setup Firebase

1. **Buat Project Firebase**:
   - Buka [Firebase Console](https://console.firebase.google.com/)
   - Buat project baru
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Enable Cloud Functions

2. **Konfigurasi Flutter**:
   ```bash
   flutter pub add firebase_core
   flutterfire configure
   ```

3. **Deploy Cloud Functions**:
   ```bash
   cd functions
   npm install
   npm run deploy
   ```

4. **Setup Firestore Rules**:
   - Upload file `firestore.rules` ke Firebase Console

## Struktur Database

### Collection: `master_hewan`
- **Document ID**: UID tag NFC (format: XX-XX-XX-XX-XX-XX-XX)
- **Fields**:
  ```json
  {
    "nama_hewan": "string",
    "tipe": "string", // Umum, Langka, Epik, Legendaris
    "deskripsi": "string",
    "model_url": "string", // URL ke file .glb
    "stats_awal": {
      "hp": "number",
      "attack": "number"
    },
    "id_pemilik": "string|null", // UID user pemilik
    "diklaim_pada": "timestamp|null"
  }
  ```

### Collection: `users`
- **Document ID**: UID dari Firebase Auth
- **Fields**:
  ```json
  {
    "email": "string",
    "username": "string",
    "dibuat_pada": "timestamp"
  }
  ```

## Cara Menjalankan

1. **Persiapan**:
   ```bash
   flutter pub get
   ```

2. **Setup Firebase** (ikuti langkah di atas)

3. **Jalankan Aplikasi**:
   ```bash
   flutter run
   ```

## Data Seed untuk Testing

Tambahkan data berikut ke collection `master_hewan` di Firestore Console:

### Document ID: `04-6E-9C-7A-81-5B-80`
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

### Document ID: `AA-BB-CC-DD-EE-FF-00`
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

## Simulasi Testing Tanpa NFC

Untuk testing di emulator tanpa NFC, Anda bisa:

1. Buat button sementara di `home_screen.dart`
2. Panggil langsung `_gameService.klaimHewan(context, "04-6E-9C-7A-81-5B-80")`

## Keamanan

- ✅ Client tidak bisa mengubah `id_pemilik` di Firestore
- ✅ Klaim hewan hanya melalui Cloud Function
- ✅ Validasi autentikasi di semua operasi
- ✅ Transaksi Firestore untuk mencegah race condition

## Fitur Mendatang

- 🍖 Feed pet functionality
- 🏋️ Pet training system
- ⚔️ Pet battles
- 🏆 Achievements & leaderboard
- 📸 AR camera integration

## Kontribusi

1. Fork repository
2. Buat branch feature (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## Lisensi

Distributed under the MIT License. See `LICENSE` for more information.

## Support

Jika ada pertanyaan atau masalah, silakan buat issue di repository ini.
