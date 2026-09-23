import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/comic_model.dart';
import '../../core/constants/constants.dart';
import '../../util/util.dart';
import 'package:go_router/go_router.dart';

class ComicCard extends StatefulWidget {
  final ComicModel comic;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool enableRetry;
  final Map<String, String>? httpHeaders;

  const ComicCard({
    Key? key,
    required this.comic,
    this.onTap,
    this.onDelete,
    this.enableRetry = false,
    this.httpHeaders,
  }) : super(key: key);
  @override
  _ComicCardState createState() => _ComicCardState();
}

class _ComicCardState extends State<ComicCard> {
  int _retryKey = 0;
  late String _formattedSubtitle;

  static const _bottomGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0xEB000000),
      Color(0xB3000000),
      Colors.transparent,
    ],
    stops: [0.0, 0.7, 1.0],
  );

  @override
  void initState() {
    super.initState();
    _formattedSubtitle = _formatChapter(widget.comic.latestChapter, widget.comic.updatedAt);
  }

  @override
  void didUpdateWidget(ComicCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.comic.latestChapter != widget.comic.latestChapter ||
        oldWidget.comic.updatedAt != widget.comic.updatedAt) {
      _formattedSubtitle = _formatChapter(widget.comic.latestChapter, widget.comic.updatedAt);
    }
  }

  void _retry() {
    setState(() {
      _retryKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap ?? () {
        context.push('/detail', extra: widget.comic.link);
      },
      child: Card(
        clipBehavior: Clip.hardEdge,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            KeyedSubtree(
              key: ValueKey('${widget.comic.thumbUrl}_$_retryKey'),
              child: CachedNetworkImage(
                imageUrl: widget.comic.thumbUrl.isNotEmpty
                    ? widget.comic.thumbUrl
                    : 'https://via.placeholder.com/150',
                httpHeaders: widget.httpHeaders ?? AppConstants.imageHeaders,
                memCacheWidth: 350,
                maxWidthDiskCache: 600,
                fadeInDuration: const Duration(milliseconds: 120),
                fadeOutDuration: Duration.zero,
                placeholder: (context, url) => const ColoredBox(color: Color(0xFF1E1E1E)),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorWidget: (context, url, error) => widget.enableRetry
                    ? Center(
                        child: IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _retry,
                        ),
                      )
                    : const Center(child: Icon(Icons.error)),
              ),
            ),

            // Bottom Info Overlay with Smooth Gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  gradient: _bottomGradient,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chips (Status/Type)
                    if (widget.comic.statusLabel.isNotEmpty || widget.comic.typeLabel.isNotEmpty) ...[
                      Wrap(
                        spacing: 4.0,
                        runSpacing: 4.0,
                        children: [
                          if (widget.comic.statusLabel.isNotEmpty)
                            _buildChip(widget.comic.statusLabel, Colors.blue),
                          if (widget.comic.typeLabel.isNotEmpty)
                            _buildChip(widget.comic.typeLabel, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Title
                    SizedBox(
                      height: 34,
                      child: Text(
                        widget.comic.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                          shadows: [
                            Shadow(offset: Offset(0, 1), blurRadius: 2.0, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                    
                    // Chapter & Updated Time
                    const SizedBox(height: 2),
                    Text(
                      _formattedSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Delete Button
            if (widget.onDelete != null)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onDelete,
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),

            // Pinned Icon Badge
            if (widget.comic.isPinned)
              Positioned(
                top: 4,
                right: widget.onDelete != null ? 32 : 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),

            // Top Left Badges (Voratoon Source Label & Format Flag below)
            Positioned(
              top: 6,
              left: 6,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xEBFFFFFF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Image.asset(
                      'lib/assets/logo_voratoon_1.png',
                      height: 12,
                      cacheHeight: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (widget.comic.formatEmoji.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.comic.formatEmoji,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _formatChapter(String? chapter, [String? updatedAt]) {
    String formattedChapter = '';
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
    if (updatedAt != null && updatedAt.trim().isNotEmpty) {
      final trimmed = updatedAt.trim();
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
}

