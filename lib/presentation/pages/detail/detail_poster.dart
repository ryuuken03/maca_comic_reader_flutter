import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/constants.dart';
import '../../../data/models/detail_comic_model.dart';

class DetailPoster extends StatelessWidget {
  final double width;
  final double height;
  final DetailComicModel detail;
  final bool isPinned;

  const DetailPoster({
    super.key,
    required this.width,
    required this.height,
    required this.detail,
    required this.isPinned,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: detail.comic.thumbUrl.isNotEmpty
                  ? detail.comic.thumbUrl
                  : 'https://via.placeholder.com/150',
              httpHeaders: AppConstants.imageHeaders,
              memCacheWidth: 350,
              maxWidthDiskCache: 600,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
            // Top Left Badge (Voratoon Source Label)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Image.asset(
                  'lib/assets/logo_voratoon_1.png',
                  height: 12,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Bottom Left Badge (Country / Format Flag)
            if (detail.comic.formatEmoji.isNotEmpty)
              Positioned(
                bottom: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    detail.comic.formatEmoji,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            if (isPinned)
              Positioned(
                top: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
