# NFC Pet Game

Flutter SDK dengan Firebase untuk MVP game koleksi hewan peliharaan berbasis NFC.

## Dokumentasi

- [📖 README](./README.md) - Overview dan fitur utama
- [🔧 Setup Guide](./SETUP_GUIDE.md) - Panduan setup Firebase lengkap
- [📋 TODO](./TODO.md) - Task list dan progress tracking
- [📊 Database Structure](./database_structure.md) - Struktur data Firestore

## Quick Start

1. **Setup Environment**:
   ```bash
   flutter pub get
   ```

2. **Setup Firebase**: Ikuti panduan di [SETUP_GUIDE.md](./SETUP_GUIDE.md)

3. **Run App**:
   ```bash
   flutter run
   ```

## Arsitektur

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  Cloud Functions │    │   Firestore     │
│                 │    │                 │    │                 │
│ • NFC Service   │───▶│ • klaimHewan    │───▶│ • master_hewan  │
│ • Auth Service  │    │ • getGameStats  │    │ • users         │
│ • Game Service  │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Core Features

- 🔐 Authentication (Firebase Auth)
- 📱 NFC Scanning (nfc_manager)
- 🎮 Pet Collection (Firestore)
- 🎯 3D Pet Viewer (model_viewer_plus)
- 🔒 Secure Backend (Cloud Functions)

## Development Status

✅ **MVP Complete** - Ready for Firebase setup dan testing
🚧 **Testing** - Membutuhkan Firebase project dan NFC tags
📱 **Deployment** - Ready untuk production deployment

---

**Tech Stack**: Flutter 3.x • Firebase • TypeScript • Firestore • Cloud Functions
