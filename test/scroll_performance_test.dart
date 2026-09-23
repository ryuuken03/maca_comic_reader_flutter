import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maca/data/models/comic_model.dart';
import 'package:maca/presentation/pages/comic_list_page.dart';
import 'package:maca/presentation/pages/home/home_content.dart';
import 'package:maca/presentation/providers/home_provider.dart';
import 'package:maca/presentation/widgets/comic_card.dart';

class MockHomeProvider extends HomeProvider {
  final List<ComicModel> mockDiscoverComics;
  final List<ComicModel> mockHomeComics;
  final List<ComicModel> mockPopularComics;
  final List<ComicModel> mockProjectComics;

  MockHomeProvider({
    this.mockDiscoverComics = const [],
    this.mockHomeComics = const [],
    this.mockPopularComics = const [],
    this.mockProjectComics = const [],
  });

  @override
  List<ComicModel> get discoverComics => mockDiscoverComics;

  @override
  List<ComicModel> get homeComics => mockHomeComics;

  @override
  List<ComicModel> get popularComics => mockPopularComics;

  @override
  List<ComicModel> get projectComics => mockProjectComics;

  @override
  bool get isLoading => false;

  @override
  bool get hasNextPage => false;

  @override
  Future<void> fetchDiscover({
    String? searchQuery,
    String? preset,
    String? type,
    List<String>? genres,
    int page = 1,
    int take = 20,
  }) async {}

  @override
  Future<void> fetchHomeData({int take = 20}) async {}
}

void main() {
  final sampleComic = ComicModel(
    title: 'Solo Leveling',
    link: 'https://api.voratoon.com/series/solo-leveling',
    thumbUrl: 'https://example.com/thumb.jpg',
    latestChapter: 'Chapter 200',
    updatedAt: '2026-09-23T10:00:00Z',
    status: 'Ongoing',
    type: 'Manhwa',
  );

  group('Scroll Performance & Optimization Tests', () {
    testWidgets('ComicCard renders with subtitle caching and updates on didUpdateWidget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicCard(comic: sampleComic),
          ),
        ),
      );

      expect(find.text('Solo Leveling'), findsOneWidget);
      expect(find.byType(ComicCard), findsOneWidget);

      final updatedComic = ComicModel(
        title: 'Solo Leveling Ragnarok',
        link: 'https://api.voratoon.com/series/solo-leveling',
        thumbUrl: 'https://example.com/thumb.jpg',
        latestChapter: 'Chapter 25',
        updatedAt: 'Baru saja',
        status: 'Ongoing',
        type: 'Manhwa',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicCard(comic: updatedComic),
          ),
        ),
      );

      expect(find.text('Solo Leveling Ragnarok'), findsOneWidget);
      expect(find.textContaining('Chapter 25 • Baru saja'), findsOneWidget);
    });

    testWidgets('ComicListPage uses CustomScrollView and SliverGrid without viewport resize Column',
        (WidgetTester tester) async {
      final mockComics = List.generate(
        10,
        (i) => ComicModel(
          title: 'Comic $i',
          link: 'https://api.voratoon.com/series/comic-$i',
          thumbUrl: 'https://example.com/thumb$i.jpg',
          latestChapter: 'Ch. $i',
        ),
      );

      final homeProvider = MockHomeProvider(mockDiscoverComics: mockComics);

      await tester.pumpWidget(
        ChangeNotifierProvider<HomeProvider>.value(
          value: homeProvider,
          child: const MaterialApp(
            home: ComicListPage(title: 'Penjelajah'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverGrid), findsOneWidget);
      expect(find.byType(ComicCard), findsWidgets);
    });

    testWidgets('HomeContent uses CustomScrollView and SliverGrid directly without SliverLayoutBuilder',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockComics = List.generate(
        6,
        (i) => ComicModel(
          title: 'Home Comic $i',
          link: 'https://api.voratoon.com/series/home-$i',
          thumbUrl: 'https://example.com/thumb$i.jpg',
          latestChapter: 'Ch. 1',
        ),
      );

      final homeProvider = MockHomeProvider(
        mockHomeComics: mockComics,
        mockPopularComics: mockComics,
        mockProjectComics: mockComics,
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<HomeProvider>.value(
          value: homeProvider,
          child: const MaterialApp(
            home: HomeContent(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverGrid), findsOneWidget);
      expect(find.byType(SliverLayoutBuilder), findsNothing);
    });
  });
}
