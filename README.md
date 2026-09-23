# Maca Komik (Voratoon API Client) 📖⚡

Maca Komik adalah aplikasi pembaca komik lintas-platform berperforma tinggi yang dibangun menggunakan **Flutter**. Aplikasi ini memanfaatkan jalur REST API JSON murni dari Voratoon (`https://api.voratoon.com`) tanpa scraping HTML lambat, dilengkapi sistem mitigasi proteksi *Cloudflare*, optimasi memori anti-OOM (*Out of Memory*), layout adaptif (Smartphone & Tablet), dan penyimpanan lokal SQLite v8 yang andal (Offline).

---

## 🌟 Fitur Utama

- **Arsitektur Bersih & Modular (Clean Architecture)**: Pemisahan tegas antara Data Layer (Repository, Service, Model) dan Presentation Layer dengan struktur komponen terorganisasi per fitur (`home/`, `detail/`, `reader/`, `collection/`).
- **Efisien State Management**: Menggunakan Provider terspesialisasi (`HomeProvider`, `DetailProvider`, `ReaderProvider`, `LibraryProvider`, `SettingsProvider`, `DownloadProvider`) untuk kinerja render yang modular dan ringan.
- **Mode Offline & Download Manager Berperforma Tinggi**:
  - Mengunduh chapter komik untuk dibaca kapan saja tanpa kuota internet.
  - Menggunakan *zero-buffer streaming I/O* langsung ke flash storage (`Stream.pipe(File.openWrite())`) menjaga penggunaan RAM unduhan tetap di bawah 10 MB.
  - Dilengkapi *concurrency pool* (2–3 gambar paralel) dan jeda manusiawi (*jitter delay* 150ms–350ms) guna memitigasi limitasi anti-bot/WAF.
- **Pengalaman Membaca Ergonomis (Advanced Reader Ergonomics)**:
  - **Mode Webtoon**: Scroll vertikal kontinyu dengan pembatas lebar (`maxWidth: 720`) di layar tablet/desktop.
  - **Mode Manga**: Paging horizontal per halaman (`PageView`) dengan dukungan arah baca Kanan-ke-Kiri (RTL) dan Kiri-ke-Kanan (LTR).
  - **Persistensi Preferensi**: Seluruh preferensi baca tersimpan otomatis di database lokal.
  - **Layar Imersif Penuh**: Sembunyikan bilah kontrol dengan sekali ketuk (`SystemUiMode.immersiveSticky`).
  - **Overlay Jam & Baterai Terisolasi**: Memantau waktu dan daya baterai tanpa memicu render ulang gambar chapter.
  - **Tint Kecerahan**: Pengatur tingkat kegelapan/kecerahan layar berbasis slider tanpa *BackdropFilter* (bebas beban offscreen GPU).
  - **Retryable Image Reload**: Tombol coba ulang mandiri per panel jika terjadi kegagalan jaringan pada gambar tertentu.
- **Tata Letak Responsif & Adaptif (Adaptive Layout)**:
  - **Grid Cerdas (Ganjil 21 / Genap 20)**: Menyesuaikan jumlah kartu komik agar baris grid selalu terisi penuh rata di semua resolusi layar (`SliverGridDelegateWithMaxCrossAxisExtent`).
  - **Adaptive Navigation**: Menggunakan `BottomNavigationBar` pada smartphone dan beralih otomatis ke `NavigationRail` vertikal di sisi kiri pada layar lebar (`width >= 640dp`).
  - **Master-Detail Split View**: Pada halaman detail di layar tablet/desktop (`width >= 720dp`), tampilan terbagi menjadi kolom metadata di kiri dan daftar chapter interaktif di kanan.
- **Koleksi Terpadu & Riwayat Otomatis (SQLite v8)**:
  - Halaman `CollectionPage` menggabungkan komik **Tersimpan (Bookmark)** dan **Unduhan (Downloads)** dalam satu tampilan `TabBar` yang rapi.
  - Riwayat baca (*History*) mencatat posisi chapter terakhir secara otomatis.
- **Dashboard Penyimpanan & Granular Cache Eviction**:
  - Menampilkan ukuran cache aktual secara real-time.
  - Hapus mandiri cache sampul (*cover cache*), cache reader, atau unduhan komik per chapter/seluruh komik langsung dari menu Pengaturan.
- **UI Bersih & Sentralisasi Teks**:
  - Seluruh teks antarmuka tersentralisasi di `lib/core/constants/app_strings.dart`.
  - Desain minimalis tanpa subtitle bertele-tele dan bebas dari ikon dekoratif non-substansi.

---

## 🏗️ Desain Arsitektur & Struktur Folder

