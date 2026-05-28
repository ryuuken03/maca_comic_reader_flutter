import 'package:flutter/material.dart';

class Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const Shimmer({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  }) : super(key: key);

  @override
  _ShimmerState createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF242424) : Colors.grey[300]!;
    final highlightColor = isDark ? const Color(0xFF383838) : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (0.0 + _animation.value * 0.3).clamp(0.0, 1.0),
                (0.3 + _animation.value * 0.3).clamp(0.0, 1.0),
                (0.6 + _animation.value * 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ComicCardSkeleton extends StatelessWidget {
  const ComicCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: const Shimmer(
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }
}

class ChapterTileSkeleton extends StatelessWidget {
  const ChapterTileSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Shimmer(width: 140, height: 16, borderRadius: 4),
                SizedBox(height: 8),
                Shimmer(width: 80, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const Shimmer(width: 24, height: 24, borderRadius: 12),
        ],
      ),
    );
  }
}
