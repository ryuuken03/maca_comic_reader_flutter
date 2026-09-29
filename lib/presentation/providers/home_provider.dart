import 'dart:math';
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

  Future<void> fetchHomeData({int take = 20}) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Muat konten utama (rilisan terbaru) terlebih dahulu agar langsung tampil ke user
      _homeComics = await _repository.fetchSeries(preset: 'rilisan_terbaru', page: 1, take: take);
      _isLoading = false;
      notifyListeners();

      // Jeda jitter manusiawi (180ms - 320ms) untuk mencegah lonjakan request WAF/Cloudflare
      await Future.delayed(Duration(milliseconds: 180 + Random().nextInt(140)));

      // 2. Muat komik populer secara bertahap
      _popularComics = await _repository.getPopularComics();
      notifyListeners();

      // Jeda jitter kedua
      await Future.delayed(Duration(milliseconds: 180 + Random().nextInt(140)));

      // 3. Muat komik proyek
      _projectComics = await _repository.getProjectComics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchHomeData: $e');
      _isLoading = false;
      notifyListeners();
    }
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
    int take = 20,
  }) async {
    _isLoading = true;
    if (page == 1) {
      _discoverComics = [];
      _hasNextPage = true;
    }
    notifyListeners();
    try {
      if(preset == "rilisan_terbaru"){
        final result = await _repository.fetchSeriesSort(
          searchQuery: searchQuery,
          sort: "latest",
          sortOrder: "desc",
          type: type,
          genres: genres,
          page: page,
          take: take,
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
      }else{
        final result = await _repository.fetchSeries(
          searchQuery: searchQuery,
          preset: preset,
          type: type,
          genres: genres,
          page: page,
          take: take,
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
      }
    } catch (e) {
      debugPrint('Error fetchDiscover: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}
