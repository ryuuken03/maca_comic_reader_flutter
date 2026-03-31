import 'package:flutter/material.dart';
import '../../data/models/comic_model.dart';
import '../../data/models/genre_model.dart';
import '../../data/repositories/comic_repository.dart';

class HomeProvider with ChangeNotifier {
  final ComicRepository _repository = ComicRepository();

  List<ComicModel> _homeComics = [];
  List<ComicModel> get homeComics => _homeComics;

  List<ComicModel> _popularComics = [];
  List<ComicModel> get popularComics => _popularComics;

  List<ComicModel> _projectComics = [];
  List<ComicModel> get projectComics => _projectComics;

  List<GenreModel> _genres = [];
  List<GenreModel> get genres => _genres;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchHomeData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final futures = await Future.wait([
        _repository.getPopularComics(),
        _repository.getProjectComics(),
        _repository.fetchSeries(preset: 'rilisan_terbaru', page: 1),
      ]);
      _popularComics = futures[0];
      _projectComics = futures[1];
      _homeComics = futures[2];
    } catch (e) {
      debugPrint('Error fetchHomeData: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchGenres() async {
    if (_genres.isNotEmpty) return;
    try {
      _genres = await _repository.getGenres();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchGenres: $e');
    }
  }

  // DISCOVER / SEARCH
  List<ComicModel> _discoverComics = [];
  List<ComicModel> get discoverComics => _discoverComics;

  bool _hasNextPage = true;
  bool get hasNextPage => _hasNextPage;

  Future<void> fetchDiscover({
    String? searchQuery,
    String? preset,
    String? type,
    List<String>? genres,
    int page = 1,
  }) async {
    _isLoading = true;
    if (page == 1) {
      _discoverComics = [];
      _hasNextPage = true;
    }
    notifyListeners();
    try {
      final result = await _repository.fetchSeries(
        searchQuery: searchQuery,
        preset: preset,
        type: type,
        page: page,
      );
      if (result.isEmpty) {
        _hasNextPage = false;
      } else {
        if (page == 1) {
          _discoverComics = result;
        } else {
          _discoverComics.addAll(result);
        }
      }
    } catch (e) {
      debugPrint('Error fetchDiscover: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}
