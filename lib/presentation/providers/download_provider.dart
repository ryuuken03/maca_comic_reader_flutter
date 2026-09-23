import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/downloaded_chapter_model.dart';
import '../../data/services/download_service.dart';

class DownloadProvider with ChangeNotifier {
  final DownloadService _service;
  final DatabaseHelper _databaseHelper;

  List<DownloadedChapterModel> _downloadedChapters = [];
  List<DownloadedChapterModel> get downloadedChapters => _downloadedChapters;

  final Set<String> _downloadedUrls = {};
  Set<String> get downloadedUrls => _downloadedUrls;

  final Map<String, double> _progressMap = {};
  Map<String, double> get progressMap => _progressMap;

  final Map<String, String> _statusMap = {}; // 'downloading', 'completed', 'failed'
  Map<String, String> get statusMap => _statusMap;

  int _totalDownloadsSizeBytes = 0;
  int get totalDownloadsSizeBytes => _totalDownloadsSizeBytes;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<DownloadProgress>? _progressSub;

  DownloadProvider({
    DownloadService? service,
    DatabaseHelper? db,
    bool autoLoad = true,
  })  : _service = service ?? DownloadService.instance,
        _databaseHelper = db ?? DatabaseHelper.instance {
    if (autoLoad) {
      _init();
    }
  }

  void _init() {
    _progressSub = _service.progressStream.listen((progress) {
      if (progress.isCompleted) {
        _progressMap.remove(progress.chapterUrl);
        _statusMap.remove(progress.chapterUrl);
        _downloadedUrls.add(progress.chapterUrl);
        loadDownloads();
      } else if (progress.isFailed) {
        _progressMap.remove(progress.chapterUrl);
        _statusMap[progress.chapterUrl] = 'failed';
        notifyListeners();
      } else {
        _progressMap[progress.chapterUrl] = progress.progress;
        _statusMap[progress.chapterUrl] = 'downloading';
        notifyListeners();
      }
    });

    loadDownloads();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  bool isChapterDownloaded(String chapterUrl) {
    return _downloadedUrls.contains(chapterUrl);
  }

  bool isChapterDownloading(String chapterUrl) {
    return _statusMap[chapterUrl] == 'downloading';
  }

  double getDownloadProgress(String chapterUrl) {
    return _progressMap[chapterUrl] ?? 0.0;
  }

  Future<void> loadDownloads() async {
    _isLoading = true;
    notifyListeners();

    try {
      _downloadedChapters = await _databaseHelper.getAllDownloadedChapters();
      _downloadedUrls.clear();
      for (final chap in _downloadedChapters) {
        _downloadedUrls.add(chap.chapterUrl);
      }
      _totalDownloadsSizeBytes = await _service.getTotalDownloadsSizeBytes();
    } catch (e) {
      debugPrint('[DownloadProvider] Error loading downloads: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> downloadChapter({
    required String comicId,
    required String comicTitle,
    String comicThumbUrl = '',
    required String chapterTitle,
    required String chapterUrl,
  }) async {
    final task = DownloadTask(
      comicId: comicId,
      comicTitle: comicTitle,
      comicThumbUrl: comicThumbUrl,
      chapterTitle: chapterTitle,
      chapterUrl: chapterUrl,
    );

    _statusMap[chapterUrl] = 'downloading';
    _progressMap[chapterUrl] = 0.0;
    notifyListeners();

    // Start asynchronously in background
    unawaited(_service.startDownload(task));
  }

  void cancelDownload(String chapterUrl) {
    _service.cancelDownload(chapterUrl);
    _progressMap.remove(chapterUrl);
    _statusMap.remove(chapterUrl);
    notifyListeners();
  }

  Future<void> deleteDownloadedChapter(String chapterUrl) async {
    await _service.deleteDownloadedChapter(chapterUrl);
    _downloadedUrls.remove(chapterUrl);
    _progressMap.remove(chapterUrl);
    _statusMap.remove(chapterUrl);
    await loadDownloads();
  }

  Future<void> deleteDownloadedChaptersByComic(String comicId) async {
    await _service.deleteDownloadedChaptersByComic(comicId);
    await loadDownloads();
  }

  Future<void> clearAllDownloads() async {
    await _service.clearAllDownloads();
    _downloadedUrls.clear();
    _progressMap.clear();
    _statusMap.clear();
    await loadDownloads();
  }
}
