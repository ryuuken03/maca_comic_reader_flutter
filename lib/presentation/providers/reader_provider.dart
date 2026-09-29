import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/api_cache_manager.dart';
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

  Future<void> fetchReaderImages(
    String chapterUrl, {
    String? comicTitle,
    String? comicLink,
    String? comicThumb,
    DetailComicModel? detailComic,
  }) async {
    // 1. Dapatkan series slug dan link dari chapterUrl secara cepat
    String seriesSlug = '';
    if (chapterUrl.contains('/series/')) {
      final parts = chapterUrl.split('/series/').last.split('/');
      if (parts.isNotEmpty) {
        seriesSlug = parts.first;
      }
    } else if (chapterUrl.contains('/chapter/')) {
      final seg = chapterUrl.split('/chapter/').last.split('?').first.replaceAll('/', '');
      if (seg.contains('-chapter-')) {
        seriesSlug = seg.split('-chapter-').first;
      }
    }

    final seriesLink = (comicLink != null && comicLink.isNotEmpty)
        ? comicLink
        : (seriesSlug.isNotEmpty ? '${AppConstants.baseUrl}/series/$seriesSlug' : chapterUrl);

    // Ambil detail comic dari parameter atau cache jika sudah ada
    DetailComicModel? cachedDetail = detailComic;
    if (cachedDetail == null && seriesSlug.isNotEmpty) {
      cachedDetail = ApiCacheManager.instance.get<DetailComicModel>('detail_slug_$seriesSlug') ??
          ApiCacheManager.instance.get<DetailComicModel>('detail_$seriesLink');
    }

    _isLoading = true;
    _readerImages = [];
    _isOffline = false;
    _offlineChapters = [];
    _detailComic = cachedDetail;

    if (cachedDetail != null) {
      _readerComicTitle = cachedDetail.comic.title;
      _readerComicLink = cachedDetail.comic.link;
      _readerComicThumb = cachedDetail.comic.thumbUrl;
    } else {
      _readerComicTitle = (comicTitle != null && comicTitle.isNotEmpty)
          ? comicTitle
          : (seriesSlug.isNotEmpty
              ? seriesSlug.split('-').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ')
              : '');
      _readerComicLink = seriesLink;
      _readerComicThumb = comicThumb ?? '';
    }

    final actIndexStr = chapterUrl.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');
    final matchingInitial = _detailComic?.chapters.where((c) => c.link == chapterUrl).firstOrNull;
    _readerChapterTitle = matchingInitial?.title ?? (actIndexStr.isNotEmpty ? 'Chapter $actIndexStr' : '');

    notifyListeners();

    try {
      // 2. Cek apakah chapter tersedia secara offline di database lokal
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

      // 3. Mode Online: Request reader images & detail komik
      final readerFuture = _repository.getReaderData(chapterUrl);
      final detailFuture = (_detailComic == null && seriesSlug.isNotEmpty)
          ? _repository.getDetailComic(seriesLink)
          : null;

      try {
        final readerData = await readerFuture;
        _readerImages = readerData.images;
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        debugPrint('Error getReaderData: $e');
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (detailFuture != null) {
        try {
          final fetchedDetail = await detailFuture;
          _detailComic = fetchedDetail;
          _readerComicTitle = fetchedDetail.comic.title;
          _readerComicLink = fetchedDetail.comic.link;
          _readerComicThumb = fetchedDetail.comic.thumbUrl;
          notifyListeners();
        } catch (e) {
          debugPrint('Warning: getDetailComic in reader: $e');
        }
      }

      // Ambil judul chapter yang rapi dari daftar chapter
      final matchingChapter = _detailComic?.chapters.where((c) => c.link == chapterUrl).firstOrNull;
      final finalChapterTitle = matchingChapter?.title ??
          (actIndexStr.isNotEmpty ? 'Chapter $actIndexStr' : _readerChapterTitle);
      _readerChapterTitle = finalChapterTitle;

      final finalLink = _readerComicLink.isNotEmpty ? _readerComicLink : seriesLink;
      final finalTitle = _readerComicTitle.isNotEmpty ? _readerComicTitle : (seriesSlug.isNotEmpty ? seriesSlug : 'Komik');

      if (finalLink.isNotEmpty) {
        await _repository.saveHistory(ComicModel(
          title: finalTitle,
          thumbUrl: _readerComicThumb,
          link: finalLink,
          latestChapter: finalChapterTitle,
          chapterLink: chapterUrl,
          type: _detailComic?.type ?? '',
          status: _detailComic?.status ?? '',
          format: _detailComic?.format ?? '',
          isPinned: _detailComic?.isPinned ?? false,
          isHot: _detailComic?.isHot ?? false,
          isRecommended: _detailComic?.isRecommended ?? false,
        ));

        // Jika komik ini tersimpan di bookmark, perbarui posisi baca terakhir secara otomatis
        await _repository.updateBookmarkProgress(finalLink, finalChapterTitle, chapterUrl);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetchReaderImages: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
}
