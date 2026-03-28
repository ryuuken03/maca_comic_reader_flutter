import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/comic_model.dart';
import '../providers/comic_provider.dart';

class ReaderPage extends StatefulWidget {
  final String chapterUrl;

  const ReaderPage({Key? key, required this.chapterUrl}) : super(key: key);

  @override
  _ReaderPageState createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComicProvider>().fetchReaderImages(widget.chapterUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final actIndexStr = widget.chapterUrl.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Chapter $actIndexStr'),
        actions: [
          Consumer<ComicProvider>(
            builder: (context, provider, child) {
              if (provider.readerComicLink.isEmpty || provider.detailComic == null) return const SizedBox.shrink();

              return FutureBuilder<bool>(
                future: provider.isBookmarked(provider.readerComicLink),
                builder: (context, snapshot) {
                  bool isBookmarked = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? Colors.yellow : null,
                    ),
                    onPressed: () {
                      final detail = provider.detailComic!;
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
                      provider.toggleBookmark(bookmarkModel);
                      (context as Element).markNeedsBuild();
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<ComicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.readerImages.isEmpty) {
            return const Center(child: Text('Tidak ada gambar ditemukan'));
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: provider.readerImages.length,
            itemBuilder: (context, index) {
              return CachedNetworkImage(
                imageUrl: provider.readerImages[index],
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
                errorWidget: (context, url, error) => const Icon(Icons.error),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Consumer<ComicProvider>(
        builder: (context, provider, child) {
          String? nextChapterUrl;
          String? prevChapterUrl;

          if (provider.detailComic != null) {
            final chapters = provider.detailComic!.chapters;
            final currentIndex = chapters.indexWhere((c) => c.link == widget.chapterUrl);
            if (currentIndex != -1) {
              if (currentIndex > 0) {
                // Usually newer chapters are earlier in list, so index - 1 is the next chapter functionally
                nextChapterUrl = chapters[currentIndex - 1].link;
              }
              if (currentIndex < chapters.length - 1) {
                // Older chapters are later in the list, so index + 1 is the previous chapter functionally
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
                          context.pushReplacement('/reader', extra: prevChapterUrl);
                        }
                      : null,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (context.canPop()) {
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
                          context.pushReplacement('/reader', extra: nextChapterUrl);
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
