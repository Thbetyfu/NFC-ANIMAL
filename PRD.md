# DOKUMEN KEBUTUHAN PRODUK (PRODUCT REQUIREMENT DOCUMENT - PRD)
**NFC Pet Game - MVP**

---

## 1. METADATA & KONTEKS GLOBAL

Nama Proyek: **NFC Pet Game (MVP)**  
Versi PRD & Tanggal: **v1.0.0 / 27 Juni 2026**  

### Target Tech Stack:
- **Frontend**: Flutter 3.x
- **State Management**: Provider
- **NFC Integration**: `nfc_manager`
- **3D Viewer**: `model_viewer_plus`
- **Backend / API**: Firebase Cloud Functions (TypeScript / Node.js)
- **Database & ORM**: Firebase Cloud Firestore & Firebase Cloud Storage (untuk file model `.glb`)
- **Autentikasi**: Firebase Authentication (Email/Password & Username)
- **Arsitektur & Standar Kode**: MVC/MVVM pattern dengan Separation of Concerns, Clean Code, SOLID Principles, Secure-by-default Firestore rules, dan Cloud Functions khusus untuk operasi write/klaim hewan.

### Peran AI (AI Persona Prompts):
> Bertindaklah sebagai Senior Full-Stack Developer, Software Architect, dan QA Engineer berpengalaman. Semua respons, struktur kode, skema database, dan pengujian yang Anda hasilkan nanti harus mematuhi batasan teknologi dan standar yang didefinisikan dalam dokumen ini tanpa pengecualian.

---

## 2. RINGKASAN PRODUK & TARGET PENGGUNA

### 2.1 Masalah & Solusi (Problem & Solution)
- **Problem Statement**: Koleksi mainan fisik seringkali kehilangan daya tarik interaktif setelah dibeli, sedangkan game digital murni kekurangan sentuhan fisik dunia nyata yang membuat koleksi terasa berharga dan unik.
- **Product Vision**: Membangun game koleksi hewan peliharaan digital berbasis teknologi NFC yang menggabungkan kepemilikan tag fisik (NFC) dengan visualisasi 3D interaktif pada aplikasi mobile, serta dilindungi oleh sistem backend transaksional yang aman untuk menghindari duplikasi klaim.

### 2.2 Target Pengguna (User Personas)
Aplikasi ini memiliki peran (*roles*) pengguna dengan hak akses yang terisolasi:
- **Role: GUEST** - Pengguna yang belum terautentikasi (belum login). Hanya dapat mengakses halaman login, registrasi, dan reset password.
- **Role: USER** - Pemain terautentikasi yang dapat memindai tag NFC, mengklaim hewan peliharaan, melihat detail visualisasi 3D, serta melihat statistik koleksi mereka.

---

## 3. ARSITEKTUR INFORMASI & STRUKTUR HALAMAN

Berikut adalah alur navigasi (*Sitemap*) dan batasan akses rute halaman pada aplikasi Flutter:

- **`AuthWrapper` (Entry Point / Route Guard)**
  - Mengecek status login secara real-time via `authStateChanges()`.
  - Jika belum login -> diarahkan ke `LoginScreen`.
  - Jika sudah login -> diarahkan ke `HomeScreen`.
- **`LoginScreen` (Akses: Hanya GUEST)**
  - Mengelola form masuk (Login), daftar akun baru (Register), dan lupa kata sandi (Reset Password).
- **`HomeScreen` (Akses: Terproteksi USER)**
  - Dashboard utama berisi informasi pengguna, daftar hewan peliharaan yang diklaim (Grid View), dialog informasi statistik game, dan tombol "Scan NFC".
- **`PetDetailScreen` (Akses: Terproteksi USER)**
  - Menampilkan visualisasi model 3D (`.glb`), informasi tag NFC, waktu klaim, statistik hewan peliharaan (HP & Attack), dan tombol aksi "Beri Makan" & "Latihan" (untuk pengembangan mendatang).

---

## 4. SPESIFIKASI FITUR DETAIL (USER STORY & ACCEPTANCE CRITERIA)

