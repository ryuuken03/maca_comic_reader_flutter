import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/comic_model.dart';
import '../../providers/reader_provider.dart';
import '../../providers/library_provider.dart';

const _kAccent = Color(0xFFFDD644);

// ─── Chapter Nav Button ────────────────────────────────────────────────────────
enum NavDirection { prev, next }

class ChapterNavButton extends StatelessWidget {
  final NavDirection direction;
  final String? chapterUrl;
  final VoidCallback? onTap;
  final bool isTablet;

  const ChapterNavButton({
    super.key,
    required this.direction,
    required this.chapterUrl,
    required this.onTap,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final isPrev = direction == NavDirection.prev;
    final isEnabled = chapterUrl != null && onTap != null;
    final icon = isPrev ? Icons.skip_previous_rounded : Icons.skip_next_rounded;

    return IconButton(
      icon: Icon(icon,
          size: isTablet ? 30 : 26,
          color: isEnabled ? Colors.white : Colors.white24),
      onPressed: onTap,
      tooltip: isPrev ? 'Chapter Sebelumnya' : 'Chapter Berikutnya',
    );
  }
}

// ─── Reader Bottom Bar ─────────────────────────────────────────────────────────
class ReaderBottomBar extends StatelessWidget {
  final String chapterUrl;
  final bool fromDetail;
  final bool isTablet;
  final double brightnessFilter;
  final ValueChanged<double> onBrightnessChanged;
  final String Function(ReaderProvider) chapterLabelBuilder;