```
lib/
├── core/
│   ├── constants/       # AppConstants & AppStrings (Sentralisasi Teks)
│   ├── database/        # DatabaseHelper (SQLite v8 migration)
│   └── utils/           # AdaptiveUtils, CacheManager, StorageHelper
├── data/
│   ├── models/          # ComicModel, DetailComicModel, ChapterModel, DownloadedChapterModel
│   ├── repositories/    # ComicRepository (Single Source of Truth)
│   └── services/        # ScraperService (REST API) & DownloadService (Streaming I/O)
└── presentation/
    ├── navigation/      # Navigasi & Routing GoRouter
    ├── pages/
    │   ├── home/        # HomePage & HomeContent
    │   ├── detail/      # DetailPage & komponen spesifik (Header, Filter, Poster, CTA, Skeleton)
    │   ├── reader/      # ReaderPage & komponen (Manga, RetryableImage, BottomBar, Overlay)
    │   ├── collection/  # CollectionPage, CollectionBookmarkTab, CollectionDownloadsTab
    │   ├── comic_list_page.dart  # Halaman penjelajah katalog komik & filter genre
    │   └── settings_page.dart    # Halaman pengaturan preferensi baca & cache storage
    ├── providers/       # Specialized Providers (Home, Detail, Reader, Library, Settings, Download)
    └── widgets/         # Komponen global (ComicCard, ChapterTile, SearchInput, Shimmer, Dialogs)
```

---

## 🛠️ Persyaratan Pra-Instalasi (System Requirements)

- **Flutter SDK** (Versi 3.0.0 ke atas sangat disarankan) - [Panduan Instalasi Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (Otomatis terpasang bersama Flutter SDK)
- **Visual Studio Code** ATAU **Android Studio**
- **Perangkat Target**: Emulator Android/iOS atau HP fisik (via Kabel Data USB Debugging / Wi-Fi Debugging).

---

## 🚀 Cara Instalasi & Menjalankan Aplikasi (Clone & Run)

### A. Menggunakan Visual Studio Code (Rekomendasi Utama)

1. **Clone Repositori:**
   ```bash
   git clone https://github.com/ryuuken03/maca_comic_reader_flutter.git
   cd maca
   ```
2. **Pasang Dependensi (*Packages*):**
   Buka terminal di VS Code (**Ctrl + `**) dan jalankan:
   ```bash
   flutter pub get
   ```
3. **Menjalankan di Emulator atau HP Fisik:**
   - Pilih target perangkat di bilah status kanan bawah VS Code (Android Emulator, iOS Simulator, atau nama HP fisik Anda).
   - Pastikan **USB Debugging** telah diaktifkan jika menggunakan HP fisik Android.
   - Buka file `lib/main.dart` dan tekan **F5** (atau klik menu *Run* -> *Start Debugging*).

---

### B. Menggunakan Terminal / Command Prompt CLI

1. **Pasang Dependensi:**
   ```bash
   flutter pub get
   ```
2. **Cek Koneksi Perangkat:**
   ```bash
   flutter devices
   ```
3. **Jalankan Aplikasi:**
   ```bash
   flutter run
   ```
   *(Gunakan `flutter run -d <DEVICE_ID>` jika terhubung ke lebih dari satu perangkat).*

---

### C. Menggunakan Android Studio

1. Buka Android Studio, pilih menu **"Get from VCS"**.
2. Tempel URL repositori Git dan klik **Clone**.
3. Buka file `pubspec.yaml`, lalu klik tombol **"Pub get"** di bagian atas editor.
4. Pilih perangkat dari Device Manager, lalu klik tombol **▶ Run** (atau tekan `Shift + F10`).

---

## 📦 Panduan Build APK (Android)

### 1. Build APK Debug
Digunakan untuk pengujian cepat langsung di perangkat fisik tanpa konfigurasi signing key/keystore:
```bash
flutter build apk --debug
```
- **Lokasi Output:** `build/app/outputs/flutter-apk/app-debug.apk`

### 2. Build APK Release
Menghasilkan APK teroptimasi (kode di-compile ke machine code biner penuh, ukuran lebih kecil, dan performa maksimal):
- **Universal APK:**
  ```bash
  flutter build apk --release
  ```
  **Lokasi Output:** `build/app/outputs/flutter-apk/app-release.apk`

- **Split per ABI (Rekomendasi - Ukuran Jauh Lebih Ringan):**
  Memisahkan APK berdasarkan arsitektur CPU target (misal: `arm64-v8a` untuk smartphone modern):
  ```bash
  flutter build apk --split-per-abi
  ```
  **Lokasi Output:** `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (dan arsitektur lainnya).

### 3. Instalasi APK ke Perangkat via ADB
Setelah build selesai, APK dapat langsung dipasang ke perangkat yang terhubung:
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
*(Atau salin file APK langsung ke penyimpanan smartphone).*

---

## 💡 Catatan & Panduan Pengujian

- **Pengujian Otomatis**: Jalankan `flutter test` untuk mengeksekusi seluruh *unit test* dan *widget test* (Adaptive Grid, Koleksi & Filter, Detail Badges, Reader Ergonomics, Cache Manager, dan Scraper Service).
- **Penanganan Gambar & Cloudflare**: Header penyamaran browser disetel pada `AppConstants.imageHeaders` untuk memastikan kelancaran pemuatan thumbnail dan halaman komik. Disarankan melakukan pengujian pada emulator/perangkat fisik Android/iOS asli.

---

*Proyek ini dikembangkan dengan arsitektur bersih, performa tinggi, dan standar kode yang terjaga rapi.*
