import 'package:flutter/material.dart';
import '../../providers/reader_provider.dart';
import 'reader_retryable_image.dart';

// ─── Page Indicator Pill ───────────────────────────────────────────────────────
class PageIndicatorPill extends StatelessWidget {
  final int current;
  final int total;

  const PageIndicatorPill({
    super.key,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.72),
            Colors.black.withValues(alpha: 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 0.8),
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Tap Zone (Manga mode) ─────────────────────────────────────────────────────
class TapZone extends StatefulWidget {
  final Alignment alignment;
  final IconData icon;
  final VoidCallback onTap;

  const TapZone({
    super.key,
    required this.alignment,
    required this.icon,
    required this.onTap,
  });

  @override
  State<TapZone> createState() => _TapZoneState();
}

class _TapZoneState extends State<TapZone> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) =>
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _ctrl.reverse();
      });
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.alignment == Alignment.centerLeft;
    return Positioned(
      top: 0,
      bottom: 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      width: MediaQuery.sizeOf(context).width * 0.25,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: FadeTransition(
          opacity: _opacity,
          child: Container(
            alignment: widget.alignment,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              widget.icon,
              size: 36,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Manga Reader ──────────────────────────────────────────────────────────────
class MangaReader extends StatelessWidget {
  final ReaderProvider provider;
  final PageController pageController;
  final bool isRTL;
  final int currentPage;
  final VoidCallback onToggleControls;
  final ValueChanged<int> onPageChanged;

  const MangaReader({
    super.key,
    required this.provider,
    required this.pageController,
    required this.isRTL,
    required this.currentPage,
    required this.onToggleControls,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: pageController,
          reverse: isRTL,
          itemCount: provider.readerImages.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  child: RetryableImage(
                    imageUrl: provider.readerImages[index],
                    pageIndex: index + 1,
                    onTap: onToggleControls,
                  ),
                ),
              ),
            );
          },
        ),
        TapZone(
          alignment: Alignment.centerLeft,
          icon: isRTL ? Icons.chevron_right : Icons.chevron_left,
          onTap: () {
            final target = isRTL ? currentPage + 1 : currentPage - 1;
            if (target >= 0 && target < provider.readerImages.length) {
              pageController.animateToPage(target,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut);
            }
          },
        ),
        TapZone(
          alignment: Alignment.centerRight,
          icon: isRTL ? Icons.chevron_left : Icons.chevron_right,
          onTap: () {
            final target = isRTL ? currentPage - 1 : currentPage + 1;
            if (target >= 0 && target < provider.readerImages.length) {
              pageController.animateToPage(target,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut);
            }
          },
        ),
        Positioned(
          bottom: 72,
          left: 0,
          right: 0,
          child: Center(
            child: PageIndicatorPill(
              current: currentPage + 1,
              total: provider.readerImages.length,
            ),
          ),
        ),
      ],
    );
  }
}

