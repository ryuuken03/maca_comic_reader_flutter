# Maca Comic Reader - Roadmap & Future Implementation Phases

Dokumen ini berisi rencana pengembangan dan panduan teknis untuk fase-fase berikutnya (*upcoming phases*) pada aplikasi **Maca Comic Reader**. Dokumen ini dirancang agar setiap pengembang atau asisten AI dapat langsung melanjutkan pekerjaan dengan arsitektur yang konsisten.

---

## 📌 Status Fase Saat Ini

| Fase | Deskripsi | Status |
|---|---|---|
| **Fase 1** | Scraping data, State Management (Provider), SQLite database (Riwayat, Bookmark) | ✅ Selesai |
| **Fase 2** | Optimasi Memori: `memCacheWidth` & `maxWidthDiskCache`, eliminasi `BackdropFilter`, Local TTL Caching | ✅ Selesai |
| **Fase 3** | Layout Responsif Tablet: `NavigationRail`, Master-Detail 2-Kolom di DetailPage, Webtoon maxWidth 720dp | ✅ Selesai |
| **Fase 4** | Kuota Grid Adaptif (Ganjil 21 / Genap 20), Search Debounce (500ms), `CustomScrollView` + `SliverGrid` recycling, Persistensi Mode Baca (Webtoon/Manga) | ✅ Selesai |
| **Fase 5** | Kenyamanan Membaca: Toggle RTL/LTR Manga, Overlay Jam & Baterai Terisolasi, Brightness Tint Slider (Non-BackdropFilter) | ✅ Selesai |
| **Fase 6** | Dashboard Pengaturan & Manajemen Penyimpanan: SegmentedButton, Selective Eviction, Disk Cache Calculator | ✅ Selesai |
| **Fase 7** | Mode Offline & Download Chapter: DownloadService, Streamed I/O, Concurrency Pool, SQLite v8, DownloadsPage & Tab Terpadu CollectionPage | ✅ Selesai |
| **Fase 8** | Pencadangan & Pemulihan (Backup & Restore Data) | ⏳ Belum Diimplementasi |

---

## 📖 Ringkasan Fase yang Sudah Selesai (Fase 1 – Fase 7)

### 📖 Fase 5: Kenyamanan Membaca Lanjutan (Advanced Reader Ergonomics) ✅
*Tujuan: Meningkatkan kenyamanan visual dan kontrol saat membaca chapter komik.*

#### 1. Arah Baca Manga (Right-to-Left / RTL vs Left-to-Right / LTR) ✅
- **Implementasi:**
  - Toggle arah baca pada `ReaderPage` saat berada di **Mode Manga** via AppBar action.
  - Pada `PageView.builder`, properti `reverse: _isRTL`.
  - Preferensi disimpan ke tabel `app_settings` (`reader_direction`: `'rtl'` atau `'ltr'`).

#### 2. Overlay Jam Digital & Indikator Baterai Mini ✅
- **Implementasi:**
  - Widget terisolasi `ReaderOverlayWidget` di pojok kanan bawah layar reader.
  - Format jam HH:mm diperbarui via timer 30 detik tanpa me-rebuild tree reader utama.
  - Sisa baterai dan status pengisian daya menggunakan `battery_plus`.
  - Toggle tampilkan/sembunyikan di AppBar dengan persistensi `reader_show_overlay`.

#### 3. Brightness Slider Mandiri (Dark Tint Filter) ✅
- **Implementasi:**
  - Overlay `IgnorePointer` berupa container hitam dengan nilai opasitas (`0.0` sampai `0.7`) yang diatur lewat slider di `BottomAppBar`.
  - Nilai disimpan ke `app_settings` (`reader_brightness_filter`).
  - Nol penggunaan `BackdropFilter` (aman GPU & RAM).

#### 4. Navigasi Tombol Fisik Volume ⏭️ *(Dilewati)*
- **Catatan:** Dilewati sesuai instruksi pengguna demi keamanan dan kompatibilitas tombol fisik device.

---

### ⚙️ Fase 6: Dashboard Pengaturan & Manajemen Penyimpanan (Settings & Storage Hub) ✅
*Tujuan: Memberikan kendali penuh pada pengguna terkait penggunaan kuota dan memori HP.*

#### 1. Akses Pengaturan Terintegrasi ✅
- **Implementasi:**
  - Destinasi keempat pada `BottomNavigationBar` (Mobile) dan `NavigationRail` (Tablet) `HomePage`.
  - Routing GoRouter: `/settings` menuju `SettingsPage`.
  - Sentralisasi string UI di `AppStrings` (`app_strings.dart`) agar modular dan mudah dirawat.

#### 2. Kalkulator Disk Cache Real-Time ✅
- **Implementasi:**
  - `StorageHelper.getReaderCacheSizeBytes()` & `getThumbnailCacheSizeBytes()` menghitung ukuran direktori cache secara asynchronous.
  - `StorageHelper.formatBytes(int bytes)` memformat ukuran secara ringkas (*contoh: "12.4 MB"*).

