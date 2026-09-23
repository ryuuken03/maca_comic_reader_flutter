import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/api_cache_manager.dart';
import '../../core/utils/cache_manager.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper? _db;

  String _readerMode = 'webtoon';
  String _mangaDirection = 'rtl';
  bool _isPortraitLocked = false;

  int _readerCacheBytes = 0;
  int _thumbCacheBytes = 0;
  bool _isCalculating = false;

  String get readerMode => _readerMode;
  String get mangaDirection => _mangaDirection;
  bool get isPortraitLocked => _isPortraitLocked;

  int get readerCacheBytes => _readerCacheBytes;
  int get thumbCacheBytes => _thumbCacheBytes;
  int get totalCacheBytes => _readerCacheBytes + _thumbCacheBytes;
  bool get isCalculating => _isCalculating;

  SettingsProvider({DatabaseHelper? db, bool autoLoad = true}) : _db = db {
    if (autoLoad) {
      loadSettings();
    }
  }

  Future<void> loadSettings() async {
    try {
      final db = _db ?? DatabaseHelper.instance;
      final mode = await db.getSetting('reader_mode');
      final direction = await db.getSetting('reader_direction');
      final orientation = await db.getSetting('reader_orientation_lock');

      if (mode != null) _readerMode = mode;
      if (direction != null) _mangaDirection = direction;
      if (orientation != null) _isPortraitLocked = (orientation == 'portrait');

      notifyListeners();
      await refreshCacheSize();
    } catch (_) {}
  }

  Future<void> setReaderMode(String mode) async {
    _readerMode = mode;
    notifyListeners();
    try {
      final db = _db ?? DatabaseHelper.instance;
      await db.setSetting('reader_mode', mode);
    } catch (_) {}
  }

  Future<void> setMangaDirection(String direction) async {
    _mangaDirection = direction;
    notifyListeners();
    try {
      final db = _db ?? DatabaseHelper.instance;
      await db.setSetting('reader_direction', direction);
    } catch (_) {}
  }

  Future<void> setPortraitLock(bool lock) async {
    _isPortraitLocked = lock;
    notifyListeners();
    try {
      final db = _db ?? DatabaseHelper.instance;
      await db.setSetting('reader_orientation_lock', lock ? 'portrait' : 'auto');
    } catch (_) {}
  }

  Future<void> refreshCacheSize() async {
    _isCalculating = true;
    notifyListeners();

    try {
      _readerCacheBytes = await StorageHelper.getReaderCacheSizeBytes();
      _thumbCacheBytes = await StorageHelper.getThumbnailCacheSizeBytes();
    } catch (_) {
      _readerCacheBytes = 0;
      _thumbCacheBytes = 0;
    } finally {
      _isCalculating = false;
      notifyListeners();
    }
  }

  Future<void> clearThumbnailCache() async {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await StorageHelper.clearThumbnailCacheOnDisk();
    } catch (_) {}
    await refreshCacheSize();
  }

  Future<void> clearReaderCache() async {
    try {
      await StorageHelper.clearReaderCacheOnDisk();
    } catch (_) {}
    await refreshCacheSize();
  }

  Future<void> clearAllCache() async {
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      ApiCacheManager.instance.clear();
      await StorageHelper.clearThumbnailCacheOnDisk();
      await StorageHelper.clearReaderCacheOnDisk();
    } catch (_) {}
    await refreshCacheSize();
  }
}
