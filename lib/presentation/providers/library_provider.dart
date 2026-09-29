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

  bool isComicBookmarked(String link) {
    return _bookmarks.any((b) => b.link == link);
  }

  ComicModel? getBookmark(String link) {
    return _bookmarks.cast<ComicModel?>().firstWhere(
      (b) => b?.link == link,
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
    if (isComicBookmarked(comic.link)) {
      await _repository.removeBookmark(comic.link);
    } else {
      await _repository.saveBookmark(comic);
    }
    await fetchBookmarks();
  }

  Future<void> removeBookmark(String link) async {
    await _repository.removeBookmark(link);
    await fetchBookmarks();
  }

  Future<void> clearBookmarks() async {
    await _repository.clearBookmarks();
    _bookmarks = [];
    notifyListeners();
  }

  Future<void> toggleChapterBookmark(ComicModel comic) async {
    if (isComicBookmarked(comic.link)) {
      await _repository.removeBookmark(comic.link);
    } else {
      await _repository.saveBookmark(comic);
    }
    await fetchBookmarks();
  }

  Future<void> updateBookmarkProgress(String link, String chapterTitle, String chapterLink) async {
    if (isComicBookmarked(link)) {
      await _repository.updateBookmarkProgress(link, chapterTitle, chapterLink);
      await fetchBookmarks();
    }
  }

  Future<bool> isBookmarked(String link) => _repository.isBookmarked(link);
  Future<bool> isBookmarkedReader(String link, String index) => _repository.isBookmarkedReader(link, index);
}
