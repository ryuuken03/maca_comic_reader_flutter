import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/comic_model.dart';
import 'package:go_router/go_router.dart';

class ComicCard extends StatelessWidget {
  final ComicModel comic;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ComicCard({Key? key, required this.comic, this.onTap, this.onDelete}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () {
        context.push('/detail', extra: comic.link);
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            CachedNetworkImage(
              imageUrl: comic.thumbUrl.isNotEmpty
                  ? comic.thumbUrl
                  : 'https://via.placeholder.com/150',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorWidget: (context, url, error) => const Center(child: Icon(Icons.error)),
            ),
            
            // Bottom Info Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65), // background darkmode 65%
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chips (Status/Type)
                    if (comic.statusLabel.isNotEmpty || comic.typeLabel.isNotEmpty) ...[
                      Wrap(
                        spacing: 4.0,
                        runSpacing: 4.0,
                        children: [
                          if (comic.statusLabel.isNotEmpty)
                            _buildChip(comic.statusLabel, Colors.blue),
                          if (comic.typeLabel.isNotEmpty)
                            _buildChip(comic.typeLabel, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    
                    // Title
                    SizedBox(
                      height: 36, // Fix height for 2 lines
                      child: Text(
                        comic.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                          shadows: [
                            Shadow(offset: Offset(0, 1), blurRadius: 2.0, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                    
                    // Chapter
                    const SizedBox(height: 2),
                    Text(
                      (comic.latestChapter == null || comic.latestChapter!.isEmpty)
                          ? ''
                          : (comic.latestChapter!.toLowerCase().contains('chapter')
                              ? comic.latestChapter!
                              : 'Ch. ${comic.latestChapter!}'),
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
            if (onDelete != null)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDelete,
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

            // Format Flags
            if (comic.formatEmoji.isNotEmpty)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    comic.formatEmoji,
                    style: const TextStyle(fontSize: 12),
                  ),
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
}

