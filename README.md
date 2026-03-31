# Maca Komik (KomikCast API Client) 📖⚡

Maca Komik adalah aplikasi pembaca komik lintas-platform berperforma tinggi yang dibangun menggunakan **Flutter**. Aplikasi ini murni memakan jalur REST API JSON (Tanpa Scraping HTML kuno), dilengkapi sistem pencegahan blokir *Cloudflare*, dan fitur koleksi/pengingat (*Bookmark & History*) otomatis yang tertanam di SQLite lokal (Offline).

## 🌟 Fitur Utama
- **Arsitektur Bersih (Clean Architecture)**: Dipisahkan menjadi lapisan Data (Repository/Model) dan Presentasi (Specialized Providers) untuk skalabilitas tinggi.
- **Efisien State Management**: Menggunakan 4 Provider spesifik (`Home`, `Detail`, `Reader`, `Library`) guna performa render yang lebih ringan dan kode yang terorganisir.
- **Antarmuka Interaktif**: Navigasi menggunakan *GoRouter* (Instan & Bebas Lag) dengan UI yang mendukung Dark Mode penuh (Toolbar konsisten).
- **Eksplorasi Katalog Komik**: Menarik detail katalog dari sistem komik terintegrasi dengan filter genre yang dinamis.
- **Mode Baca (*Reader*) Optimal**: Penampil halaman memanjang (*Full-Width Infinite Scroll*) menggunakan `CachedNetworkImage` ber-Header HTTP tingkat lanjut.
- **Riwayat & Koleksi Cerdas (SQLite)**: Sinkronisasi otomatis ke _Database Offline_ untuk menyimpan progres baca (History) dan daftar favorit (Bookmark).

## 🏗️ Desain Arsitektur
Proyek ini mengikuti pola **Clean Architecture** sederhana:
- **Data Layer**: 
  - `ScraperService`: Penanggung jawab pengambilan data API.
  - `DatabaseHelper`: Penanggung jawab persistensi lokal SQLite.
  - `ComicRepository`: *Single Source of Truth* yang mengoordinasikan sumber data untuk UI.
- **Presentation Layer (Providers)**:
  - `HomeProvider`: Mengelola feed beranda, pencarian, dan penemuan komik.
  - `DetailProvider`: Mengelola informasi detail komik dan daftar chapter.
  - `ReaderProvider`: Mengelola penampil gambar chapter dan metadata pembaca.
  - `LibraryProvider`: Mengelola sinkronisasi Bookmark dan Riwayat Baca.

---

## 🛠️ Persyaratan Pra-Instalasi (System Requirements)
Pastikan Anda sudah menginstal sistem inti berikut di komputer/laptop:
- **Flutter SDK** (Versi 3.0.0 ke atas sangat disarankan) - [Cara Instal Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (Biasanya otomatis menempel satu paket dengan Flutter)
- **Visual Studio Code** ATAU **Android Studio**
- Tersedia **Emulator Android/iOS** atau Perangkat HP sungguhan (via Kabel Data / WiFi Debugging).

---

## 🚀 Cara Instalasi (Clone & Run)

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
   ```bash
   flutter pub get
   ```
3. **Pilih Perangkat Anda:**
   Lihat area bilah bawah (*Status Bar*) VS Code Anda bagian kanan bawah. Klik area `No Device` dan pilih nyalakan Emulator bawaan (seperti *Pixel API* / *Windows* / *Chrome*).
4. **Jalankan Aplikasi:**
   Buka file `lib/main.dart`, lalu silakan tekan tombol ikon ▶️ (Play) di antarmuka atas, ATAU pencet tombol sakti **F5** pada Keyboard untuk mulai *Compile & Debug*.

### B. Menggunakan Android Studio
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
