import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/comic_model.dart';
import '../../data/models/detail_comic_model.dart';
import '../../data/repositories/comic_repository.dart';
import '../../data/services/download_service.dart';

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

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  Future<void> fetchReaderImages(String chapterUrl) async {
    _isLoading = true;
    _readerImages = [];
    _readerComicTitle = '';
    _readerComicLink = '';
    _detailComic = null;
    _isOffline = false;
    notifyListeners();

    try {
      // 1. Cek apakah chapter tersedia secara offline di database lokal
      final downloaded = await DatabaseHelper.instance.getDownloadedChapterByUrl(chapterUrl);
      if (downloaded != null) {
        final localImages = await DownloadService.instance.getLocalChapterImagePaths(downloaded.localPath);
        if (localImages.isNotEmpty) {
          _isOffline = true;
          _readerImages = localImages;
          _readerComicTitle = downloaded.comicTitle;
          _readerComicLink = downloaded.comicId.isNotEmpty
              ? '${AppConstants.baseUrl}/series/${downloaded.comicId}'
              : '';
          _isLoading = false;
          notifyListeners();

          // Simpan riwayat membaca offline
          final actIndexStr = chapterUrl.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');
          await _repository.saveHistory(ComicModel(
            title: downloaded.comicTitle,
            thumbUrl: downloaded.comicThumbUrl,
            link: _readerComicLink,
            latestChapter: actIndexStr,
            chapterLink: chapterUrl,
          ));

          // Coba muat metadata detail di background jika ada koneksi, abaikan jika offline
          try {
            if (_readerComicLink.isNotEmpty) {
              _detailComic = await _repository.getDetailComic(_readerComicLink);
              notifyListeners();
            }
          } catch (_) {}
          return;
        }
      }

      // 2. Mode Online: Dapatkan series slug dan link dari chapterUrl
      String seriesSlug = '';
      if (chapterUrl.contains('/series/')) {
        final parts = chapterUrl.split('/series/').last.split('/');
        if (parts.isNotEmpty) {
          seriesSlug = parts.first;
        }
      }
      final seriesLink = '${AppConstants.baseUrl}/series/$seriesSlug';

      // 3. Request paralel untuk reader images & detail komik
      final readerFuture = _repository.getReaderData(chapterUrl);
      final detailFuture = _repository.getDetailComic(seriesLink);

      final readerData = await readerFuture;
      _readerImages = readerData.images;
      _isLoading = false;
      notifyListeners();

      final detailComic = await detailFuture;
      _detailComic = detailComic;
      _readerComicTitle = detailComic.comic.title;
      _readerComicLink = detailComic.comic.link;

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