#### 3. Pembersihan Cache Selektif (Granular Cache Eviction) ✅
- **Fitur:**
  - *Cache Sampul*: Menghapus thumbnail via `DefaultCacheManager().emptyCache()`.
  - *Cache Reader*: Menghapus cache resolusi tinggi via `CustomCacheManager.instance.emptyCache()`.
  - *Total Cache*: Menghapus seluruh cache (thumbnail + reader + in-memory API cache via `ApiCacheManager`).
  - Dialog konfirmasi ringkas dan feedback snackbar.

#### 4. Pengaturan Preferensi Global ✅
- **Fitur:**
  - Mode baca default: Webtoon atau Manga.
  - Arah baca Manga: Kanan ke Kiri (RTL) atau Kiri ke Kanan (LTR).
  - Kunci orientasi portrait (`reader_orientation_lock`) yang diterapkan di `ReaderPage` dan di-reset saat keluar reader.
  - Persistensi menggunakan SQLite `app_settings` via `DatabaseHelper`.

---

### 💾 Fase 7: Mode Offline & Download Chapter (Offline Reading) ✅
*Tujuan: Memungkinkan pengguna membaca komik favorit di mana saja tanpa kuota internet.*

#### 1. Arsitektur Download Manager ✅
- **Implementasi:**
  - Layanan `DownloadService` dengan antrean (*queue*) unduhan.
  - **Aturan Konkurensi:** Unduh gambar chapter dalam pool maksimal 2–3 gambar simultan dengan jeda acak (150ms–300ms) untuk mencegah pemblokiran WAF/Cloudflare (sesuai aturan [AGENTS.md](file:///c:/Project/Antigravity/maca/AGENTS.md)).
  - Simpan gambar ke direktori aman aplikasi:
    `getApplicationDocumentsDirectory()/downloads/<comic_slug>/<chapter_slug>/`

#### 2. Database Chapter Terunduh ✅
- Tambahkan tabel SQLite `downloaded_chapters`:
  ```sql
  CREATE TABLE downloaded_chapters (
    id TEXT PRIMARY KEY,
    comic_id TEXT,
    comic_title TEXT,
    chapter_title TEXT,
    chapter_url TEXT,
    local_path TEXT,
    page_count INTEGER,
    downloaded_at INTEGER
  );
  ```

#### 3. Integrasi Otomatis pada `ReaderPage` ✅
- Saat membuka chapter, `ReaderPage` terlebih dahulu memeriksa keberadaan file lokal di `downloaded_chapters`.
- Jika tersedia secara offline, gunakan `Image.file(File(path))` alih-alih `CachedNetworkImage`.

#### 4. UI Status Unduhan di `DetailPage`, `DownloadsPage` & Tab Terpadu `CollectionPage` ✅
- Tombol aksi icon download di setiap list chapter:
  - Icon panah unduh (belum diunduh).
  - Indikator putar / circular progress (sedang mengunduh).
  - Icon centang hijau (sudah siap dibaca offline).
- Integrasi tab **Koleksi** (`CollectionPage`) pada `BottomNavigationBar` & `NavigationRail` yang menyatukan komik tersimpan dan komik terunduh dengan `TabBar`.
- Filter interaktif di `DetailPage` (`Semua` & `Terunduh`) untuk menyaring chapter offline secara instan dengan empty state informatif.

---

## 🚀 Rencana Fase Selanjutnya (Upcoming Phase)

### 🔄 Fase 8: Pencadangan & Pemulihan (Backup & Restore Data) ⏳ (Belum Diimplementasi)
*Tujuan: Melindungi riwayat membaca dan koleksi komik pengguna saat berganti smartphone.*

#### 1. Format Skema Ekspor JSON
- Struktur data JSON komprehensif:
  ```json
  {
    "version": 1,
    "exported_at": 1727000000000,
    "bookmarks": [ ... ],
    "history": [ ... ],
    "settings": { ... }
  }
  ```

#### 2. Alur Ekspor
- Baca seluruh tabel `bookmarks`, `history`, dan `app_settings` dari SQLite.
- Konversi ke file string JSON.
- Gunakan package `file_picker` atau `share_plus` agar pengguna dapat menyimpannya ke folder *Downloads*, *Google Drive*, atau aplikasi pesan.

#### 3. Alur Impor & Validasi
- Pengguna memilih file `.json`.
- Validasi skema dan versi format file.
- Opsi penggabungan (*merge*) data atau penimpaan (*replace*) dengan konfirmasi dialog.

---

## 🛠️ Panduan Memulai Fase Baru bagi AI / Developer

Saat diminta mengeksekusi Fase 8:
1. Baca kembali aturan wajib di [AGENTS.md](file:///c:/Project/Antigravity/maca/AGENTS.md).
2. Buat `implementation_plan.md` yang spesifik untuk fase tersebut dan mintakan persetujuan pengguna.
3. Jalankan pengujian otomatis (`flutter analyze` dan `flutter test`) sebelum dan sesudah perubahan.
4. Perbarui status checklist di dokumen ini.
