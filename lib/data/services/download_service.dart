import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/constants.dart';
import '../../core/database/database_helper.dart';
import '../models/downloaded_chapter_model.dart';
import 'scraper_service.dart';

class DownloadTask {
  final String comicId;
  final String comicTitle;
  final String comicThumbUrl;
  final String chapterTitle;
  final String chapterUrl;

  DownloadTask({
    required this.comicId,
    required this.comicTitle,
    this.comicThumbUrl = '',
    required this.chapterTitle,
    required this.chapterUrl,
  });
}

class DownloadProgress {
  final String chapterUrl;
  final double progress; // 0.0 to 1.0
  final int downloadedPages;
  final int totalPages;
  final bool isCompleted;
  final bool isFailed;
  final String? errorMessage;

  DownloadProgress({
    required this.chapterUrl,
    required this.progress,
    required this.downloadedPages,
    required this.totalPages,
    this.isCompleted = false,
    this.isFailed = false,
    this.errorMessage,
  });
}

class DownloadService {
  static final DownloadService instance = DownloadService._init();
  final ScraperService _scraperService = ScraperService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  final Set<String> _activeDownloads = {};
  final Set<String> _cancelledUrls = {};

  final StreamController<DownloadProgress> _progressController =
      StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  DownloadService._init();

  bool isDownloading(String chapterUrl) => _activeDownloads.contains(chapterUrl);

  void cancelDownload(String chapterUrl) {
    if (_activeDownloads.contains(chapterUrl)) {
      _cancelledUrls.add(chapterUrl);
    }
  }

  String _sanitizeFileName(String input) {
    return input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  }

