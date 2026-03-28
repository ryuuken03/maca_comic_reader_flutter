# Maca Komik (KomikCast API Client) 📖⚡

Maca Komik adalah aplikasi pembaca komik lintas-platform berperforma tinggi yang dibangun menggunakan **Flutter**. Aplikasi ini murni memakan jalur REST API JSON (Tanpa Scraping HTML kuno), dilengkapi sistem pencegahan blokir *Cloudflare*, dan fitur koleksi/pengingat (*Bookmark & History*) otomatis yang tertanam di SQLite lokal (Offline).

## 🌟 Fitur Utama
- **Antarmuka Interaktif**: Menggunakan *GoRouter* (Perpindahan layar instan bebas lag) & State dinamis dengan *Provider*.
- **Eksplorasi Katalog Komik**: Menarik detail katalog dari sistem komik yang terus di-_update_.
- **Mode Baca (*Reader*) Optimal**: Penampil halaman memanjang (*Full-Width Infinite Scroll*) menggunakan `CachedNetworkImage` ber-Header HTTP tingkat lanjut (Bebas Error Pemblokiran HTTP 403).
- **Riwayat Cerdas (History)**: Secara otomatis merekam jejak posisi chapter spesifik saat dibuka, lengkap dengan sinkronisasi ke _Database Offline SQLite_ (Versi 3).  
- **Koleksi (Bookmark)**: Simpan ribuan judul komik favorit ke tabel Anda tanpa batas untuk akses super cepat. 

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