### Fitur ID: F-01 - Autentikasi Pengguna
- **User Story**: Sebagai **GUEST**, saya ingin **masuk atau mendaftarkan akun baru** sehingga **saya dapat masuk ke dalam dashboard game dan mengakses kandang hewan saya sendiri**.
- **Aturan Bisnis (Business Rules)**:
  - Email harus valid secara format dan unik (belum terdaftar di Firebase Auth).
  - Password pendaftaran minimal harus 6 karakter.
  - Username disimpan di Firestore collection `users` saat pendaftaran berhasil.
- **Kriteria Penerimaan (Acceptance Criteria)**:
  - *Skenario 1: Berhasil Daftar Akun Baru*
    - **Given**: Pengguna berada di halaman Login/Register dalam mode "DAFTAR" dan belum terautentikasi.
    - **When**: Pengguna memasukkan username, email valid, password minimal 6 karakter, lalu menekan tombol "DAFTAR".
    - **Then**: Sistem mendaftarkan akun di Firebase Auth, menyimpan dokumen baru di collection `users`, dan mengalihkan pengguna secara otomatis ke `HomeScreen` via `AuthWrapper`.
  - *Skenario 2: Berhasil Login*
    - **Given**: Pengguna berada di halaman Login/Register dalam mode "LOGIN".
    - **When**: Pengguna memasukkan email dan password terdaftar yang valid, lalu menekan tombol "LOGIN".
    - **Then**: Sistem memvalidasi kredensial dan mengalihkan pengguna ke `HomeScreen`.
  - *Skenario 3: Gagal Login karena Kredensial Salah*
    - **Given**: Pengguna berada di halaman Login/Register.
    - **When**: Pengguna memasukkan email/password yang tidak valid, lalu menekan tombol "LOGIN".
    - **Then**: Sistem menampilkan SnackBar error merah dengan pesan kesalahan dari Firebase Auth.

---

### Fitur ID: F-02 - Pemindaian & Klaim Hewan Berbasis NFC
- **User Story**: Sebagai **USER**, saya ingin **memindai tag NFC fisik** sehingga **saya dapat mengklaim hewan peliharaan baru ke dalam kandang digital saya secara aman**.
- **Aturan Bisnis (Business Rules)**:
  - Proses update kepemilikan tag NFC (`id_pemilik`) hanya boleh dilakukan via Cloud Function (`klaimHewan`) untuk mencegah manipulasi data dari sisi klien.
  - Aturan Firestore melarang keras penulisan/modifikasi langsung ke collection `master_hewan` dari klien (`allow write: if false`).
  - Satu tag NFC hanya bisa diklaim oleh satu pengguna (tidak bisa diklaim ulang jika `id_pemilik` tidak bernilai `null`).
  - Operasi klaim di backend wajib menggunakan transaksi database (*Firestore Transaction*) untuk menghindari race condition.
- **Kriteria Penerimaan (Acceptance Criteria)**:
  - *Skenario 1: Berhasil Mengklaim Hewan*
    - **Given**: Pengguna sudah login dan berada di `HomeScreen`.
    - **When**: Pengguna menekan tombol "Scan NFC", mendekatkan tag NFC baru yang terdaftar di database ke sensor perangkat, dan proses Cloud Function berhasil.
    - **Then**: Sistem menampilkan dialog sukses berisi nama hewan peliharaan, tipe kelangkaan, deskripsi, dan hewan tersebut otomatis muncul di grid kandang pemain.
  - *Skenario 2: Gagal Klaim karena Tag Sudah Dimiliki Orang Lain*
    - **Given**: Pengguna berada di `HomeScreen` dan menempelkan tag NFC yang sudah pernah diklaim.
    - **When**: Cloud Function mendeteksi `id_pemilik != null`.
    - **Then**: Sistem menutup loading dan memunculkan dialog kesalahan: "Hewan ini sudah diklaim oleh pemain lain. Coba tag NFC yang berbeda."
  - *Skenario 3: Gagal Klaim karena Tag Tidak Terdaftar*
    - **Given**: Pengguna menempelkan tag NFC kosong/asing yang tidak ada di database `master_hewan`.
    - **When**: Cloud Function mencari ID tag tersebut dan menghasilkan status dokumen tidak ditemukan.
    - **Then**: Sistem memunculkan dialog kesalahan: "Tag NFC tidak valid atau tidak terdaftar dalam sistem."

