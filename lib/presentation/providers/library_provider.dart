import 'package:flutter/material.dart';
import '../../data/models/comic_model.dart';
import '../../data/repositories/comic_repository.dart';

class LibraryProvider with ChangeNotifier {
  final ComicRepository _repository = ComicRepository();

  List<ComicModel> _bookmarks = [];
  List<ComicModel> get bookmarks => _bookmarks;

  List<ComicModel> _history = [];
  List<ComicModel> get history => _history;

  LibraryProvider({bool autoFetch = true}) {
    if (autoFetch) {
      fetchBookmarks();
      fetchHistory();
    }
  }

  Future<void> fetchBookmarks() async {
    _bookmarks = await _repository.getBookmarks();
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    _history = await _repository.getHistory();
    notifyListeners();
  }

  Future<void> saveHistory(ComicModel comic) async {
    await _repository.saveHistory(comic);
    await fetchHistory();
  }

  Future<void> removeHistory(String link) async {
    await _repository.removeHistory(link);
    await fetchHistory();
  }

  Future<void> clearHistory() async {
    await _repository.clearHistory();
    _history = [];
    notifyListeners();
  }

  static String extractComicSlug(String url) {
    if (url.isEmpty) return '';
    final clean = url.split('?').first.replaceAll(RegExp(r'/+$'), '');
    if (clean.contains('/series/')) {
      final after = clean.split('/series/').last;
      return after.split('/').firstWhere((s) => s.isNotEmpty, orElse: () => '');
    }
    if (clean.contains('/komik/')) {
      final after = clean.split('/komik/').last;
      return after.split('/').firstWhere((s) => s.isNotEmpty, orElse: () => '');
    }
    return clean.split('/').lastWhere((s) => s.isNotEmpty, orElse: () => clean);
  }

  static bool isSameComic(String? urlA, String? urlB) {
    if (urlA == null || urlB == null) return false;
    if (urlA.isEmpty || urlB.isEmpty) return false;
    if (urlA == urlB) return true;
    final cleanA = urlA.split('?').first.replaceAll(RegExp(r'/+$'), '');
    final cleanB = urlB.split('?').first.replaceAll(RegExp(r'/+$'), '');
    if (cleanA == cleanB) return true;
    final slugA = extractComicSlug(cleanA);
    final slugB = extractComicSlug(cleanB);
    return slugA.isNotEmpty && slugA == slugB;
  }

  bool isComicBookmarked(String link) {
    return _bookmarks.any((b) => isSameComic(b.link, link));
  }

  ComicModel? getBookmark(String link) {
    return _bookmarks.cast<ComicModel?>().firstWhere(
      (b) => isSameComic(b?.link, link),
      orElse: () => null,
    );
  }

  bool isChapterBookmarked(String comicLink, String chapterUrl) {
    final b = getBookmark(comicLink);
    if (b == null || b.chapterLink == null) return false;
    if (b.chapterLink == chapterUrl) return true;
    final bSlug = b.chapterLink!.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');
    final cSlug = chapterUrl.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');
    return bSlug.isNotEmpty && bSlug == cSlug;
  }

  Future<void> toggleBookmark(ComicModel comic) async {
    final existing = getBookmark(comic.link);
    if (existing != null) {
      await _repository.removeBookmark(existing.link);
      if (existing.link != comic.link) {
        await _repository.removeBookmark(comic.link);
      }
    } else {
      await _repository.saveBookmark(comic);
    }
    await fetchBookmarks();
  }

  Future<void> removeBookmark(String link) async {
    final existing = getBookmark(link);
    if (existing != null) {
      await _repository.removeBookmark(existing.link);
    }
    await _repository.removeBookmark(link);
    await fetchBookmarks();
  }

  Future<void> clearBookmarks() async {
    await _repository.clearBookmarks();
    _bookmarks = [];
    notifyListeners();
  }

  Future<void> toggleChapterBookmark(ComicModel comic) async {
    final existing = getBookmark(comic.link);
    if (existing != null && existing.chapterLink == comic.chapterLink) {
      await removeBookmark(existing.link);
    } else {
      await _repository.saveBookmark(comic);
      await fetchBookmarks();
    }
  }

  Future<void> updateBookmarkProgress(String link, String chapterTitle, String chapterLink) async {
    final existing = getBookmark(link);
    if (existing != null) {
      await _repository.updateBookmarkProgress(existing.link, chapterTitle, chapterLink);
      if (existing.link != link) {
        await _repository.updateBookmarkProgress(link, chapterTitle, chapterLink);
      }
      await fetchBookmarks();
    }
  }

  Future<bool> isBookmarked(String link) => _repository.isBookmarked(link);
  Future<bool> isBookmarkedReader(String link, String index) => _repository.isBookmarkedReader(link, index);
}