  Future<Directory> getDownloadsDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${appDocDir.path}/downloads');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir;
  }

  Future<Directory> getChapterDirectory(String comicId, String chapterUrl) async {
    final downloadsDir = await getDownloadsDirectory();
    final cleanComicId = _sanitizeFileName(comicId.isEmpty ? 'unknown_comic' : comicId);
    final cleanChapterSlug = _sanitizeFileName(
      chapterUrl.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => 'chapter'),
    );
    final chapterDir = Directory('${downloadsDir.path}/$cleanComicId/$cleanChapterSlug');
    if (!await chapterDir.exists()) {
      await chapterDir.create(recursive: true);
    }
    return chapterDir;
  }

  Future<void> startDownload(
    DownloadTask task, {
    http.Client? httpClient,
  }) async {
    final chapterUrl = task.chapterUrl;
    if (_activeDownloads.contains(chapterUrl)) return;

    _activeDownloads.add(chapterUrl);
    _cancelledUrls.remove(chapterUrl);

    final client = httpClient ?? http.Client();
    final random = Random();

    try {
      _progressController.add(DownloadProgress(
        chapterUrl: chapterUrl,
        progress: 0.0,
        downloadedPages: 0,
        totalPages: 0,
      ));

      // 1. Dapatkan daftar URL gambar chapter
      final readerData = await _scraperService.getReaderDataBE(chapterUrl);
      final images = readerData.images;

      if (images.isEmpty) {
        throw Exception('Tidak ada halaman gambar yang ditemukan');
      }

      if (_cancelledUrls.contains(chapterUrl)) {
        throw Exception('Unduhan dibatalkan');
      }

      // 2. Siapkan direktori lokal
      final targetDir = await getChapterDirectory(task.comicId, chapterUrl);

      int completedCount = 0;
      int totalSize = 0;
      final totalPages = images.length;

      // 3. Pool konkurensi (maksimal 2 gambar simultan) dengan jeda jitter (150-300ms)
      const maxConcurrency = 2;
      int nextIndex = 0;

      Future<void> worker() async {
        while (true) {
          if (_cancelledUrls.contains(chapterUrl)) {
            break;
          }

          if (nextIndex >= totalPages) return;
          final currentIndex = nextIndex++;

          final imgUrl = images[currentIndex];
          final pageNum = currentIndex + 1;
          final fileName = '${pageNum.toString().padLeft(3, '0')}.jpg';
          final localFile = File('${targetDir.path}/$fileName');

          // Jeda jitter manusiawi (150ms - 300ms) untuk mencegah proteksi Cloudflare/WAF
          final jitterMs = 150 + random.nextInt(151);
          await Future.delayed(Duration(milliseconds: jitterMs));

          if (_cancelledUrls.contains(chapterUrl)) break;

          // Streaming I/O langsung ke disk tanpa menampung buffer gambar di RAM
          final request = http.Request('GET', Uri.parse(imgUrl));
          request.headers.addAll(AppConstants.imageHeaders);
          final response = await client.send(request);

          if (response.statusCode == 200) {
            final sink = localFile.openWrite();
            await response.stream.pipe(sink);
            await sink.flush();
            await sink.close();

            final fileLen = await localFile.length();
            totalSize += fileLen;
          } else {
            throw Exception('Gagal mengunduh hal $pageNum (HTTP ${response.statusCode})');
          }

          completedCount++;
          final progress = completedCount / totalPages;
          _progressController.add(DownloadProgress(
            chapterUrl: chapterUrl,
            progress: progress,
            downloadedPages: completedCount,
            totalPages: totalPages,
          ));
        }
      }

      final workers = List.generate(
        maxConcurrency < totalPages ? maxConcurrency : totalPages,
        (_) => worker(),
      );

      await Future.wait(workers);

      if (_cancelledUrls.contains(chapterUrl)) {
        // Bersihkan file jika dibatalkan
        if (await targetDir.exists()) {
          await targetDir.delete(recursive: true);
        }
        throw Exception('Unduhan dibatalkan');
      }

      // 4. Simpan metadata ke SQLite
      final downloadedChapter = DownloadedChapterModel(
        id: '${task.comicId}_${task.chapterUrl.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => 'chap')}',
        comicId: task.comicId,
        comicTitle: task.comicTitle,
        comicThumbUrl: task.comicThumbUrl,
        chapterTitle: task.chapterTitle,
        chapterUrl: task.chapterUrl,
        localPath: targetDir.path,
        pageCount: completedCount,
        sizeBytes: totalSize,
        downloadedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _databaseHelper.saveDownloadedChapter(downloadedChapter);

      _progressController.add(DownloadProgress(
        chapterUrl: chapterUrl,
        progress: 1.0,
        downloadedPages: completedCount,
        totalPages: totalPages,
        isCompleted: true,
      ));
    } catch (e) {
      debugPrint('[DownloadService] ❌ Gagal unduh chapter: $e');
      _progressController.add(DownloadProgress(
        chapterUrl: chapterUrl,
        progress: 0.0,
        downloadedPages: 0,
        totalPages: 0,
        isFailed: true,
        errorMessage: e.toString(),
      ));
    } finally {
      _activeDownloads.remove(chapterUrl);
      _cancelledUrls.remove(chapterUrl);
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<void> deleteDownloadedChapter(String chapterUrl) async {
    final chapter = await _databaseHelper.getDownloadedChapterByUrl(chapterUrl);
    if (chapter != null) {
      final dir = Directory(chapter.localPath);
      if (await dir.exists()) {
        try {
          await dir.delete(recursive: true);
        } catch (e) {
          debugPrint('[DownloadService] Warning deleting directory: $e');
        }
      }
      await _databaseHelper.deleteDownloadedChapter(chapterUrl);
    }
  }

  Future<void> deleteDownloadedChaptersByComic(String comicId) async {
    final chapters = await _databaseHelper.getDownloadedChaptersByComic(comicId);
    for (var c in chapters) {
      final dir = Directory(c.localPath);
      if (await dir.exists()) {
        try {
          await dir.delete(recursive: true);
        } catch (e) {
          debugPrint('[DownloadService] Warning deleting directory: $e');
        }
      }
    }
    await _databaseHelper.deleteDownloadedChaptersByComic(comicId);
  }

  Future<void> clearAllDownloads() async {
    final downloadsDir = await getDownloadsDirectory();
    if (await downloadsDir.exists()) {
      try {
        await downloadsDir.delete(recursive: true);
      } catch (e) {
        debugPrint('[DownloadService] Warning deleting downloads directory: $e');
      }
    }
    await _databaseHelper.clearAllDownloadedChapters();
  }

  Future<int> getTotalDownloadsSizeBytes() async {
    final downloadsDir = await getDownloadsDirectory();
    if (!await downloadsDir.exists()) return 0;
    int totalBytes = 0;
    try {
      final entities = downloadsDir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          totalBytes += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('[DownloadService] Error counting total bytes: $e');
    }
    return totalBytes;
  }

  Future<List<String>> getLocalChapterImagePaths(String localPath) async {
    final dir = Directory(localPath);
    if (!await dir.exists()) return [];

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.webp') || f.path.endsWith('.png'))
        .toList();

    files.sort((a, b) => a.path.compareTo(b.path));
    return files.map((f) => f.path).toList();
  }
}