---

### Fitur ID: F-03 - Visualisasi Hewan Peliharaan 3D
- **User Story**: Sebagai **USER**, saya ingin **membuka detail hewan peliharaan** sehingga **saya dapat melihat model 3D interaktif yang dapat diputar 360° dan mendukung visualisasi AR (Augmented Reality)**.
- **Aturan Bisnis (Business Rules)**:
  - File model 3D berformat `.glb` disimpan di Cloud Storage atau URL eksternal terpercaya dan dibaca melalui widget `ModelViewer`.
  - Warna tema halaman detail disesuaikan secara dinamis berdasarkan kelangkaan hewan peliharaan (Umum, Langka, Epik, Legendaris).
- **Kriteria Penerimaan (Acceptance Criteria)**:
  - *Skenario 1: Membuka Detail Peliharaan*
    - **Given**: Pengguna memiliki setidaknya satu hewan peliharaan di kandang.
    - **When**: Pengguna mengetuk salah satu kartu hewan di grid `HomeScreen`.
    - **Then**: Sistem membuka `PetDetailScreen`, memuat model 3D, menampilkan statistik lengkap (HP & Attack), dan menampilkan identitas tag NFC serta waktu klaim.

---

### Fitur ID: F-04 - Statistik Koleksi Game
- **User Story**: Sebagai **USER**, saya ingin **melihat ringkasan statistik game** sehingga **saya mengetahui total hewan yang terdaftar dalam game, jumlah hewan yang sudah terklaim, dan sisa hewan yang masih bisa dicari**.
- **Aturan Bisnis (Business Rules)**:
  - Data statistik diambil secara real-time dari Cloud Function `getGameStats` agar beban pembacaan data agregat tidak membebani database klien secara langsung.
- **Kriteria Penerimaan (Acceptance Criteria)**:
  - *Skenario 1: Menampilkan Statistik Game*
    - **Given**: Pengguna berada di `HomeScreen`.
    - **When**: Pengguna mengetuk ikon info di pojok kanan atas AppBar.
    - **Then**: Sistem memanggil API `getGameStats` dan menampilkan AlertDialog berisi total hewan peliharaan di sistem, hewan terklaim, dan sisa hewan yang tersedia.

---

## 5. SKEMA DATA & ENTITAS DATABASE (DATA MODEL)

### 5.1 Entitas 1: `users` (Firestore Collection)
Dokumen disimpan dengan ID berupa UID dari Firebase Authentication.

| Field Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `email` | String | Required | Alamat email terdaftar |
| `username` | String | Required | Nama tampilan pengguna |
| `dibuat_pada` | Timestamp | Required | Waktu pembuatan akun |

### 5.2 Entitas 2: `master_hewan` (Firestore Collection)
Dokumen disimpan dengan ID berupa UID Tag NFC (Format: `XX-XX-XX-XX-XX-XX-XX`).

| Field Name | Data Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `nama_hewan` | String | Required | Nama hewan peliharaan |
| `tipe` | String | Required | Kelangkaan: `Umum` \| `Langka` \| `Epik` \| `Legendaris` |
| `deskripsi` | String | Required | Deskripsi atau latar belakang cerita hewan |
| `model_url` | String | Required | URL file model 3D `.glb` |
| `stats_awal` | Map | Required | Peta nilai statistik awal: `{"hp": number, "attack": number}` |
| `id_pemilik` | String \| null | Optional | UID pengguna pemilik (null jika belum diklaim) |
| `diklaim_pada` | Timestamp \| null | Optional | Waktu klaim berhasil |

---

## 6. BATASAN NON-FUNGSIONAL, KEAMANAN, & VALIDASI

### Keamanan (Security):
1. **No Direct Client Write**: Klien dilarang menulis langsung ke data global (`master_hewan`). Perubahan data kepemilikan tag harus melewati Firebase Cloud Functions yang memvalidasi otorisasi di server.
2. **Transaction Integrity**: Proses klaim menggunakan transaksi Firestore (`db.runTransaction()`) untuk mencegah dua pengguna mengklaim tag yang sama pada detik yang bersamaan.
3. **Firestore Security Rules**: Penerapan berkas `firestore.rules` untuk mengunci akses baca/tulis `users` hanya bagi pemilik UID, serta melarang operasi tulis klien untuk `master_hewan`.

