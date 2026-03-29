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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: comic.thumbUrl.isNotEmpty
                        ? comic.thumbUrl
                        : 'https://via.placeholder.com/150',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                  if (onDelete != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                          onPressed: onDelete,
                        ),
                      ),
                    ),
                  if (comic.format.toLowerCase() == 'manga' || comic.format.toLowerCase() == 'manhwa' || comic.format.toLowerCase() == 'manhua')
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          comic.format.toLowerCase() == 'manga' ? '🇯🇵' :
                          comic.format.toLowerCase() == 'manhwa' ? '🇰🇷' : '🇨🇳',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 36, // Fixed height for 2 lines
                    child: Text(
                      comic.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  if (comic.status.isNotEmpty || comic.type.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4.0,
                      runSpacing: 4.0,
                      children: [
                        if (comic.status.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(comic.status.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blue)),
                          ),
                        if (comic.type.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(comic.type.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                      ],
                    ),
                  ],
                  if (comic.latestChapter != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      comic.latestChapter!.toLowerCase().contains('chapter') 
                        ? comic.latestChapter! 
                        : 'Chapter ${comic.latestChapter!}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                  if (comic.updatedAt != null && comic.updatedAt != '') ...[
                    const SizedBox(height: 2),
                    Text(
                      comic.updatedAt,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
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
}
