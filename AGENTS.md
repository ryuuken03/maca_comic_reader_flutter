# Maca Comic Reader - Project Guidelines & Rules for AI Agents

Dokumen ini adalah aturan wajib (*mandatory rules*) bagi asisten AI (Google Antigravity / Gemini) saat mengembangkan atau memodifikasi kode di repositori **Maca Comic Reader**. Setiap sesi dan conversation baru **wajib** mematuhi pedoman ini.

---

## 1. Aturan Optimasi Memori (RAM & GPU)

Aplikasi komik memuat ratusan gambar beresolusi tinggi. Kesalahan manajemen memori gambar akan menyebabkan *Out of Memory (OOM)* crash pada smartphone berspesifikasi rendah (RAM 2GB–3GB).

- **Wajib `memCacheWidth` & `maxWidthDiskCache`:**
  - Setiap kali menggunakan `CachedNetworkImage` atau `Image.network` untuk **thumbnail / cover komik**, **WAJIB** sertakan pembatas resolusi memori:
    ```dart
    CachedNetworkImage(
      imageUrl: comic.thumbUrl,
      memCacheWidth: 350, // Cukup 300-350px decode untuk thumbnail grid
      maxWidthDiskCache: 600,
      ...
    )
    ```
  - Untuk gambar **chapter reader**, batas `memCacheWidth` harus dihitung proporsional terhadap lebar layar aktual dan device pixel ratio:
    ```dart
    memCacheWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
    ```
- **Wajib `cacheWidth` pada `Image.file` (Mode Offline Reader):**
  - Saat me-render gambar chapter lokal dari flash storage menggunakan `Image.file`, **WAJIB** sertakan pembatas decoding:
    ```dart
    Image.file(
      File(localPath),
      cacheWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round(),
      fit: BoxFit.fitWidth,
    )
    ```
  - Tanpa `cacheWidth`, Flutter men-decode bitmap resolusi mentah (2500–4000px) ke GPU/RAM yang memicu OOM crash seketika pada smartphone RAM 2GB–3GB.
- **Dilarang Menggunakan `BackdropFilter` di dalam Item Grid / List:**
  - `BackdropFilter` memicu offscreen rendering (`saveLayer`) di GPU. Jika dipasang pada item yang dapat di-scroll (seperti `ComicCard`), akan menyebabkan frame drop parah.
  - **Gunakan `LinearGradient`** atau warna solid transparan sebagai alternatif overlay teks.
- **Hindari `shrinkWrap: true` pada List/Grid Berukuran Besar:**
  - Gunakan `CustomScrollView` bersama `SliverGrid` atau `SliverList` agar Flutter dapat mendaur ulang (*recycle*) widget saat scrolling, bukan me-render seluruh widget ke RAM sekaligus.

---

## 2. Aturan Layout Responsif (Tablet & Smartphone)

Aplikasi harus terlihat proporsional di smartphone portrait, smartphone landscape, tablet (8–12 inci), serta layar desktop/web.

- **Dilarang Hardcoding `crossAxisCount: 2` pada GridView:**
  - Jangan gunakan nilai kolom statis tanpa mempertimbangkan lebar layar.
  - Gunakan `SliverGridDelegateWithMaxCrossAxisExtent`:
    ```dart
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 180, // Ukuran kartu ideal di semua device
      childAspectRatio: 0.68,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    )
    ```
- **Adaptive Grid Take Data (Genap 20 / Ganjil 21):**
  - Saat me-render grid komik (`HomePage`, `ComicListPage`), hitung estimasi jumlah kolom:
    - Jika jumlah kolom **ganjil** (seperti 3 atau 5 kolom), minta data sebanyak **21 item** agar baris terbawah terisi penuh rata dan tidak ada slot kartu kosong/gantung.
    - Jika jumlah kolom **genap** (seperti 2 atau 4 kolom), minta data sebanyak **20 item** (10 baris x 2 atau 5 baris x 4).
- **Tablet Adaptive Navigation:**
  - Pada layar lebar (`width >= 640dp`), gunakan `NavigationRail` vertikal di sisi kiri dan hilangkan `BottomNavigationBar` agar navigasi nyaman dijangkau ibu jari saat memegang tablet.
- **Detail Page Master-Detail Split-View:**
  - Pada tablet / desktop (`width >= 720dp`), bagi halaman detail menjadi 2 kolom berdampingan:
    - Kolom Kiri (~35-40%): Poster cover, Status, Tipe, Format, Genre chips, tombol aksi bookmark/baca, dan Sinopsis lengkap.
    - Kolom Kanan (~60-65%): Search input chapter, filter sorting Asc/Desc, dan daftar chapter dalam `ListView` tersendiri.
- **Reader Webtoon di Layar Lebar:**
  - Pada layar tablet / desktop (`width >= 720dp`), list gambar vertikal **harus dibatasi** dengan `ConstrainedBox(constraints: BoxConstraints(maxWidth: 720))` dan di-center agar panel webtoon tidak tertarik memenuhi seluruh layar secara berlebihan.