### Performa (Performance):
1. **Pemuatan Eksklusif (Lazy Loading & 2D Fallback)**: Model 3D tidak di-render di halaman daftar hewan (`HomeScreen` grid view). Di halaman kandang/grid, gunakan gambar statis PNG atau animasi 2D ringan (seperti Lottie/WebP). Model 3D hanya boleh dimuat secara aktif ketika pemain masuk ke halaman detail (`PetDetailScreen`).
2. **Animasi Bawaan Terpemicu (Pre-Baked Animations)**: Hindari penggunaan kalkulasi fisika dinamis waktu nyata di sisi klien. Semua gerakan hewan menggunakan klip animasi skeletal bawaan di dalam berkas `.glb` (seperti `idle`, `reaksi_sentuh`, `makan`) yang dipicu secara langsung oleh program saat event sentuhan terdeteksi.
3. **Optimasi Berkas 3D (Low-Poly & Draco)**: Batasi jumlah poligon model 3D di bawah 5.000 - 8.000 segitiga per karakter. Seluruh berkas `.glb` harus dikompresi menggunakan metode Draco Compression untuk mengurangi ukuran berkas hingga 70-80% dan menghemat RAM ponsel.
4. **Bayangan Panggang (Baked AO & Shadows)**: Matikan rendering bayangan dinamis waktu nyata di GPU. Desainer 3D harus memanggang (*bake*) efek bayangan (ambient occlusion) langsung ke dalam gambar tekstur hewan peliharaan (diffuse map).
5. **Kalkulasi Interaksi Ringan (Look-At Neck Rotation)**: Efek interaksi gerakan dinamis kepala hewan yang mengikuti sentuhan jari pemain dilakukan dengan memanipulasi rotasi *joint* leher secara terbatas berdasarkan koordinat sentuhan layar, tanpa membebani GPU/CPU dengan model AI.
6. **Statistik Server-Side**: Penghitungan statistik agregat dilakukan di sisi server untuk mencegah pembacaan data seluruh dokumen secara terus-menerus oleh klien.

### Aksesibilitas & UI/UX (Accessibility):
1. **Responsive Grid**: Layout kandang di `HomeScreen` menggunakan grid responsif yang dapat menyesuaikan diri dengan berbagai resolusi layar ponsel Android & iOS.
2. **Dynamic Coloring**: Indikasi visual yang kuat dengan warna berbeda di setiap jenis hewan berdasarkan kelangkaannya guna memudahkan klasifikasi.
3. **Interactive Control Hint**: Penempatan teks petunjuk "Putar untuk melihat" pada visualizer 3D agar pengguna mengetahui bahwa objek 3D dapat disentuh dan diputar 360°.

### Spesifikasi Perangkat Target (Target Device Specifications):
Spesifikasi perangkat ditentukan untuk memastikan fitur pembacaan hardware (NFC), rendering visual 3D, dan proyeksi kamera (AR) dapat berjalan stabil tanpa memicu crash memori (Out-of-Memory) atau panas berlebih pada ponsel.

#### 1. Spesifikasi Minimum (Untuk Menjalankan Game & Scan NFC Dasar):
- **Sistem Operasi**: 
  - Android 8.0 (Oreo, API Level 26) atau lebih baru.
  - iOS 13.0 (iPhone 7) atau lebih baru.
- **Hardware / Sensor**: Chip sensor NFC fisik internal yang aktif (Built-in NFC controller).
- **Memori (RAM)**: 3 GB (Sisa RAM bebas minimal 1.5 GB saat menjalankan game).
- **GPU**: Dukungan OpenGL ES 3.0.

#### 2. Spesifikasi Rekomendasi (Untuk Performa 3D Mulus & 60 FPS):
- **Sistem Operasi**: Android 10.0+ atau iOS 15.0+.
- **Memori (RAM)**: 4 GB atau lebih besar.
- **GPU**: Perangkat dengan dukungan Vulkan API (Android) atau Metal API (iOS).
- **Koneksi**: Internet stabil (Wi-Fi/4G LTE) untuk sinkronisasi cloud real-time.