  const ReaderBottomBar({
    super.key,
    required this.chapterUrl,
    required this.fromDetail,
    required this.isTablet,
    required this.brightnessFilter,
    required this.onBrightnessChanged,
    required this.chapterLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = isTablet ? 48.0 : 16.0;

    return Consumer<ReaderProvider>(
      builder: (context, provider, child) {
        String? nextChapterUrl;
        String? prevChapterUrl;

        if (provider.detailComic != null) {
          final chapters = provider.detailComic!.chapters;
          final currentIndex =
              chapters.indexWhere((c) => c.link == chapterUrl);
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
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Brightness row
              Row(
                children: [
                  const Icon(Icons.brightness_high_rounded,
                      size: 18, color: Colors.white54),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2.0,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 10),
                        activeTrackColor: _kAccent,
                        thumbColor: _kAccent,
                        inactiveTrackColor: Colors.white24,
                        overlayColor: _kAccent.withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        value: brightnessFilter,
                        min: 0.0,
                        max: 0.7,
                        divisions: 14,
                        onChanged: onBrightnessChanged,
                      ),
                    ),
                  ),
                  const Icon(Icons.brightness_3_rounded,
                      size: 18, color: Colors.white54),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${(brightnessFilter / 0.7 * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white54),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),

              Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08)),

              // Chapter navigation row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ChapterNavButton(
                    direction: NavDirection.prev,
                    chapterUrl: prevChapterUrl,
                    isTablet: isTablet,
                    onTap: prevChapterUrl != null
                        ? () => context.pushReplacement('/reader', extra: {
                              'chapterUrl': prevChapterUrl,
                              'fromDetail': fromDetail,
                            })
                        : null,
                  ),

                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (fromDetail && context.canPop()) {
                          context.pop();
                        } else if (provider.readerComicLink.isNotEmpty) {
                          context.pushReplacement('/detail',
                              extra: provider.readerComicLink);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              provider.readerComicTitle.isNotEmpty
                                  ? provider.readerComicTitle
                                  : 'Memuat...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 14 : 13,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Consumer<ReaderProvider>(
                              builder: (_, p, __) => Text(
                                chapterLabelBuilder(p),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  ChapterNavButton(
                    direction: NavDirection.next,
                    chapterUrl: nextChapterUrl,
                    isTablet: isTablet,
                    onTap: nextChapterUrl != null
                        ? () => context.pushReplacement('/reader', extra: {
                              'chapterUrl': nextChapterUrl,
                              'fromDetail': fromDetail,
                            })
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Reader AppBar ─────────────────────────────────────────────────────────────
class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String chapterUrl;
  final bool isTablet;
  final bool isWebtoonMode;
  final bool isRTL;
  final bool showInfoOverlay;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleRTL;
  final VoidCallback onToggleInfoOverlay;
  final String Function(ReaderProvider) chapterLabelBuilder;

  const ReaderAppBar({
    super.key,
    required this.chapterUrl,
    required this.isTablet,
    required this.isWebtoonMode,
    required this.isRTL,
    required this.showInfoOverlay,
    required this.onToggleMode,
    required this.onToggleRTL,
    required this.onToggleInfoOverlay,
    required this.chapterLabelBuilder,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color == Colors.white24 ? Colors.white70 : color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return AppBar(
      titleSpacing: canPop ? 0 : null,
      title: Consumer<ReaderProvider>(
        builder: (context, provider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.readerComicTitle.isNotEmpty
                    ? provider.readerComicTitle
                    : 'Memuat...',
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      chapterLabelBuilder(provider),
                      style: TextStyle(
                        fontSize: isTablet ? 12 : 11,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (provider.isOffline) ...[
                    const SizedBox(width: 4),
                    _buildBadge(AppStrings.offlineMode, _kAccent),
                  ],
                  const SizedBox(width: 4),
                  _buildBadge(
                    isWebtoonMode
                        ? AppStrings.modeWebtoon
                        : AppStrings.modeManga,
                    Colors.white24,
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        // Mode toggle
        Consumer<ReaderProvider>(builder: (context, provider, _) {
          return IconButton(
            icon: Icon(
              isWebtoonMode
                  ? Icons.view_day_rounded
                  : Icons.auto_stories_rounded,
              color: Colors.white,
            ),
            tooltip: isWebtoonMode
                ? 'Mode Webtoon → Manga'
                : 'Mode Manga → Webtoon',
            onPressed: onToggleMode,
          );
        }),

        // Settings popup
        PopupMenuButton<String>(
          icon: const Icon(Icons.tune_rounded, color: Colors.white),
          tooltip: 'Pengaturan Baca',
          itemBuilder: (context) => [
            if (!isWebtoonMode)
              PopupMenuItem(
                value: 'rtl',
                child: Row(
                  children: [
                    Icon(
                      isRTL
                          ? Icons.format_textdirection_r_to_l
                          : Icons.format_textdirection_l_to_r,
                      size: 20,
                      color: isRTL ? _kAccent : null,
                    ),
                    const SizedBox(width: 12),
                    Text(isRTL
                        ? AppStrings.directionRTL
                        : AppStrings.directionLTR),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'overlay',
              child: Row(
                children: [
                  Icon(
                    showInfoOverlay ? Icons.schedule : Icons.schedule_outlined,
                    size: 20,
                    color: showInfoOverlay ? _kAccent : null,
                  ),
                  const SizedBox(width: 12),
                  Text(showInfoOverlay
                      ? 'Sembunyikan Jam & Baterai'
                      : 'Tampilkan Jam & Baterai'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'rtl') onToggleRTL();
            if (value == 'overlay') onToggleInfoOverlay();
          },
        ),

        // Bookmark
        Consumer2<ReaderProvider, LibraryProvider>(
          builder: (context, readerProvider, libraryProvider, child) {
            final actIndexStr = chapterUrl
                .split('/')
                .lastWhere((e) => e.isNotEmpty, orElse: () => '');
            if (readerProvider.readerComicLink.isEmpty ||
                readerProvider.detailComic == null) {
              return const SizedBox.shrink();
            }
            return FutureBuilder<bool>(
              future: libraryProvider.isBookmarkedReader(
                  readerProvider.readerComicLink, actIndexStr),
              builder: (context, snapshot) {
                final isBookmarked = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? _kAccent : Colors.white,
                  ),
                  onPressed: () {
                    final detail = readerProvider.detailComic!;
                    libraryProvider.toggleChapterBookmark(ComicModel(
                      title: detail.comic.title,
                      thumbUrl: detail.comic.thumbUrl,
                      link: detail.comic.link,
                      latestChapter: actIndexStr,
                      chapterLink: chapterUrl,
                      type: detail.type,
                      status: detail.status,
                      format: detail.format,
                    ));
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
