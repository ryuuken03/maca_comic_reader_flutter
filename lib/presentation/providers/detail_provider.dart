import 'package:flutter/material.dart';
import '../../data/models/detail_comic_model.dart';
import '../../data/repositories/comic_repository.dart';

class DetailProvider with ChangeNotifier {
  final ComicRepository _repository = ComicRepository();

  DetailComicModel? _detailComic;
  DetailComicModel? get detailComic => _detailComic;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchDetail(String url) async {
    _isLoading = true;
    _detailComic = null;
    notifyListeners();
    try {
      _detailComic = await _repository.getDetailComic(url);
    } catch (e) {
      debugPrint('Error fetchDetail: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> isBookmarked(String link) => _repository.isBookmarked(link);
}