#### 3. Kebutuhan Khusus Fitur Masa Depan (AR - Augmented Reality):
- **Android**: Perangkat harus terdaftar dalam daftar resmi pendukung **Google Play Services for AR (ARCore)**.
- **iOS**: iPhone dengan chip Apple A9 atau lebih baru (Mendukung Apple ARKit).
- **Sensor Tambahan**: Giroskop, Akselerometer, dan kamera belakang minimal 12 MP dengan autofokus.

---

## 7. RENCANA PENINGKATAN MENDATANG (FUTURE ROADMAP FOR MONETIZATION & ENGAGEMENT)

Bagian ini mendefinisikan rencana pengembangan masa depan untuk memperluas nilai jual fisik dan fungsionalitas permainan guna mendukung monetisasi kartu NFC.

### 7.1 Konsep "Soul Tag" (NFC Write State)
- **Akar Masalah**: Jika NFC hanya digunakan sebagai kunci klaim sekali pakai, kartu fisik tersebut akan kehilangan kegunaannya setelah discan dan tidak memiliki nilai guna berkelanjutan.
- **Solusi**: Mengubah kartu NFC menjadi wadah penyimpan status peliharaan. Setiap kali pemain menaikkan level, memberi makan, atau melatih hewannya, data statistik terbaru ditulis kembali ke dalam memori chip NFC fisik tersebut (menggunakan fitur NFC Write).
- **Nilai Jual**: Pemain dapat membawa kartu fisiknya ke mana saja. Saat kartu tersebut discan di ponsel orang lain, peliharaan mereka dengan level dan stats yang sama persis akan muncul secara lokal untuk dipamerkan atau ditandingkan.

### 7.2 Turn-Based Battle System (PvE & PvP)
- **Akar Masalah**: Statistik HP dan Attack yang diperoleh dari proses menaikkan level saat ini hanya berfungsi sebagai angka pajangan tanpa memiliki fungsi gameplay yang nyata.
- **Solusi**: Membangun modul pertarungan sederhana bergaya turn-based. Pemain dapat menantang bos liar (PvE) untuk mendapatkan item makanan langka, atau menantang sesama pemain (PvP) secara lokal.
- **Nilai Jual**: Kenaikan level dan status menjadi sangat penting. Pemain terdorong untuk melatih peliharaan mereka atau membeli kartu NFC baru dengan status awal tinggi agar dapat memenangkan pertarungan.

### 7.3 Sistem Evolusi Hewan & Model 3D Variatif
- **Akar Masalah**: Tampilan visual yang statis tanpa perubahan bentuk visual membuat permainan terasa cepat membosankan setelah beberapa hari.
- **Solusi**: Menerapkan batas evolusi peliharaan pada level tertentu (misalnya level 10 dan 20). Ketika berevolusi, model 3D peliharaan akan berubah bentuk menjadi lebih besar, lebih garang, dan memiliki efek visual baru.
- **Nilai Jual**: Membangun kepuasan jangka panjang bagi pemain dalam merawat peliharaannya.

### 7.4 Integrasi Kamera AR (Augmented Reality)
- **Akar Masalah**: Interaksi visual saat ini masih terbatas di dalam layar dua dimensi ponsel.
- **Solusi**: Menambahkan fitur kamera AR (menggunakan library ARCore/ARKit) sehingga pemain bisa memproyeksikan model 3D hewan mereka ke permukaan dunia nyata.
- **Nilai Jual**: Pemain bisa berfoto bersama hewan peliharaan mereka dan membagikannya ke media sosial, menciptakan pemasaran organik (viral marketing) yang kuat.

### 7.5 Kolektibilitas Kartu Fisik Premium & Blind Box (Gacha)
- **Akar Masalah**: Kartu NFC polos biasa kurang menarik secara visual untuk dikoleksi secara fisik.
- **Solusi**: Merancang kartu NFC fisik dengan kualitas premium menggunakan ilustrasi karakter (artwork) yang menarik, efek cetak hologram (foil), atau cetak timbul (embossed). Penjualan kartu dikemas dalam bentuk Blind Box (gacha fisik).
- **Nilai Jual**: Menciptakan sensasi kejutan dan hobi koleksi fisik bagi kolektor kartu.

