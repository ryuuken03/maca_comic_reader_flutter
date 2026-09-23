import 'package:flutter/material.dart';
import '../../widgets/shimmer.dart';

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

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
                      const Shimmer(
                          width: double.infinity, height: 24, borderRadius: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