---

## 3. Aturan Pengalaman Membaca (Reader Ergonomics)

- **Immersive Fullscreen Mode:**
  - Kontrol baca (AppBar & BottomBar) harus dapat disembunyikan/dimunculkan dengan sekali tap di layar.
  - Saat kontrol disembunyikan, aktifkan `SystemUiMode.immersiveSticky` agar bilah status dan navigasi sistem Android/iOS tidak mengganggu pembacaan.
- **Dukungan Mode Baca Fleksibel & Persistensi:**
  - Sediakan opsi bagi pengguna untuk beralih antara:
    - **Mode Webtoon:** Scroll vertikal kontinyu (ideal untuk manhwa / komik webtoon).
    - **Mode Manga:** Paging horizontal per halaman (`PageView`) dengan indikator nomor halaman floating (ideal untuk manga tradisional Jepang / komik strip).
  - Pilihan mode baca **wajib disimpan secara persisten** di penyimpanan lokal agar tidak pernah ter-reset saat pengguna berpindah ke chapter selanjutnya.

---

## 4. Aturan Jaringan, Caching & Anti-Bot

Backend komik (seperti Voratoon / Komikcast / Cloudflare) memiliki sistem proteksi WAF terhadap akses otomatis atau pola scraping agresif.

- **Local Caching Berbasis Waktu (TTL):**
  - Jangan pernah menembak API berulang kali untuk data statis / semi-statis.
  - Simpan genre di penyimpanan lokal (TTL 24 jam).
  - Simpan detail komik dan chapter list di memory/cache lokal (TTL 15–30 menit).
- **Pembatasan Lonjakan Request (Rate Limiting & Jitter):**
  - Berikan jeda acak manusiawi (*jitter delay* 150ms–350ms) antar pagination atau scraper berseri.
  - Jangan men-trigger download 50+ gambar chapter secara bersamaan; gunakan pembatas konkurensi (batching / pool 2–3 gambar paralel).
- **Zero-Buffer Streaming pada Download Chapter:**
  - Saat mengunduh gambar komik ke storage lokal (`DownloadService`), **WAJIB** menggunakan streaming pipa I/O langsung ke file (`Stream.pipe(File.openWrite())`).
  - **Dilarang keras** mengumpulkan puluhan file gambar ke RAM (`List<Uint8List>`) sebelum ditulis ke flash storage, agar penggunaan RAM proses download selalu terjaga di bawah 10 MB.
- **Debounce pada Input Pencarian:**
  - Setiap input pencarian teks interaktif harus memiliki debounce minimal 500ms agar tidak mengirim request di tiap karakter.
- **User-Agent & Error Handling:**
  - Sertakan header browser lengkap (`Referer`, `Origin`, `Accept`, `Accept-Language`).
  - Tangani kode status HTTP `429 Too Many Requests` dan `503 Service Unavailable` secara elegan menggunakan *exponential backoff* dan pesan user-friendly, BUKAN retry tanpa batas.

---

## 5. Aturan Desain Antarmuka, Pengaturan & Manajemen Teks (UI & String Guidelines)

- **Sentralisasi Teks Terpusat (`app_strings.dart`):**
  - Seluruh teks label, dialog, notifikasi, dan opsi antarmuka **wajib dipisahkan ke dalam satu file konstanta** (`lib/core/constants/app_strings.dart`).
  - Dilarang hardcoding teks string langsung di dalam widget agar kode mudah dirawat (*maintainable*).
- **Teks Ringkas & Lugas:**
  - Gunakan kalimat dan kata yang pendek, padat, dan *to-the-point* (misal: "Cache Sampul", "Hapus", "Kunci Portrait").
  - Hindari teks penjelasan yang bertele-tele atau paragraf deskripsi panjang jika tidak esensial.
- **Tanpa Subtitle pada Elemen Pengaturan:**
  - Jangan gunakan `subtitle` pada `ListTile` atau item opsi pengaturan. Cukup gunakan judul opsi dan kontrol aksi langsung (Switch, SegmentedButton, atau Tombol).
- **Bebas Icon Non-Substansi:**
  - Hindari memasang icon dekoratif yang tidak memiliki nilai fungsional (seperti icon hiasan samping `leading` di setiap baris ListTile). Pertahankan antarmuka tetap bersih, minimalis, dan fungsional.

---

## 6. Roadmap & Fase Pengembangan Lanjutan

Rincian fase pengembangan selanjutnya (Fase 8), termasuk arsitektur teknis dan panduan fitur, didokumentasikan di [ROADMAP.md](file:///c:/Project/Antigravity/maca/ROADMAP.md). AI agent wajib merujuk ke dokumen tersebut saat pengguna meminta kelanjutan pengembangan fitur.

