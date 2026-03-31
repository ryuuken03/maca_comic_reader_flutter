import 'package:flutter/material.dart';
import '../../data/models/comic_model.dart';
import '../../data/repositories/comic_repository.dart';

class LibraryProvider with ChangeNotifier {
  final ComicRepository _repository = ComicRepository();

  List<ComicModel> _bookmarks = [];
  List<ComicModel> get bookmarks => _bookmarks;

  List<ComicModel> _history = [];
  List<ComicModel> get history => _history;

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

  Future<void> toggleBookmark(ComicModel comic) async {
    final isBookmarked = await _repository.isBookmarked(comic.link);
    if (isBookmarked) {
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
    // Specialized logic from previous toggleBookmarkReader
    bool isBookmarked = await _repository.isBookmarked(comic.link);
    bool isBookmarkedReader = await _repository.isBookmarkedReader(comic.link, comic.latestChapter!);
    if (isBookmarked) {
      await _repository.removeBookmark(comic.link);
      if(!isBookmarkedReader){
        await _repository.saveBookmark(comic);
      }
    } else {
      await _repository.saveBookmark(comic);
    }
    await fetchBookmarks();
  }

  Future<bool> isBookmarked(String link) => _repository.isBookmarked(link);
  Future<bool> isBookmarkedReader(String link, String index) => _repository.isBookmarkedReader(link, index);
}
