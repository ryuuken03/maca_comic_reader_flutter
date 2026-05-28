import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/comic_model.dart';
import '../../data/models/chapter_model.dart';
import '../providers/detail_provider.dart';
import '../providers/library_provider.dart';
import '../widgets/chapter_tile.dart';
import '../widgets/genre_chip.dart';
import '../widgets/search_input.dart';
import '../widgets/shimmer.dart';

class DetailPage extends StatefulWidget {
  final String comicUrl;

  const DetailPage({Key? key, required this.comicUrl}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isExpanded = false;
  String _searchChapterQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;
  bool _showBackToTop = false;
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 600) {
        if (!_showBackToTop) {
          setState(() {
            _showBackToTop = true;
          });
        }
      } else {
        if (_showBackToTop) {
          setState(() {
            _showBackToTop = false;
          });
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetailProvider>().fetchDetail(widget.comicUrl);
      context.read<LibraryProvider>().fetchBookmarks();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Komik'),
        actions: [
          Consumer2<DetailProvider, LibraryProvider>(
            builder: (context, detailProvider, libraryProvider, child) {
              if (detailProvider.detailComic == null) return const SizedBox.shrink();

              return FutureBuilder<bool>(
                future: libraryProvider.isBookmarked(widget.comicUrl),
                builder: (context, snapshot) {
                  bool isBookmarked = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? const Color(0xFFFDD644) : null,
                    ),
                    onPressed: () {
                      final detail = detailProvider.detailComic!;
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
                      libraryProvider.toggleBookmark(bookmarkModel);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<DetailProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading || provider.detailComic == null) {
            return const _DetailSkeleton();
          }

          final detail = provider.detailComic!;
          final libraryProvider = context.watch<LibraryProvider>();
          final savedChapters = libraryProvider.bookmarks.where((b) {
            return b.link == widget.comicUrl && b.latestChapter != null && b.chapterLink != null;
          }).toList();

          var filteredChapters = detail.chapters.where((chap) {
             return chap.title.toLowerCase().contains(_searchChapterQuery.toLowerCase());
          }).toList();

          if (_isAscending) {
            filteredChapters = filteredChapters.reversed.toList();
          }

          return Scrollbar(
            controller: _scrollController,
            interactive: true,
            thickness: 6.0,
            radius: const Radius.circular(3.0),
            child: CustomScrollView(
              controller: _scrollController,
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
                              if (detail.comic.formatEmoji.isNotEmpty)
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
                                      detail.comic.formatEmoji,
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
                                if (detail.comic.statusLabel.isNotEmpty)
                                  Chip(
                                    label: Text(
                                      detail.comic.statusLabel,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: Colors.blue.withOpacity(0.1),
                                  ),
                                  if (detail.comic.typeLabel.isNotEmpty)
                                    Chip(
                                      label: Text(
                                        detail.comic.typeLabel,
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
                                  children: detail.genres.map((g) => GenreChip(label: g)).toList(),
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
              if (savedChapters.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          itemCount: savedChapters.length,
                          itemBuilder: (context, index) {
                            final saved = savedChapters[index];
                            final chap = ChapterModel(
                              title: saved.latestChapter!.toLowerCase().contains('chapter')
                                  ? saved.latestChapter!
                                  : 'Chapter ${saved.latestChapter}',
                              link: saved.chapterLink!,
                              releaseDate: 'Tersimpan',
                            );
                            return ChapterTile(
                              chapter: chap,
                              comicUrl: widget.comicUrl,
                            );
                          },
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'List Chapter (${detail.chapters.length} chapter)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(
                              _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Theme.of(context).primaryColor,
                            ),
                            tooltip: _isAscending ? 'Urutan terlama' : 'Urutan terbaru',
                            onPressed: () {
                              setState(() {
                                _isAscending = !_isAscending;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SearchInput(
                        controller: _searchController,
                        hintText: 'Cari chapter...',
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
                  return ChapterTile(
                    chapter: filteredChapters[index],
                    comicUrl: widget.comicUrl,
                  );
                }, childCount: filteredChapters.length),
              ),
            ],
          ),
        );
        },
      ),
      floatingActionButton: AnimatedSlide(
        offset: _showBackToTop ? Offset.zero : const Offset(0, 1.5),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _showBackToTop ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            onPressed: _showBackToTop
                ? () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            child: const Icon(Icons.keyboard_arrow_up),
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Shimmer(width: 120, height: 160, borderRadius: 8),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Shimmer(width: double.infinity, height: 24, borderRadius: 4),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Shimmer(width: 60, height: 20, borderRadius: 4),
                          SizedBox(width: 8),
                          Shimmer(width: 60, height: 20, borderRadius: 4),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Shimmer(width: 40, height: 16, borderRadius: 4),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Shimmer(width: 50, height: 20, borderRadius: 4),
                          SizedBox(width: 4),
                          Shimmer(width: 50, height: 20, borderRadius: 4),
                          SizedBox(width: 4),
                          Shimmer(width: 50, height: 20, borderRadius: 4),
                        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Shimmer(width: 80, height: 20, borderRadius: 4),
                SizedBox(height: 8),
                Shimmer(width: double.infinity, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                Shimmer(width: double.infinity, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                Shimmer(width: 180, height: 14, borderRadius: 4),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Shimmer(width: 120, height: 20, borderRadius: 4),
                SizedBox(height: 8),
                Shimmer(width: double.infinity, height: 40, borderRadius: 8),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const ChapterTileSkeleton(),
            childCount: 5,
          ),
        ),
      ],
    );
  }
}
