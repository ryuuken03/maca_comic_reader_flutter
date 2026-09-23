import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maca/core/constants/app_strings.dart';
import 'package:maca/data/models/chapter_model.dart';
import 'package:maca/data/models/comic_model.dart';
import 'package:maca/data/models/detail_comic_model.dart';
import 'package:maca/presentation/pages/collection/collection_page.dart';
import 'package:maca/presentation/pages/detail/detail_page.dart';
import 'package:maca/presentation/providers/detail_provider.dart';
import 'package:maca/presentation/providers/download_provider.dart';
import 'package:maca/presentation/providers/library_provider.dart';

class MockDetailProvider extends DetailProvider {
  final DetailComicModel? mockDetail;

  MockDetailProvider({this.mockDetail});

  @override
  DetailComicModel? get detailComic => mockDetail;

  @override
  bool get isLoading => false;

  @override
  Future<void> fetchDetail(String url, {bool forceRefresh = false}) async {}

  @override
  Future<bool> isBookmarked(String link) async => false;
}

class MockLibraryProvider extends LibraryProvider {
  final List<ComicModel> mockBookmarks;

  MockLibraryProvider({this.mockBookmarks = const []});

  @override
  List<ComicModel> get bookmarks => mockBookmarks;

  @override
  List<ComicModel> get history => const [];

  @override
  Future<void> fetchBookmarks() async {}

  @override
  Future<void> fetchHistory() async {}

  @override
  Future<bool> isBookmarked(String link) async => false;
}

class MockDownloadProvider extends DownloadProvider {
  final Set<String> mockDownloadedUrls;

  MockDownloadProvider({this.mockDownloadedUrls = const {}}) : super(autoLoad: false);

  @override
  bool isChapterDownloaded(String chapterUrl) {
    return mockDownloadedUrls.contains(chapterUrl);
  }

  @override
  Set<String> get downloadedUrls => mockDownloadedUrls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CollectionPage Tests', () {
    testWidgets('renders TabBar with Tersimpan and Unduhan tabs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<LibraryProvider>(create: (_) => MockLibraryProvider()),
              ChangeNotifierProvider<DownloadProvider>(create: (_) => MockDownloadProvider()),
            ],
            child: const CollectionPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check AppBar title
      expect(find.text(AppStrings.navCollection), findsOneWidget);

      // Check Tabs exist
      expect(find.text(AppStrings.navBookmark), findsOneWidget);
      expect(find.text(AppStrings.navDownloads), findsOneWidget);

      // Default tab is Bookmark -> Empty state
      expect(find.text(AppStrings.noSavedComics), findsOneWidget);

      // Switch to Downloads tab
      await tester.tap(find.text(AppStrings.navDownloads));
      await tester.pumpAndSettle();

      // Downloads empty state
      expect(find.text(AppStrings.noDownloads), findsOneWidget);
    });

    testWidgets('initialTabIndex 1 opens directly to Unduhan tab', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<LibraryProvider>(create: (_) => MockLibraryProvider()),
              ChangeNotifierProvider<DownloadProvider>(create: (_) => MockDownloadProvider()),
            ],
            child: const CollectionPage(initialTabIndex: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Directly shows Downloads tab empty state
      expect(find.text(AppStrings.noDownloads), findsOneWidget);
    });
  });

  group('DetailPage Chapter Filter Tests', () {
    final sampleChapters = [
      ChapterModel(
        title: 'Chapter 10',
        link: 'https://example.com/chapter-10',
        releaseDate: '1 hari lalu',
      ),
      ChapterModel(
        title: 'Chapter 11',
        link: 'https://example.com/chapter-11',
        releaseDate: '2 jam lalu',
      ),
    ];

    final sampleDetail = DetailComicModel(
      comic: ComicModel(
        title: 'Solo Leveling',
        thumbUrl: 'https://example.com/thumb.jpg',
        link: 'https://example.com/comic/solo-leveling',
      ),
      status: 'Ongoing',
      type: 'Manhwa',
      format: 'Webtoon',
      description: 'Cerita hunter terlemah.',
      genres: ['Action', 'Fantasy'],
      chapters: sampleChapters,
    );

    testWidgets('renders filter pills and filters downloaded chapters properly', (tester) async {
      // Mock that only Chapter 11 is downloaded
      final mockDownload = MockDownloadProvider(
        mockDownloadedUrls: {'https://example.com/chapter-11'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<DetailProvider>(
                create: (_) => MockDetailProvider(mockDetail: sampleDetail),
              ),
              ChangeNotifierProvider<LibraryProvider>(
                create: (_) => MockLibraryProvider(),
              ),
              ChangeNotifierProvider<DownloadProvider>(
                create: (_) => mockDownload,
              ),
            ],
            child: const DetailPage(comicUrl: 'https://example.com/comic/solo-leveling'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Filter pills should be visible with counts
      expect(find.text('${AppStrings.filterAll} (2)'), findsWidgets);
      expect(find.text('${AppStrings.filterDownloaded} (1)'), findsWidgets);

      // Initially, "Semua" is active -> both chapters are rendered
      expect(find.text('Chapter 10'), findsOneWidget);
      expect(find.text('Chapter 11'), findsOneWidget);

      // Tap on "Terunduh (1)" filter pill
      await tester.tap(find.text('${AppStrings.filterDownloaded} (1)').first);
      await tester.pumpAndSettle();

      // Only Chapter 11 is shown, Chapter 10 is filtered out
      expect(find.text('Chapter 11'), findsOneWidget);
      expect(find.text('Chapter 10'), findsNothing);

      // Tap back to "Semua (2)"
      await tester.tap(find.text('${AppStrings.filterAll} (2)').first);
      await tester.pumpAndSettle();

      // Both chapters visible again
      expect(find.text('Chapter 10'), findsOneWidget);
      expect(find.text('Chapter 11'), findsOneWidget);
    });

    testWidgets('shows no downloaded chapters empty state when filter active with 0 downloads', (tester) async {
      // Mock 0 downloaded chapters
      final mockDownload = MockDownloadProvider(mockDownloadedUrls: {});

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<DetailProvider>(
                create: (_) => MockDetailProvider(mockDetail: sampleDetail),
              ),
              ChangeNotifierProvider<LibraryProvider>(
                create: (_) => MockLibraryProvider(),
              ),
              ChangeNotifierProvider<DownloadProvider>(
                create: (_) => mockDownload,
              ),
            ],
            child: const DetailPage(comicUrl: 'https://example.com/comic/solo-leveling'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Filter pill shows Terunduh (0)
      expect(find.text('${AppStrings.filterDownloaded} (0)'), findsWidgets);

      // Tap "Terunduh (0)"
      await tester.tap(find.text('${AppStrings.filterDownloaded} (0)').first);
      await tester.pumpAndSettle();

      // Empty state shown
      expect(find.text(AppStrings.noDownloadedChapters), findsOneWidget);
      expect(find.text(AppStrings.downloadHint), findsOneWidget);
    });
  });
}
