import 'package:flutter/material.dart';
import '../../data/models/comic_model.dart';
import '../../data/models/detail_comic_model.dart';
import '../../data/repositories/comic_repository.dart';

class ReaderProvider with ChangeNotifier {
  final ComicRepository _repository = ComicRepository();

  List<String> _readerImages = [];
  List<String> get readerImages => _readerImages;

  String _readerComicTitle = '';
  String get readerComicTitle => _readerComicTitle;

  String _readerComicLink = '';
  String get readerComicLink => _readerComicLink;

  DetailComicModel? _detailComic;
  DetailComicModel? get detailComic => _detailComic;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchReaderImages(String chapterUrl) async {
    _isLoading = true;
    _readerImages = [];
    _readerComicTitle = '';
    _readerComicLink = '';
    _detailComic = null;
    notifyListeners();
    try {
      final readerData = await _repository.getReaderData(chapterUrl);
      _readerImages = readerData.images;
      _readerComicTitle = readerData.title;
      _readerComicLink = readerData.seriesLink;

      // Fetch detail to support history saving with full metadata
      _detailComic = await _repository.getDetailComic(readerData.seriesLink);
    } catch (e) {
      debugPrint('Error fetchReaderImages: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}
