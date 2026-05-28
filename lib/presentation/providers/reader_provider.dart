import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
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
      // 1. Get series slug and link synchronously from chapterUrl
      String seriesSlug = '';
      if (chapterUrl.contains('/series/')) {
        final parts = chapterUrl.split('/series/').last.split('/');
        if (parts.isNotEmpty) {
          seriesSlug = parts.first;
        }
      }
      final seriesLink = '${AppConstants.baseUrl}/komik/$seriesSlug';

      // 2. Start both requests in parallel
      final readerFuture = _repository.getReaderData(chapterUrl);
      final detailFuture = _repository.getDetailComic(seriesLink);

      // 3. Await images first for instant loading
      final readerData = await readerFuture;
      _readerImages = readerData.images;
      _isLoading = false;
      notifyListeners();

      // 4. Await detail in the background
      final detailComic = await detailFuture;
      _detailComic = detailComic;
      _readerComicTitle = detailComic.comic.title;
      _readerComicLink = detailComic.comic.link;

      // Save history directly to local database
      final actIndexStr = chapterUrl.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');
      await _repository.saveHistory(ComicModel(
        title: detailComic.comic.title,
        thumbUrl: detailComic.comic.thumbUrl,
        link: detailComic.comic.link,
        latestChapter: actIndexStr,
        chapterLink: chapterUrl,
        type: detailComic.type,
        status: detailComic.status,
        format: detailComic.format,
      ));

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchReaderImages: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
}
