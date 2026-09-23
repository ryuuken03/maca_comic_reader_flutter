import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/adaptive_utils.dart';
import '../../../data/models/comic_model.dart';
import '../../providers/home_provider.dart';
import '../../widgets/comic_card.dart';
import '../../widgets/show_all_button.dart';
import '../../widgets/shimmer.dart';
import '../../../core/constants/app_strings.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final take = getAdaptiveGridTake(context);
        context.read<HomeProvider>().fetchHomeData(take: take);
      }
    });
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {String? preset, String? type}) {
    return InkWell(
      onTap: () {
        context
            .push('/list', extra: {'title': title, 'preset': preset, 'type': type});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildShowAllButton(BuildContext context, String title,
      {String? preset, String? type}) {
    return ShowAllButton(
      onTap: () {
        context
            .push('/list', extra: {'title': title, 'preset': preset, 'type': type});
      },
    );
  }

  Widget _buildHorizontalList(List<ComicModel> comics, {bool isLoading = false}) {
    if (isLoading) {
      return SizedBox(
        height: 250,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: 5,
          itemBuilder: (context, index) {
            return const SizedBox(
              width: 140,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: ComicCardSkeleton(),
              ),
            );
          },
        ),
      );
    }
    if (comics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text(AppStrings.noComicsFound)),
      );
    }
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: comics.length,
        cacheExtent: 300,
        itemBuilder: (context, index) {
          final comic = comics[index];
          return SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ComicCard(
                key: ValueKey('h_${comic.link}'),
                comic: comic,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridSliver(List<ComicModel> comics, {bool isLoading = false}) {
    if (isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            childAspectRatio: 0.68,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) => const ComicCardSkeleton(),
            childCount: 4,
          ),
        ),
      );
    }
    if (comics.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text(AppStrings.noComicsFound)),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          childAspectRatio: 0.68,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final comic = comics[index];
            return ComicCard(
              key: ValueKey('grid_${comic.link}'),
              comic: comic,
            );
          },
          childCount: comics.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'lib/assets/icon_voratoon.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 10),
            const Text(AppStrings.appTitle),
          ],
        ),
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          final isLoading = provider.isLoading &&
              provider.homeComics.isEmpty &&
              provider.popularComics.isEmpty;

          return RefreshIndicator(
            onRefresh: () {
              final take = getAdaptiveGridTake(context);
              return provider.fetchHomeData(take: take);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              cacheExtent: 500,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildSectionHeader(context, AppStrings.popularComics,
                          preset: 'popular_all'),
                      _buildHorizontalList(
                          isLoading ? [] : provider.popularComics,
                          isLoading: isLoading),
                      _buildShowAllButton(context, AppStrings.popularComics,
                          preset: 'popular_all'),

                      const SizedBox(height: 16),
                      _buildSectionHeader(context, AppStrings.projectComics,
                          type: 'project', preset: 'rilisan_terbaru'),
                      _buildHorizontalList(
                          isLoading ? [] : provider.projectComics,
                          isLoading: isLoading),
                      _buildShowAllButton(context, AppStrings.projectComics,
                          type: 'project', preset: 'rilisan_terbaru'),

                      const SizedBox(height: 16),
                      _buildSectionHeader(context, AppStrings.latestComics,
                          preset: 'rilisan_terbaru'),
                    ],
                  ),
                ),
                _buildGridSliver(isLoading ? [] : provider.homeComics,
                    isLoading: isLoading),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildShowAllButton(context, AppStrings.latestComics,
                        preset: 'rilisan_terbaru'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
