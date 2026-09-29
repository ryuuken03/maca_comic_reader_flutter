import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/database/database_helper.dart';
import '../../data/models/comic_model.dart';
import '../../data/models/detail_comic_model.dart';
import '../../data/models/downloaded_chapter_model.dart';
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

  String _readerChapterTitle = '';
  String get readerChapterTitle => _readerChapterTitle;

  String _readerComicThumb = '';
  String get readerComicThumb => _readerComicThumb;

  DetailComicModel? _detailComic;
  DetailComicModel? get detailComic => _detailComic;

  List<DownloadedChapterModel> _offlineChapters = [];
  List<DownloadedChapterModel> get offlineChapters => _offlineChapters;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isOffline = false;
  bool get isOffline => _isOffline;

  Future<void> fetchReaderImages(String chapterUrl) async {
    _isLoading = true;
    _readerImages = [];
    _readerComicTitle = '';
    _readerComicLink = '';
    _readerChapterTitle = '';
    _readerComicThumb = '';
    _detailComic = null;
    _offlineChapters = [];
    _isOffline = false;
    notifyListeners();

    try {
      // 1. Cek apakah chapter tersedia secara offline di database lokal
      final downloaded = await DatabaseHelper.instance.getDownloadedChapterByUrl(chapterUrl);
      if (downloaded != null) {
        final localImages = await DownloadService.instance.getLocalChapterImagePaths(
          downloaded.localPath,
          comicId: downloaded.comicId,
          chapterUrl: downloaded.chapterUrl,
        );
        if (localImages.isNotEmpty) {
          _isOffline = true;
          _readerImages = localImages;
          _readerComicTitle = downloaded.comicTitle;
          _readerChapterTitle = downloaded.chapterTitle;
          _readerComicThumb = downloaded.comicThumbUrl;
          _readerComicLink = downloaded.comicId.isNotEmpty
              ? '${AppConstants.baseUrl}/series/${downloaded.comicId}'
              : (chapterUrl.contains('/series/')
                  ? '${AppConstants.baseUrl}/series/${chapterUrl.split('/series/').last.split('/').first}'
                  : chapterUrl);

          if (downloaded.comicId.isNotEmpty) {
            _offlineChapters = await DatabaseHelper.instance.getDownloadedChaptersByComic(downloaded.comicId);
          }

          _isLoading = false;
          notifyListeners();

          // Simpan riwayat membaca offline dengan judul chapter yang rapi
          if (_readerComicLink.isNotEmpty) {
            await _repository.saveHistory(ComicModel(
              title: downloaded.comicTitle,
              thumbUrl: downloaded.comicThumbUrl,
              link: _readerComicLink,
              latestChapter: downloaded.chapterTitle,
              chapterLink: chapterUrl,
            ));

            // Jika komik ini tersimpan di bookmark, perbarui posisi baca terakhir
            await _repository.updateBookmarkProgress(_readerComicLink, downloaded.chapterTitle, chapterUrl);
          }

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
      _readerComicThumb = detailComic.comic.thumbUrl;

      // Ambil judul chapter yang rapi dari daftar chapter
      final matchingChapter = detailComic.chapters.where((c) => c.link == chapterUrl).firstOrNull;
      final actIndexStr = chapterUrl.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');
      final chapterTitle = matchingChapter?.title ?? actIndexStr;
      _readerChapterTitle = chapterTitle;

      await _repository.saveHistory(ComicModel(
        title: detailComic.comic.title,
        thumbUrl: detailComic.comic.thumbUrl,
        link: detailComic.comic.link,
        latestChapter: chapterTitle,
        chapterLink: chapterUrl,
        type: detailComic.type,
        status: detailComic.status,
        format: detailComic.format,
        isPinned: detailComic.isPinned,
        isHot: detailComic.isHot,
        isRecommended: detailComic.isRecommended,
      ));

      // Jika komik ini tersimpan di bookmark, perbarui posisi baca terakhir secara otomatis
      await _repository.updateBookmarkProgress(detailComic.comic.link, chapterTitle, chapterUrl);

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchReaderImages: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
}
