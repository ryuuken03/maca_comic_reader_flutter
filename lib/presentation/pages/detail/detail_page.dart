import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/comic_model.dart';
import '../../../data/models/detail_comic_model.dart';
import '../../../data/models/chapter_model.dart';
import '../../../core/constants/constants.dart';
import '../../../util/util.dart';
import '../../providers/detail_provider.dart';
import '../../providers/library_provider.dart';
import '../../providers/download_provider.dart';
import '../../widgets/chapter_tile.dart';
import '../../widgets/genre_chip.dart';
import '../../widgets/search_input.dart';
import 'detail_badge.dart';
import 'detail_cta_button.dart';
import 'detail_poster.dart';
import 'detail_chapter_header.dart';
import 'detail_chapter_filter.dart';
import 'detail_empty_state.dart';
import 'detail_skeleton.dart';

class DetailPage extends StatefulWidget {
  final String comicUrl;

  const DetailPage({super.key, required this.comicUrl});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isExpanded = false;
  String _searchChapterQuery = '';
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;
  bool _showBackToTop = false;
  bool _isAscending = false;
  bool _onlyDownloaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 600) {
        if (!_showBackToTop) setState(() => _showBackToTop = true);
      } else {
        if (_showBackToTop) setState(() => _showBackToTop = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetailProvider>().fetchDetail(widget.comicUrl);
      context.read<LibraryProvider>().fetchBookmarks();
      context.read<LibraryProvider>().fetchHistory();
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
        title: const Text(AppStrings.comicDetail),
        actions: [
          Consumer2<DetailProvider, LibraryProvider>(
            builder: (context, detailProvider, libraryProvider, child) {
              if (detailProvider.detailComic == null) return const SizedBox.shrink();

              final detail = detailProvider.detailComic!;
              final existingBookmark = libraryProvider.getBookmark(detail.comic.link) ??
                  libraryProvider.getBookmark(widget.comicUrl);
              final isBookmarked = existingBookmark != null;
              final isBookmarkedFromReader = isBookmarked &&
                  existingBookmark.chapterLink != null &&
                  existingBookmark.chapterLink!.isNotEmpty;

              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? const Color(0xFFFDD644) : null,
                ),
                tooltip: isBookmarkedFromReader ? AppStrings.savedFromReader : null,
                onPressed: isBookmarkedFromReader
                    ? null // Jika sudah bookmark di reader, tombol dinonaktifkan agar tidak mereplace data chapter terakhir
                    : () {
                  if (existingBookmark != null) {
                    libraryProvider.removeBookmark(existingBookmark.link);
                  } else {
                    final bookmarkModel = ComicModel(
                      title: detail.comic.title,
                      thumbUrl: detail.comic.thumbUrl,
                      link: detail.comic.link,
                      latestChapter: null, // Sesuai aturan: jika dimulai dari detail_page, chapter dibuat null
                      chapterLink: null,   // Sesuai aturan: jika dimulai dari detail_page, chapter dibuat null
                      type: detail.type,
                      status: detail.status,
                      format: detail.format,
                      updatedAt: detail.comic.updatedAt.isNotEmpty
                          ? detail.comic.updatedAt
                          : detail.displayDate,
                      createdAt: detail.createdAt.isNotEmpty
                          ? detail.createdAt
                          : detail.comic.createdAt,
                      isPinned: detail.isPinned,
                      isHot: detail.isHot,
                      isRecommended: detail.isRecommended,
                    );
                    libraryProvider.toggleBookmark(bookmarkModel);
                  }
                },
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<DetailProvider>().fetchDetail(widget.comicUrl, forceRefresh: true);
          context.read<LibraryProvider>().fetchBookmarks();
          context.read<LibraryProvider>().fetchHistory();
        },
        child: Consumer<DetailProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const DetailSkeleton();
            }

            if (provider.detailComic == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      AppStrings.loadDetailFailed,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.comicNotFound,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<DetailProvider>()
                            .fetchDetail(widget.comicUrl);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text(AppStrings.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD644),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              );
            }

            final detail = provider.detailComic!;
            final libraryProvider = context.watch<LibraryProvider>();
            final isPinned = detail.isPinned ||
                detail.comic.isPinned ||
                libraryProvider.bookmarks
                    .any((b) => b.link == widget.comicUrl && b.isPinned);
            final isHot = detail.isHot || detail.comic.isHot;
            final isRecommended =
                detail.isRecommended || detail.comic.isRecommended;

            bool matchLink(String? a, String? b) {
              if (a == null || b == null) return false;
              if (a == b) return true;
              final cleanA = a.split('?').first.replaceAll(RegExp(r'/+$'), '');
              final cleanB = b.split('?').first.replaceAll(RegExp(r'/+$'), '');
              if (cleanA == cleanB) return true;
              final slugA = cleanA.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');
              final slugB = cleanB.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');
              return slugA.isNotEmpty && slugA == slugB;
            }

            final bookmarkedItem = libraryProvider.bookmarks
                .cast<ComicModel?>()
                .firstWhere(
                  (b) =>
                      matchLink(b?.link, widget.comicUrl) &&
                      b?.chapterLink != null &&
                      b!.chapterLink!.isNotEmpty,
                  orElse: () => null,
                );

            final historyItem = libraryProvider.history
                .cast<ComicModel?>()
                .firstWhere(
                  (h) =>
                      matchLink(h?.link, widget.comicUrl) &&
                      h?.chapterLink != null &&
                      h!.chapterLink!.isNotEmpty,
                  orElse: () => null,
                );

            String? targetChapterUrl;
            String ctaLabel;
            bool isContinue = false;

            String formatCleanTitle(String raw) {
              if (raw.trim().isEmpty) return '';
              final lower = raw.toLowerCase().trim();
              if (lower.startsWith('chapter') || lower.startsWith('ch')) {
                return raw.trim();
              }
              return 'Chapter ${raw.trim()}';
            }

            // Prioritaskan chapter dari Bookmark dulu, jika tidak ada baru dari History
            if (bookmarkedItem != null &&
                bookmarkedItem.chapterLink != null &&
                bookmarkedItem.chapterLink!.isNotEmpty) {
              var rawCh = bookmarkedItem.latestChapter ?? '';
              if (rawCh.isEmpty) {
                final matchedChapter = detail.chapters.cast<ChapterModel?>().firstWhere(
                  (c) => matchLink(c?.link, bookmarkedItem.chapterLink),
                  orElse: () => null,
                );
                if (matchedChapter != null) {
                  rawCh = matchedChapter.title;
                }
              }
              final bookmarkTitle = formatCleanTitle(rawCh);
              targetChapterUrl = bookmarkedItem.chapterLink;
              ctaLabel = bookmarkTitle.isNotEmpty
                  ? '${AppStrings.readContinue} ($bookmarkTitle)'
                  : AppStrings.readContinue;
              isContinue = true;
            } else if (historyItem != null &&
                historyItem.chapterLink != null &&
                historyItem.chapterLink!.isNotEmpty) {
              var rawCh = historyItem.latestChapter ?? '';
              if (rawCh.isEmpty) {
                final matchedChapter = detail.chapters.cast<ChapterModel?>().firstWhere(
                  (c) => matchLink(c?.link, historyItem.chapterLink),
                  orElse: () => null,
                );
                if (matchedChapter != null) {
                  rawCh = matchedChapter.title;
                }
              }
              final lastReadTitle = formatCleanTitle(rawCh);
              targetChapterUrl = historyItem.chapterLink;
              ctaLabel = lastReadTitle.isNotEmpty
                  ? '${AppStrings.readContinue} ($lastReadTitle)'
                  : AppStrings.readContinue;
              isContinue = true;
            } else if (detail.chapters.isNotEmpty) {
              final firstChap = detail.chapters.last;
              targetChapterUrl = firstChap.link;
              ctaLabel = '${AppStrings.readStart}: ${firstChap.title}';
            } else {
              ctaLabel = AppStrings.readStart;
            }

            final downloadProvider = context.watch<DownloadProvider?>();
            final downloadedCount = detail.chapters
                .where(
                  (chap) =>
                      downloadProvider?.isChapterDownloaded(chap.link) ?? false,
                )
                .length;

            var filteredChapters = detail.chapters.where((chap) {
              final matchesSearch = chap.title
                  .toLowerCase()
                  .contains(_searchChapterQuery.toLowerCase());
              if (!matchesSearch) return false;
              if (_onlyDownloaded) {
                return downloadProvider?.isChapterDownloaded(chap.link) ??
                    false;
              }
              return true;
            }).toList();

            if (_isAscending) {
              filteredChapters = filteredChapters.reversed.toList();
            }

            final screenWidth = MediaQuery.sizeOf(context).width;
            final isTablet = screenWidth >= 720;

            if (isTablet) {
              return _buildTabletLayout(
                context,
                detail: detail,
                isPinned: isPinned,
                isHot: isHot,
                isRecommended: isRecommended,
                targetChapterUrl: targetChapterUrl,
                ctaLabel: ctaLabel,
                isContinue: isContinue,
                filteredChapters: filteredChapters,
                downloadedCount: downloadedCount,
                screenWidth: screenWidth,
              );
            }

            return _buildPhoneLayout(
              context,
              detail: detail,
              isPinned: isPinned,
              isHot: isHot,
              isRecommended: isRecommended,
              targetChapterUrl: targetChapterUrl,
              ctaLabel: ctaLabel,
              isContinue: isContinue,
              filteredChapters: filteredChapters,
              downloadedCount: downloadedCount,
              screenWidth: screenWidth,
            );
          },
        ),
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

  String _formatChapterSubtitle(DetailComicModel detail) {
    String formattedChapter = '';
    String? chapter = detail.comic.latestChapter;
    if (chapter == null || chapter.trim().isEmpty) {
      if (detail.chapters.isNotEmpty) {
        chapter = detail.chapters.first.title;
      }
    }
    if (chapter != null && chapter.trim().isNotEmpty) {
      final trimmed = chapter.trim();
      final lower = trimmed.toLowerCase();
      if (lower.startsWith('ch') || lower.contains('chapter') || lower.contains('oneshot')) {
        formattedChapter = trimmed;
      } else {
        formattedChapter = 'Ch. $trimmed';
      }
    }

    String formattedTime = '';
    final dateStr = detail.displayDate;
    if (dateStr.isNotEmpty) {
      final trimmed = dateStr.trim();
      if (trimmed.contains('lalu') || trimmed == 'Baru saja') {
        formattedTime = trimmed;
      } else {
        formattedTime = timeAgo(trimmed);
      }
    }

    if (formattedChapter.isNotEmpty && formattedTime.isNotEmpty) {
      return '$formattedChapter • $formattedTime';
    } else if (formattedChapter.isNotEmpty) {
      return formattedChapter;
    } else if (formattedTime.isNotEmpty) {
      return formattedTime;
    }
    return '';
  }

  Widget _buildTabletLayout(
    BuildContext context, {
    required DetailComicModel detail,
    required bool isPinned,
    required bool isHot,
    required bool isRecommended,
    required String? targetChapterUrl,
    required String ctaLabel,
    required bool isContinue,
    required List<ChapterModel> filteredChapters,
    required int downloadedCount,
    required double screenWidth,
  }) {
    final leftColumnWidth = (screenWidth * 0.38).clamp(320.0, 420.0);
    final chapterSubtitle = _formatChapterSubtitle(detail);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: leftColumnWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: DetailPoster(
                    width: 160,
                    height: 220,
                    detail: detail,
                    isPinned: isPinned,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  detail.comic.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: [
                    if (isHot)
                      DetailBadge('HOT', Colors.redAccent,
                          icon: Icons.local_fire_department_rounded),
                    if (isRecommended)
                      DetailBadge('REKOMENDASI', AppConstants.primaryColor,
                          icon: Icons.thumb_up_alt_rounded),
                    if (detail.comic.statusLabel.isNotEmpty)
                      DetailBadge(detail.comic.statusLabel, Colors.blue),
                    if (detail.comic.typeLabel.isNotEmpty)
                      DetailBadge(detail.comic.typeLabel, Colors.orange),
                  ],
                ),
                if (chapterSubtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    chapterSubtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                DetailCtaButton(
                  targetChapterUrl: targetChapterUrl,
                  ctaLabel: ctaLabel,
                  isContinue: isContinue,
                  comicTitle: detail.comic.title,
                  comicLink: detail.comic.link,
                  comicThumb: detail.comic.thumbUrl,
                ),
                if (detail.genres.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6.0,
                    runSpacing: 4.0,
                    children:
                        detail.genres.map<Widget>((g) => GenreChip(label: g)).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.synopsis,
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  detail.description.isNotEmpty
                      ? detail.description
                      : AppStrings.noSynopsis,
                  style: const TextStyle(
                      fontSize: 13, height: 1.4, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(
            thickness: 1, width: 1, color: Colors.white12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailChapterHeader(
                      totalChapters: detail.chapters.length,
                      filteredCount: filteredChapters.length,
                      isAscending: _isAscending,
                      onToggleSort: () =>
                          setState(() => _isAscending = !_isAscending),
                    ),
                    const SizedBox(height: 10),
                    SearchInput(
                      controller: _searchController,
                      hintText: AppStrings.searchChapterHint,
                      onChanged: (val) =>
                          setState(() => _searchChapterQuery = val),
                    ),
                    DetailChapterFilter(
                      totalChapters: detail.chapters.length,
                      downloadedCount: downloadedCount,
                      onlyDownloaded: _onlyDownloaded,
                      onSelectAll: () {
                        if (_onlyDownloaded) {
                          setState(() => _onlyDownloaded = false);
                        }
                      },
                      onSelectDownloaded: () {
                        if (!_onlyDownloaded) {
                          setState(() => _onlyDownloaded = true);
                        }
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredChapters.isEmpty
                    ? DetailEmptyChapterState(
                        isDownloadedFilter: _onlyDownloaded,
                        searchQuery: _searchChapterQuery,
                      )
                    : Scrollbar(
                        controller: _scrollController,
                        interactive: true,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: filteredChapters.length,
                          itemBuilder: (context, index) {
                            return ChapterTile(
                              chapter: filteredChapters[index],
                              comicUrl: widget.comicUrl,
                              comicTitle: detail.comic.title,
                              comicThumbUrl: detail.comic.thumbUrl,
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(
    BuildContext context, {
    required DetailComicModel detail,
    required bool isPinned,
    required bool isHot,
    required bool isRecommended,
    required String? targetChapterUrl,
    required String ctaLabel,
    required bool isContinue,
    required List<ChapterModel> filteredChapters,
    required int downloadedCount,
    required double screenWidth,
  }) {
    final coverWidth = screenWidth < 360 ? 100.0 : 120.0;
    final coverHeight = coverWidth * 1.33;
    final chapterSubtitle = _formatChapterSubtitle(detail);

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
                  DetailPoster(
                    width: coverWidth,
                    height: coverHeight,
                    detail: detail,
                    isPinned: isPinned,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.comic.title,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6.0,
                          runSpacing: 4.0,
                          children: [
                            if (isHot)
                              DetailBadge('HOT', Colors.redAccent,
                                  icon: Icons.local_fire_department_rounded),
                            if (isRecommended)
                              DetailBadge(
                                  'REKOMENDASI', AppConstants.primaryColor,
                                  icon: Icons.thumb_up_alt_rounded),
                            if (detail.comic.statusLabel.isNotEmpty)
                              DetailBadge(
                                  detail.comic.statusLabel, Colors.blue),
                            if (detail.comic.typeLabel.isNotEmpty)
                              DetailBadge(
                                  detail.comic.typeLabel, Colors.orange),
                          ],
                        ),
                        if (chapterSubtitle.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            chapterSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (detail.genres.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4.0,
                            runSpacing: 4.0,
                            children: detail.genres
                                .map<Widget>((g) => GenreChip(label: g))
                                .toList(),
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
              child: DetailCtaButton(
                targetChapterUrl: targetChapterUrl,
                ctaLabel: ctaLabel,
                isContinue: isContinue,
                comicTitle: detail.comic.title,
                comicLink: detail.comic.link,
                comicThumb: detail.comic.thumbUrl,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.synopsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () =>
                        setState(() => _isExpanded = !_isExpanded),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.description.isNotEmpty
                              ? detail.description
                              : AppStrings.noSynopsis,
                          maxLines: _isExpanded ? null : 4,
                          overflow: _isExpanded
                              ? null
                              : TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.white70),
                        ),
                        if (detail.description.length > 120) ...[
                          const SizedBox(height: 4),
                          Text(
                            _isExpanded
                                ? AppStrings.readLess
                                : AppStrings.readMore,
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DetailChapterHeader(
                    totalChapters: detail.chapters.length,
                    filteredCount: filteredChapters.length,
                    isAscending: _isAscending,
                    onToggleSort: () =>
                        setState(() => _isAscending = !_isAscending),
                  ),
                  const SizedBox(height: 10),
                  SearchInput(
                    controller: _searchController,
                    hintText: AppStrings.searchChapterHint,
                    onChanged: (val) =>
                        setState(() => _searchChapterQuery = val),
                  ),
                  DetailChapterFilter(
                    totalChapters: detail.chapters.length,
                    downloadedCount: downloadedCount,
                    onlyDownloaded: _onlyDownloaded,
                    onSelectAll: () {
                      if (_onlyDownloaded) {
                        setState(() => _onlyDownloaded = false);
                      }
                    },
                    onSelectDownloaded: () {
                      if (!_onlyDownloaded) {
                        setState(() => _onlyDownloaded = true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (filteredChapters.isEmpty)
            SliverToBoxAdapter(
              child: DetailEmptyChapterState(
                isDownloadedFilter: _onlyDownloaded,
                searchQuery: _searchChapterQuery,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return ChapterTile(
                    chapter: filteredChapters[index],
                    comicUrl: widget.comicUrl,
                    comicTitle: detail.comic.title,
                    comicThumbUrl: detail.comic.thumbUrl,
                  );
                },
                childCount: filteredChapters.length,
              ),
            ),
        ],
      ),
    );
  }
}
