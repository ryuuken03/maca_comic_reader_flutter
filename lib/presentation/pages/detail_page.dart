import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/comic_model.dart';
import '../providers/comic_provider.dart';
import '../widgets/chapter_tile.dart';

class DetailPage extends StatefulWidget {
  final String comicUrl;

  const DetailPage({Key? key, required this.comicUrl}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isExpanded = false;
  String _searchChapterQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComicProvider>().fetchDetailComic(widget.comicUrl);
      context.read<ComicProvider>().fetchBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Komik'),
        actions: [
          Consumer<ComicProvider>(
            builder: (context, provider, child) {
              if (provider.detailComic == null) return const SizedBox.shrink();

              return FutureBuilder<bool>(
                future: provider.isBookmarked(widget.comicUrl),
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
                        latestChapter: null,
                        chapterLink: null,
                        type: detail.type,
                        status: detail.status,
                        format: detail.format,
                      );
                      provider.toggleBookmark(bookmarkModel);
                      // Memaksa state build ulang saat ikon di-tap
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
          if (provider.isLoading || provider.detailComic == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final detail = provider.detailComic!;
          final filteredChapters = detail.chapters.where((chap) {
             return chap.title.toLowerCase().contains(_searchChapterQuery.toLowerCase());
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120,
                        height: 160,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: detail.comic.thumbUrl.isNotEmpty
                                    ? detail.comic.thumbUrl
                                    : 'https://via.placeholder.com/150',
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                              if (detail.format.toLowerCase() == 'manga' || detail.format.toLowerCase() == 'manhwa' || detail.format.toLowerCase() == 'manhua')
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      detail.format.toLowerCase() == 'manga' ? '🇯🇵' :
                                      detail.format.toLowerCase() == 'manhwa' ? '🇰🇷' : '🇨🇳',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.comic.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: [
                                if (detail.status.isNotEmpty)
                                  Chip(
                                    label: Text(
                                      detail.status.toUpperCase(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                  ),
                                  if (detail.type.isNotEmpty)
                                    Chip(
                                      label: Text(
                                        detail.type.toUpperCase(),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: Colors.orange.withOpacity(0.1),
                                    ),
                                ],
                              ),
                              if (detail.genres.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Genre',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 4.0,
                                  runSpacing: 4.0,
                                  children: detail.genres.map((g) => Chip(
                                    label: Text(g, style: const TextStyle(fontSize: 10)),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  )).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       const Text(
                         'Sinopsis',
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(height: 8),
                       InkWell(
                         onTap: () {
                           setState(() {
                              _isExpanded = !_isExpanded;
                           });
                         },
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               detail.description,
                               maxLines: _isExpanded ? null : 4,
                               overflow: _isExpanded ? null : TextOverflow.ellipsis,
                             ),
                             const SizedBox(height: 4),
                             Text(
                               _isExpanded ? 'Lebih sedikit' : 'Selengkapnya',
                               style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                             ),
                           ],
                         ),
                       ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'List Chapter (${detail.chapters.length} chapter)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                           hintText: 'Cari chapter...',
                           prefixIcon: const Icon(Icons.search),
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(8.0),
                           ),
                           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        ),
                        onChanged: (val) {
                           setState(() {
                              _searchChapterQuery = val;
                           });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return ChapterTile(chapter: filteredChapters[index]);
                }, childCount: filteredChapters.length),
              ),
            ],
          );
        },
      ),
    );
  }
}
