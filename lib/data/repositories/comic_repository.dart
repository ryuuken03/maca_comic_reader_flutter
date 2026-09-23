import '../models/comic_model.dart';
import '../models/detail_comic_model.dart';
import '../models/genre_model.dart';
import '../services/scraper_service.dart';
import '../../core/database/database_helper.dart';

class ComicRepository {
  final ScraperService _scraperService = ScraperService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // HOME FEEDS
  Future<List<ComicModel>> getPopularComics() {
    return _scraperService.fetchSeries(preset: 'popular_all', take: 10);
  }

  Future<List<ComicModel>> getProjectComics() {
    return _scraperService.fetchSeries(preset: 'rilisan_terbaru', type: 'project', take: 10);
  }

  Future<List<ComicModel>> fetchSeries({
    String? searchQuery,
    String? preset,
    String? type,
    List<String>? genres,
    int page = 1,
    int take = 20,
  }) {
    return _scraperService.fetchSeries(
      searchQuery: searchQuery,
      preset: preset,
      type: type,
      genres: genres,
      page: page,
      take: take,
    );
  }
  Future<List<ComicModel>> fetchSeriesSort({
    String? searchQuery,
    String? preset,
    String? type,
    String? sort,
    String? sortOrder,
    List<String>? genres,
    int page = 1,
    int take = 20,
  }) {
    return _scraperService.fetchSeries(
      searchQuery: searchQuery,
      preset: preset,
      type: type,
      genres: genres,
      sort: sort,
      sortOrder: sortOrder,
      page: page,
      take: take,
    );
  }

  // DETAILS & GENRES
  Future<DetailComicModel> getDetailComic(String url, {bool forceRefresh = false}) {
    return _scraperService.getDetailComic(url, forceRefresh: forceRefresh);
  }

  Future<List<GenreModel>> getGenres({bool forceRefresh = false}) {
    return _scraperService.getGenres(forceRefresh: forceRefresh);
  }

  // READER
  Future<ReaderData> getReaderData(String chapterUrl, {bool forceRefresh = false}) {
    return _scraperService.getReaderDataBE(chapterUrl, forceRefresh: forceRefresh);
  }

  // DATABASE / LIBRARY
  Future<List<ComicModel>> getBookmarks() => _databaseHelper.getBookmarks();
  Future<List<ComicModel>> getHistory() => _databaseHelper.getHistory();
  
  Future<void> saveHistory(ComicModel comic) => _databaseHelper.saveHistory(comic);
  Future<void> removeHistory(String link) => _databaseHelper.removeHistory(link);
  Future<void> clearHistory() => _databaseHelper.clearHistory();

  Future<void> saveBookmark(ComicModel comic) => _databaseHelper.saveBookmark(comic);
  Future<void> removeBookmark(String link) => _databaseHelper.removeBookmark(link);
  Future<void> clearBookmarks() => _databaseHelper.clearBookmarks();

  Future<bool> isBookmarked(String link) => _databaseHelper.isBookmarked(link);
  Future<bool> isBookmarkedReader(String link, String index) => _databaseHelper.isBookmarkedReader(link, index);
}
