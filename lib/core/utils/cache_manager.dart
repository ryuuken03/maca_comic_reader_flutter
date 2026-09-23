import 'dart:io';
import 'dart:math';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CustomCacheManager {
  static const String key = 'maca_reader_cache';

  static CacheManager instance = CacheManager(
    Config(
      key,
      maxNrOfCacheObjects: 300, // Batasi jumlah file
      stalePeriod: const Duration(days: 3), // Hapus otomatis setelah 3 hari
    ),
  );
}

class StorageHelper {
  /// Menghitung total ukuran file di dalam sebuah direktori secara asinkron.
  static Future<int> getDirectorySizeBytes(Directory dir) async {
    try {
      if (!await dir.exists()) return 0;
      int total = 0;
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Menghapus seluruh isi file dan folder di dalam direktori secara fisik dari disk.
  static Future<void> deleteDirectoryContents(Directory dir) async {
    try {
      if (!await dir.exists()) return;
      try {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
        return;
      } catch (_) {}

      await for (final entity in dir.list(recursive: false, followLinks: false)) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
  }

  /// Menghitung ukuran direktori cache reader chapter.
  static Future<int> getReaderCacheSizeBytes({Directory? baseDir}) async {
    try {
      final rootDir = baseDir ?? await getTemporaryDirectory();
      final readerDir = Directory(path.join(rootDir.path, CustomCacheManager.key));
      return await getDirectorySizeBytes(readerDir);
    } catch (_) {
      return 0;
    }
  }

  /// Menghitung ukuran direktori cache thumbnail komik (DefaultCacheManager).
  static Future<int> getThumbnailCacheSizeBytes({Directory? baseDir}) async {
    try {
      final rootDir = baseDir ?? await getTemporaryDirectory();
      final thumbDir = Directory(path.join(rootDir.path, 'libCachedImageData'));
      return await getDirectorySizeBytes(thumbDir);
    } catch (_) {
      return 0;
    }
  }

  /// Menghitung total gabungan ukuran cache.
  static Future<int> getTotalCacheSizeBytes({Directory? baseDir}) async {
    final reader = await getReaderCacheSizeBytes(baseDir: baseDir);
    final thumb = await getThumbnailCacheSizeBytes(baseDir: baseDir);
    return reader + thumb;
  }

  /// Format angka bytes menjadi teks ringkas (B, KB, MB, GB).
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    final clampedI = i.clamp(0, suffixes.length - 1);
    if (clampedI == 0) return '$bytes B';
    final size = bytes / pow(1024, clampedI);
    return '${size.toStringAsFixed(1)} ${suffixes[clampedI]}';
  }

  /// Menghapus seluruh cache reader chapter dari database dan disk fisik.
  static Future<void> clearReaderCacheOnDisk({Directory? baseDir}) async {
    if (baseDir == null) {
      try {
        await CustomCacheManager.instance.emptyCache();
      } catch (_) {}
    }
    try {
      final rootDir = baseDir ?? await getTemporaryDirectory();
      final readerDir = Directory(path.join(rootDir.path, CustomCacheManager.key));
      await deleteDirectoryContents(readerDir);
    } catch (_) {}
  }

  /// Menghapus seluruh cache thumbnail/cover dari database dan disk fisik.
  static Future<void> clearThumbnailCacheOnDisk({Directory? baseDir}) async {
    if (baseDir == null) {
      try {
        await DefaultCacheManager().emptyCache();
      } catch (_) {}
    }
    try {
      final rootDir = baseDir ?? await getTemporaryDirectory();
      final thumbDir = Directory(path.join(rootDir.path, 'libCachedImageData'));
      await deleteDirectoryContents(thumbDir);
    } catch (_) {}
  }
}
