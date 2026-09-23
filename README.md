# Maca Komik (KomikCast API Client) 📖⚡

Maca Komik adalah aplikasi pembaca komik lintas-platform berperforma tinggi yang dibangun menggunakan **Flutter**. Aplikasi ini murni memakan jalur REST API JSON (Tanpa Scraping HTML kuno), dilengkapi sistem pencegahan blokir *Cloudflare*, dan fitur koleksi/pengingat (*Bookmark & History*) otomatis yang tertanam di SQLite lokal (Offline).

## 🌟 Fitur Utama
- **Arsitektur Bersih (Clean Architecture)**: Dipisahkan menjadi lapisan Data (Repository/Model/Service) dan Presentasi (Specialized Providers) untuk skalabilitas tinggi.
- **Efisien State Management**: Menggunakan Provider terspesialisasi (`Home`, `Detail`, `Reader`, `Library`, `Settings`, `Download`) guna performa render yang ringan dan modular.
- **Mode Offline & Download Manager**: Pengguna dapat mengunduh chapter komik untuk dibaca tanpa kuota. Menggunakan *zero-buffer streaming I/O* langsung ke disk (RAM < 10 MB) dan *concurrency pool* (2–3 gambar paralel + jitter anti-bot).
- **Mode Baca Optimal & Adaptif**: Penampil gambar memanjang (*Webtoon*) dan per halaman (*Manga PageView* RTL/LTR) dengan pembatasan bitmap `cacheWidth`/`memCacheWidth` demi mencegah crash OOM.
- **Riwayat, Koleksi & Unduhan Cerdas (SQLite v8)**: Sinkronisasi otomatis progres baca (*History*), daftar favorit (*Bookmark*), pengaturan preferensi (*app_settings*), dan katalog offline (*downloaded_chapters*).
- **Dashboard Penyimpanan & Granular Cache Eviction**: Manajemen mandiri cache thumbnail, cache reader, dan file unduhan chapter komik langsung dari menu Pengaturan.

## 🏗️ Desain Arsitektur
Proyek ini mengikuti pola **Clean Architecture**:
- **Data Layer**: 
  - `ScraperService`: Penanggung jawab pengambilan data API REST.
  - `DownloadService`: Penanggung jawab antrean download chapter, streaming I/O, dan concurrency pool.
  - `DatabaseHelper`: Penanggung jawab persistensi lokal SQLite (Bookmarks, History, Settings, Downloaded Chapters).
  - `ComicRepository`: *Single Source of Truth* yang mengoordinasikan sumber data untuk UI.
- **Presentation Layer (Providers & Pages)**:
  - `HomeProvider` & `HomePage`: Mengelola feed beranda, pencarian, dan grid adaptif komik.
  - `DetailProvider` & `DetailPage`: Mengelola detail komik, list chapter, dan trigger download chapter.
  - `ReaderProvider` & `ReaderPage`: Mengelola penampil gambar chapter (online via `CachedNetworkImage` dan offline via `Image.file`).
  - `LibraryProvider` & `BookmarkPage` / `HistoryPage`: Mengelola sinkronisasi Bookmark dan Riwayat Baca.
  - `SettingsProvider` & `SettingsPage`: Mengelola preferensi baca global dan kalkulator disk cache.
  - `DownloadProvider` & `DownloadsPage`: Mengelola status unduhan aktif, tracking progres, dan penghapusan chapter lokal.

---

