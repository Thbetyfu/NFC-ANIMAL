# Struktur Database Cloud Firestore untuk NFC-Pet

## Koleksi: master_hewan
ID Dokumen: UID dari tag NFC fisik (Format: String Hexadecimal, contoh: 04-6E-9C-7A-81-5B-80)

```json
{
  "nama_hewan": "Kucing Api",
  "tipe": "Langka",
  "deskripsi": "Seekor kucing yang diselimuti api abadi.",
  "model_url": "gs://bucket-anda/model/kucing_api.glb",
  "stats_awal": { 
    "hp": 100, 
    "attack": 15 
  },
  "id_pemilik": null // String, Nullable - KUNCI KEAMANAN
}
```

## Koleksi: users
ID Dokumen: uid dari Firebase Authentication

```json
{
  "email": "user@example.com",
  "username": "Pemain1",
  "dibuat_pada": "timestamp"
}
```

## Contoh Data Seed untuk Testing:

### master_hewan/04-6E-9C-7A-81-5B-80:
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

### master_hewan/AA-BB-CC-DD-EE-FF-00:
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

### master_hewan/11-22-33-44-55-66-77:
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
