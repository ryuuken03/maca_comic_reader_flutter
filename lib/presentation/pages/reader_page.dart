import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/comic_model.dart';
import '../providers/reader_provider.dart';
import '../providers/library_provider.dart';

class ReaderPage extends StatefulWidget {
  final String chapterUrl;
  final bool fromDetail;

  const ReaderPage({Key? key, required this.chapterUrl, this.fromDetail = false}) : super(key: key);

  @override
  _ReaderPageState createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  Timer? _loadingTimer;
  bool _isTimeout = false;
  late ReaderProvider _readerProvider;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _readerProvider = context.read<ReaderProvider>();
    _readerProvider.addListener(_onProviderChanged);
    _startLoad();
  }

  @override
  void dispose() {
    _readerProvider.removeListener(_onProviderChanged);
    _loadingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startLoad() {
    setState(() {
      _isTimeout = false;
    });
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _readerProvider.isLoading) {
        setState(() {
          _isTimeout = true;
        });
      }
    });
    _readerProvider.fetchReaderImages(widget.chapterUrl);
  }

  void _onProviderChanged() {
    if (!_readerProvider.isLoading) {
      _loadingTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final actIndexStr = widget.chapterUrl.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Chapter $actIndexStr'),
        actions: [
          Consumer2<ReaderProvider, LibraryProvider>(
            builder: (context, readerProvider, libraryProvider, child) {
              if (readerProvider.readerComicLink.isEmpty || readerProvider.detailComic == null) return const SizedBox.shrink();

              return FutureBuilder<bool>(
                future: libraryProvider.isBookmarkedReader(readerProvider.readerComicLink, actIndexStr),
                builder: (context, snapshot) {
                  bool isBookmarked = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? Colors.yellow : null,
                    ),
                    onPressed: () {
                      final detail = readerProvider.detailComic!;
                      final bookmarkModel = ComicModel(
                        title: detail.comic.title,
                        thumbUrl: detail.comic.thumbUrl,
                        link: detail.comic.link,
                        latestChapter: actIndexStr, 
                        chapterLink: widget.chapterUrl,
                        type: detail.type,
                        status: detail.status,
                        format: detail.format,
                      );
                      libraryProvider.toggleChapterBookmark(bookmarkModel);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ReaderProvider>(
        builder: (context, provider, child) {
          if (_isTimeout) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.signal_cellular_connected_no_internet_4_bar_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Jaringan Lambat / Stuck',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pemuatan halaman melebihi 10 detik.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _startLoad,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD644),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.readerImages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Gagal memuat chapter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tidak ada gambar ditemukan atau terjadi kesalahan.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _startLoad,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD644),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return Scrollbar(
            controller: _scrollController,
            interactive: true,
            thickness: 6.0,
            radius: const Radius.circular(3.0),
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              itemCount: provider.readerImages.length,
              itemBuilder: (context, index) {
                return _RetryableImage(imageUrl: provider.readerImages[index]);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<ReaderProvider>(
        builder: (context, provider, child) {
          String? nextChapterUrl;
          String? prevChapterUrl;

          if (provider.detailComic != null) {
            final chapters = provider.detailComic!.chapters;
            final currentIndex = chapters.indexWhere((c) => c.link == widget.chapterUrl);
            if (currentIndex != -1) {
              if (currentIndex > 0) {
                nextChapterUrl = chapters[currentIndex - 1].link;
              }
              if (currentIndex < chapters.length - 1) {
                prevChapterUrl = chapters[currentIndex + 1].link;
              }
            }
          }

          return BottomAppBar(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: prevChapterUrl != null
                      ? () {
                          context.pushReplacement('/reader', extra: {
                            'chapterUrl': prevChapterUrl,
                            'fromDetail': widget.fromDetail,
                          });
                        }
                      : null,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (widget.fromDetail && context.canPop()) {
                        context.pop();
                      } else if (provider.readerComicLink.isNotEmpty) {
                        context.pushReplacement('/detail', extra: provider.readerComicLink);
                      }
                    },
                    child: Text(
                      provider.readerComicTitle.isNotEmpty ? provider.readerComicTitle : 'Memuat...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: nextChapterUrl != null
                      ? () {
                          context.pushReplacement('/reader', extra: {
                            'chapterUrl': nextChapterUrl,
                            'fromDetail': widget.fromDetail,
                          });
                        }
                      : null,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RetryableImage extends StatefulWidget {
  final String imageUrl;
  const _RetryableImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  __RetryableImageState createState() => __RetryableImageState();
}

class __RetryableImageState extends State<_RetryableImage> {
  int _retryKey = 0;
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _retryKey++;
    });
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final m = Matrix4.identity();
      m.setEntry(0, 0, 2.5);
      m.setEntry(1, 1, 2.5);
      m.setEntry(0, 3, -position.dx * 1.5);
      m.setEntry(1, 3, -position.dy * 1.5);
      _transformationController.value = m;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey('${widget.imageUrl}_$_retryKey'),
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 1.0,
        maxScale: 4.0,
        child: GestureDetector(
          onDoubleTapDown: (details) {
            _doubleTapDetails = details;
          },
          onDoubleTap: _handleDoubleTap,
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            httpHeaders: const {
              'Referer': 'https://komikcast.cc/',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.9',
            },
            fit: BoxFit.fitWidth,
            width: double.infinity,
            placeholder: (context, url) => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) {
              return Container(
                height: 250,
                color: const Color(0xFF1E1E1E),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'Gagal memuat halaman gambar ini',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD644),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