## 🛠️ Persyaratan Pra-Instalasi (System Requirements)
Pastikan Anda sudah menginstal sistem inti berikut di komputer/laptop:
- **Flutter SDK** (Versi 3.0.0 ke atas sangat disarankan) - [Cara Instal Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (Biasanya otomatis menempel satu paket dengan Flutter)
- **Visual Studio Code** ATAU **Android Studio**
- Tersedia **Emulator Android/iOS** atau Perangkat HP sungguhan (via Kabel Data / WiFi Debugging).

---

## 🚀 Cara Instalasi & Menjalankan Aplikasi (Clone & Run)

### A. Menggunakan Visual Studio Code (Rekomendasi Utama)

1. **Clone Repositori Ini:**
   Buka *Command Prompt/Terminal/Git Bash* di folder tempat Anda ingin menaruh proyek ini, dan ketikkan:
   ```bash
   git clone https://github.com/ryuuken03/maca_comic_reader_flutter.git
   cd maca
   ```
2. **Pasang Dependensi (*Packages*):**
   Buka folder proyek ini ke dalam **Visual Studio Code**, kemudian tekan **Ctrl + `** untuk membuka Terminal internal VS Code. Ketikkan:
   ```bash
   flutter pub get
   ```

3. **Menjalankan di Emulator:**
   - Lihat area bilah bawah (*Status Bar*) VS Code Anda bagian kanan bawah.
   - Klik area nama perangkat (misal `No Device` atau `Chrome`) lalu pilih nama Emulator yang ingin dijalankan (Android Emulator / iOS Simulator).
   - Buka file `lib/main.dart` dan tekan tombol **F5** pada Keyboard untuk menjalankan aplikasi (atau klik menu *Run* -> *Start Debugging*).

4. **Menjalankan di HP Fisik (Android / iOS):**
   - **Persiapan HP Android**:
     1. Aktifkan **Developer Options**: Masuk ke menu *Settings* -> *About Phone* -> Ketuk *Build Number* sebanyak 7 kali hingga muncul pesan bahwa developer mode aktif.
     2. Aktifkan **USB Debugging**: Masuk ke menu *Settings* -> *Developer Options* -> Nyalakan tombol *USB Debugging*.
   - **Persiapan HP iOS (Harus menggunakan MacOS & Xcode)**:
     1. Hubungkan HP iOS ke komputer Mac menggunakan kabel data.
     2. Di HP iOS, aktifkan **Developer Mode** melalui *Settings* -> *Privacy & Security* -> Nyalakan *Developer Mode* (ikuti instruksi restart perangkat).
     3. Buka folder `ios` menggunakan Xcode untuk menyetel *Signing & Capabilities* (Team dan Bundle Identifier) agar bisa di-deploy ke HP Anda.
   - **Koneksi & Eksekusi di VS Code**:
     1. Hubungkan HP menggunakan kabel data (pastikan mode USB di HP diset ke *File Transfer*).
     2. Setujui dialog otorisasi *USB Debugging* yang muncul di layar HP Anda (*"Allow USB debugging?"*).
     3. Pada status bar kanan bawah VS Code, pastikan nama HP fisik Anda sudah terpilih (misal: *Samsung SM-G998B* atau *iPhone*).
     4. Tekan **F5** untuk memulai proses compile dan instalasi langsung ke HP Anda.

---

### B. Menggunakan Editor Lain & Terminal CLI (Sublime Text, Vim, Cursor, Notepad++, dll.)

Jika Anda menggunakan editor teks ringan lainnya, Anda dapat mengontrol kompilasi dan instalasi sepenuhnya melalui baris perintah (*command line*):

1. **Pasang Dependensi**:
   ```bash
   flutter pub get
   ```
2. **Cek Koneksi Perangkat**:
   Hubungkan HP fisik Anda (dengan USB Debugging menyala) atau nyalakan emulator, lalu jalankan perintah:
   ```bash
   flutter devices
   ```
   Pastikan nama perangkat HP atau emulator Anda terdaftar di output tersebut dengan status *online*.
3. **Jalankan Aplikasi**:
   - Jika hanya ada **satu perangkat** aktif, jalankan perintah berikut di terminal root proyek:
     ```bash
     flutter run
     ```
   - Jika ada **beberapa perangkat** aktif, jalankan menggunakan ID perangkat target:
     ```bash
     flutter run -d <DEVICE_ID>
     ```
   - *Tips interaktif*: Ketik `r` di terminal untuk *Hot Reload* cepat, `R` untuk *Hot Restart*, atau `q` untuk keluar dan menutup aplikasi.

---

### C. Menggunakan Android Studio
1. **Clone Proyek:** 
   Buka Android Studio, pilih menu **"Get from VCS"** (Paling awal di layar sambutan).
2. **Tempel URL:** 
   Masukkan link git proyek ini dan tentukan lokasi foldernya. Klik **Clone**.
3. **Tarik Dependensi:** 
   Buka file `pubspec.yaml`, dan akan muncul garis batas / pita khusus di atas layar bertuliskan **"Pub get"**. Klik tombol tersebut untuk menyedot semua modul secara instan.
4. **Jalankan Aplikasi:**
   Nyalakan AVD (*Android Virtual Device*) Anda dari menu navigasi Manajer Perangkat Atas. Setelah nyala, klik panah hijau besar (**▶ Run**) atau tekan `Shift + F10`.

---

## 💡 Troubleshooting & Bantuan
* **Masalah `Method or Getter Not Defined`?** Pastikan Anda melakukan `flutter clean` lalu `flutter pub get` ulang untuk membersihkan tumpukan _cache_ yang rusak di komputer Anda.
* **Gambar Gagal Termuat / Cloudflare 403?** Header rahasia emulator untuk *Bypass* Cloudflare disetel secara permanen di class *Reader Page*. Aplikasi ini akan paling aman dites di emulator/Android asli (Bukan di *Local Web/Chrome*, karena Web menderita batasan CORS yang ketat).

*Proyek ini dirancang menggunakan arsitektur bersih dan struktur yang terus relevan! Selamat berkreasi dan mencoba.*
