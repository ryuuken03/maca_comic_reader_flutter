import 'package:flutter/material.dart';
import '../../data/models/comic_model.dart';
import '../../data/models/detail_comic_model.dart';
import '../../data/services/scraper_service.dart';
import '../../core/database/database_helper.dart';

class ComicProvider with ChangeNotifier {
  final ScraperService _scraperService = ScraperService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  List<ComicModel> _homeComics = [];
  List<ComicModel> get homeComics => _homeComics;

  List<ComicModel> _popularComics = [];
  List<ComicModel> get popularComics => _popularComics;

  List<ComicModel> _projectComics = [];
  List<ComicModel> get projectComics => _projectComics;

  List<ComicModel> _bookmarks = [];
  List<ComicModel> get bookmarks => _bookmarks;

  List<ComicModel> _history = [];
  List<ComicModel> get history => _history;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DetailComicModel? _detailComic;
  DetailComicModel? get detailComic => _detailComic;

  List<String> _readerImages = [];
  List<String> get readerImages => _readerImages;

  String _readerComicTitle = '';
  String get readerComicTitle => _readerComicTitle;

  String _readerComicLink = '';
  String get readerComicLink => _readerComicLink;

  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isFetchingMore = false;

  bool get hasNextPage => _hasNextPage;
  bool get isFetchingMore => _isFetchingMore;

  Future<void> fetchHomeComics() async {
    _isLoading = true;
    _currentPage = 1;
    _hasNextPage = true;
    notifyListeners();
    try {
      final futures = await Future.wait([
        _scraperService.fetchSeries(preset: 'popular_all', take: 10, includeMeta : true),
        _scraperService.fetchSeries(preset: 'rilisan_terbaru',type: 'project', take: 20),
        _scraperService.fetchSeries(preset: 'rilisan_terbaru', take: 20, page: _currentPage),
      ]);
      _popularComics = futures[0] as List<ComicModel>;
      _projectComics = futures[1] as List<ComicModel>;
      _homeComics = futures[2] as List<ComicModel>;
      
      if (_homeComics.isEmpty) {
        _hasNextPage = false;
      }
    } catch (e) {
      debugPrint('Error fetchHomeComics: ${e.toString()}');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDetailComic(String url) async {
    _isLoading = true;
    _detailComic = null;
    notifyListeners();
    try {
      _detailComic = await _scraperService.getDetailComic(url);
    } catch (e) {
      debugPrint('Error fetchDetailComic: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchReaderImages(String chapterUrl) async {
    _isLoading = true;
    _readerImages = [];
    _readerComicTitle = '';
    _readerComicLink = '';
    notifyListeners();
    try {
      final readerData = await _scraperService.getReaderDataBE(chapterUrl);
      _readerImages = readerData.images;
      _readerComicTitle = readerData.title;
      _readerComicLink = readerData.seriesLink;

      if (_detailComic == null || _detailComic!.comic.link != readerData.seriesLink) {
         try {
           _detailComic = await _scraperService.getDetailComic(readerData.seriesLink);
         } catch (e) {
           debugPrint('Silently failed fetching detail for reader: $e');
         }
      }

      if (_detailComic != null) {
         final comic = _detailComic!.comic;
         final historyComic = ComicModel(
             title: comic.title,
             thumbUrl: comic.thumbUrl,
             link: comic.link,
             latestChapter: chapterUrl.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => ''),
             chapterLink: chapterUrl,
             type: _detailComic!.type,
             status: _detailComic!.status,
             format: _detailComic!.format,
         );
         await DatabaseHelper.instance.saveHistory(historyComic);
         fetchHistory(); // sync history real-time
      }
    } catch (e) {
      debugPrint('Error fetchReaderImages: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBookmarks() async {
    _bookmarks = await _databaseHelper.getBookmarks();
    notifyListeners();
  }

  Future<void> fetchHistory() async {
    _history = await _databaseHelper.getHistory();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _databaseHelper.clearHistory();
    await fetchHistory();
  }

  Future<void> clearBookmarks() async {
    await _databaseHelper.clearBookmarks();
    await fetchBookmarks();
  }

  Future<void> toggleBookmark(ComicModel comic) async {
    bool isBookmarked = await _databaseHelper.isBookmarked(comic.link);
    if (isBookmarked) {
      await _databaseHelper.removeBookmark(comic.link);
    } else {
      await _databaseHelper.saveBookmark(comic);
    }
    await fetchBookmarks();
  }

  Future<void> toggleBookmarkReader(ComicModel comic) async {
    bool isBookmarked = await _databaseHelper.isBookmarked(comic.link);
    bool isBookmarkedReader = await _databaseHelper.isBookmarkedReader(comic.latestChapter!);
    if (isBookmarked) {
      await _databaseHelper.removeBookmark(comic.link);
      if(!isBookmarkedReader){
        await _databaseHelper.saveBookmark(comic);
      }
    } else {
      await _databaseHelper.saveBookmark(comic);
    }
    await fetchBookmarks();
  }

  Future<bool> isBookmarked(String link) async {
    return await _databaseHelper.isBookmarked(link);
  }

  Future<bool> isBookmarkedReader(String index) async {
    return await _databaseHelper.isBookmarkedReader(index);
  }
}
