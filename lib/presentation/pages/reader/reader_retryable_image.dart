import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/constants.dart';
import '../../../core/utils/cache_manager.dart';

const _kAccent = Color(0xFFFDD644);

// ─── Retryable Image ───────────────────────────────────────────────────────────
class RetryableImage extends StatefulWidget {
  final String imageUrl;
  final int pageIndex;
  final VoidCallback? onTap;

  const RetryableImage({
    super.key,
    required this.imageUrl,
    required this.pageIndex,
    this.onTap,
  });

  @override
  State<RetryableImage> createState() => _RetryableImageState();
}

class _RetryableImageState extends State<RetryableImage> {
  int _retryKey = 0;
  bool _isRetrying = false;
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if (scale <= 1.0 && _isZoomed) {
      setState(() => _isZoomed = false);
    }
  }

  Future<void> _retry() async {
    setState(() => _isRetrying = true);
    try {
      await CustomCacheManager.instance.removeFile(widget.imageUrl);
      PaintingBinding.instance.imageCache.evict(
        CachedNetworkImageProvider(
          widget.imageUrl,
          cacheManager: CustomCacheManager.instance,
        ),
      );
    } catch (e) {
      debugPrint(
          '[ReaderPage] Gagal membersihkan cache Hal ${widget.pageIndex}: $e');
    }
    if (mounted) {
      setState(() {
        _retryKey++;
        _isRetrying = false;
      });
    }
  }

  void _handleDoubleTap() {
    if (_isZoomed) {
      _transformationController.value = Matrix4.identity();
      setState(() => _isZoomed = false);
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final m = Matrix4.identity()
        ..setEntry(0, 0, 2.5)
        ..setEntry(1, 1, 2.5)
        ..setEntry(0, 3, -position.dx * 1.5)
        ..setEntry(1, 3, -position.dy * 1.5);
      _transformationController.value = m;
      setState(() => _isZoomed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRetrying) {
      return Container(
        height: 250,
        color: const Color(0xFF1E1E1E),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(_kAccent)),
            ),
            const SizedBox(height: 12),
            Text(
              'Memuat ulang halaman ${widget.pageIndex}...',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final effectiveWidth = screenWidth > 720 ? 720.0 : screenWidth;
    final targetMemCacheWidth = (effectiveWidth * dpr).round();

    final isLocalFile = !widget.imageUrl.startsWith('http');
    final Widget imageWidget;

    if (isLocalFile) {
      imageWidget = Image.file(
        File(widget.imageUrl),
        cacheWidth: targetMemCacheWidth,
        fit: BoxFit.fitWidth,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint(
              '[ReaderPage] ❌ Gagal load gambar lokal Hal ${widget.pageIndex}: ${widget.imageUrl} | Error: $error');
          return _ImageErrorPlaceholder(
            pageIndex: widget.pageIndex,
            showRetry: false,
          );
        },
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: widget.imageUrl,
        cacheManager: CustomCacheManager.instance,
        httpHeaders: AppConstants.imageHeaders,
        memCacheWidth: targetMemCacheWidth,
        fit: BoxFit.fitWidth,
        width: double.infinity,
        placeholder: (context, url) => const SizedBox(
          height: 300,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(_kAccent),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint(
              '[ReaderPage] ❌ Gagal load gambar Hal ${widget.pageIndex}: $url | Error: $error');
          return _ImageErrorPlaceholder(
            pageIndex: widget.pageIndex,
            showRetry: true,
            onRetry: _retry,
            imageUrl: widget.imageUrl,
          );
        },
      );
    }

    return KeyedSubtree(
      key: ValueKey('${widget.imageUrl}_$_retryKey'),
      child: _isZoomed
          ? InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              panEnabled: true,
              scaleEnabled: true,
              child: GestureDetector(
                onTap: widget.onTap,
                onDoubleTapDown: (d) => _doubleTapDetails = d,
                onDoubleTap: _handleDoubleTap,
                child: imageWidget,
              ),
            )
          : GestureDetector(
              onTap: widget.onTap,
              onDoubleTapDown: (d) => _doubleTapDetails = d,
              onDoubleTap: _handleDoubleTap,
              child: imageWidget,
            ),
    );
  }
}

// ─── Image Error Placeholder ───────────────────────────────────────────────────
class _ImageErrorPlaceholder extends StatelessWidget {
  final int pageIndex;
  final bool showRetry;
  final VoidCallback? onRetry;
  final String? imageUrl;

  const _ImageErrorPlaceholder({
    required this.pageIndex,
    required this.showRetry,
    this.onRetry,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      color: const Color(0xFF1E1E1E),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_outlined,
              color: Colors.white24, size: 48),
          const SizedBox(height: 12),
          Text(
            'Gagal memuat halaman $pageIndex',
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold),
          ),
          if (imageUrl != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                imageUrl!,
                style: const TextStyle(color: Colors.white30, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
          if (showRetry && onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(AppStrings.retry),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kAccent,
                side: const BorderSide(color: _kAccent, width: 0.8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
