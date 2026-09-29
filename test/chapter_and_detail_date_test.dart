import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maca/core/constants/app_strings.dart';
import 'package:maca/data/models/chapter_model.dart';
import 'package:maca/data/models/comic_model.dart';
import 'package:maca/data/models/detail_comic_model.dart';
import 'package:maca/presentation/pages/detail/detail_page.dart';
import 'package:maca/presentation/providers/detail_provider.dart';
import 'package:maca/presentation/providers/library_provider.dart';
import 'package:maca/presentation/providers/download_provider.dart';
import 'package:maca/presentation/widgets/chapter_tile.dart';

class MockDetailProvider extends DetailProvider {
  final DetailComicModel mockDetail;

  MockDetailProvider(this.mockDetail);

  @override
  DetailComicModel? get detailComic => mockDetail;

  @override
  bool get isLoading => false;

  @override
  Future<void> fetchDetail(String url, {bool forceRefresh = false}) async {}
}

class MockLibraryProvider extends LibraryProvider {
  @override
  List<ComicModel> get bookmarks => const [];

  @override
  List<ComicModel> get history => const [];

  @override
  Future<void> fetchBookmarks() async {}

  @override
  Future<void> fetchHistory() async {}

  @override
  bool isComicBookmarked(String link) => false;

  @override
  bool isChapterBookmarked(String comicUrl, String chapterLink) => false;
}

void main() {
  group('ChapterModel and DetailComicModel Date Tests', () {
    test('ChapterModel falls back to createdAt if updatedAt is null', () {
      final ch = ChapterModel(
        title: 'Chapter 1',
        link: '/chapter/1',
        createdAt: '2 jam lalu',
      );
      expect(ch.displayDate, equals('2 jam lalu'));
    });

    test('ChapterModel prioritizes updatedAt over createdAt', () {
      final ch = ChapterModel(
        title: 'Chapter 2',
        link: '/chapter/2',
        updatedAt: '1 jam lalu',
        createdAt: '5 jam lalu',
      );
      expect(ch.displayDate, equals('1 jam lalu'));
    });

    test('DetailComicModel displayDate resolves from comic or chapters', () {
      final comic = ComicModel(
        title: 'Komik Keren',
        thumbUrl: '',
        link: '/komik/keren',
        updatedAt: '3 hari lalu',
      );
      final detail = DetailComicModel(
        comic: comic,
        description: 'Deskripsi',
        chapters: [],
      );
      expect(detail.displayDate, equals('3 hari lalu'));
    });
  });

  group('ChapterTile Date Subtitle Widget Tests', () {
    testWidgets('ChapterTile displays formatted date subtitle', (tester) async {
      final chapter = ChapterModel(
        title: 'Chapter 10',
        link: '/chapter/10',
        updatedAt: '4 jam lalu',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<LibraryProvider>(create: (_) => MockLibraryProvider()),
                ChangeNotifierProvider<DownloadProvider?>.value(value: null),
              ],
              child: ChapterTile(
                chapter: chapter,
                comicUrl: '/komik/keren',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Chapter 10'), findsOneWidget);
      expect(find.text('4 jam lalu'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('4 jam lalu'));
      expect(textWidget.style?.fontSize, equals(11));
      expect(textWidget.style?.color, equals(Colors.white70));
      expect(textWidget.style?.fontWeight, equals(FontWeight.w500));
    });
  });

  group('DetailPage Chapter & Date Header Subtitle Tests', () {
    testWidgets('DetailPage renders latest chapter and updated time subtitle', (tester) async {
      final comic = ComicModel(
        title: 'Komik Mantap',
        thumbUrl: '',
        link: '/komik/mantap',
        latestChapter: 'Chapter 25',
        updatedAt: '1 hari lalu',
      );

      final detail = DetailComicModel(
        comic: comic,
        description: 'Sinopsis mantap',
        chapters: [
          ChapterModel(title: 'Chapter 25', link: '/chapter/25', updatedAt: '1 hari lalu'),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DetailProvider>(create: (_) => MockDetailProvider(detail)),
            ChangeNotifierProvider<LibraryProvider>(create: (_) => MockLibraryProvider()),
            ChangeNotifierProvider<DownloadProvider?>.value(value: null),
          ],
          child: const MaterialApp(
            home: DetailPage(comicUrl: '/komik/mantap'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chapter 25 • 1 hari lalu'), findsOneWidget);
    });
  });

  group('DetailPage CTA Button Priority Tests', () {
    final detail = DetailComicModel(
      comic: ComicModel(
        title: 'Solo Leveling',
        thumbUrl: '',
        link: '/komik/solo-leveling',
      ),
      description: 'Sinopsis',
      chapters: [
        ChapterModel(title: 'Chapter 20', link: '/chapter/20'),
        ChapterModel(title: 'Chapter 5', link: '/chapter/5'),
        ChapterModel(title: 'Chapter 1', link: '/chapter/1'),
      ],
    );

    testWidgets('CTA button prioritizes Bookmark over History', (tester) async {
      final mockLibrary = MockLibraryProviderWithData(
        bookmarks: [
          ComicModel(
            title: 'Solo Leveling',
            thumbUrl: '',
            link: '/komik/solo-leveling',
            latestChapter: 'Chapter 20',
            chapterLink: '/chapter/20',
          ),
        ],
        history: [
          ComicModel(
            title: 'Solo Leveling',
            thumbUrl: '',
            link: '/komik/solo-leveling',
            latestChapter: 'Chapter 5',
            chapterLink: '/chapter/5',
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DetailProvider>(create: (_) => MockDetailProvider(detail)),
            ChangeNotifierProvider<LibraryProvider>(create: (_) => mockLibrary),
            ChangeNotifierProvider<DownloadProvider?>.value(value: null),
          ],
          child: const MaterialApp(
            home: DetailPage(comicUrl: '/komik/solo-leveling'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bookmark is Chapter 20, History is Chapter 5 -> Must show Chapter 20
      expect(find.text('${AppStrings.readContinue} (Chapter 20)'), findsOneWidget);
      expect(find.text('${AppStrings.readContinue} (Chapter 5)'), findsNothing);
    });

    testWidgets('CTA button uses History if no Bookmark exists', (tester) async {
      final mockLibrary = MockLibraryProviderWithData(
        bookmarks: [],
        history: [
          ComicModel(
            title: 'Solo Leveling',
            thumbUrl: '',
            link: '/komik/solo-leveling',
            latestChapter: 'Chapter 5',
            chapterLink: '/chapter/5',
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DetailProvider>(create: (_) => MockDetailProvider(detail)),
            ChangeNotifierProvider<LibraryProvider>(create: (_) => mockLibrary),
            ChangeNotifierProvider<DownloadProvider?>.value(value: null),
          ],
          child: const MaterialApp(
            home: DetailPage(comicUrl: '/komik/solo-leveling'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('${AppStrings.readContinue} (Chapter 5)'), findsOneWidget);
    });

    testWidgets('CTA button uses first chapter if neither Bookmark nor History exists', (tester) async {
      final mockLibrary = MockLibraryProviderWithData(
        bookmarks: [],
        history: [],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DetailProvider>(create: (_) => MockDetailProvider(detail)),
            ChangeNotifierProvider<LibraryProvider>(create: (_) => mockLibrary),
            ChangeNotifierProvider<DownloadProvider?>.value(value: null),
          ],
          child: const MaterialApp(
            home: DetailPage(comicUrl: '/komik/solo-leveling'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // detail.chapters.last is Chapter 1
      expect(find.text('Mulai Baca: Chapter 1'), findsOneWidget);
    });
  });
}

class MockLibraryProviderWithData extends LibraryProvider {
  final List<ComicModel> _mockBookmarks;
  final List<ComicModel> _mockHistory;

  MockLibraryProviderWithData({
    List<ComicModel> bookmarks = const [],
    List<ComicModel> history = const [],
  })  : _mockBookmarks = bookmarks,
        _mockHistory = history;

  @override
  List<ComicModel> get bookmarks => _mockBookmarks;

  @override
  List<ComicModel> get history => _mockHistory;

  @override
  Future<void> fetchBookmarks() async {}

  @override
  Future<void> fetchHistory() async {}

  @override
  bool isComicBookmarked(String link) => _mockBookmarks.any((b) => b.link == link);

  @override
  bool isChapterBookmarked(String comicUrl, String chapterLink) =>
      _mockBookmarks.any((b) => b.link == comicUrl && b.chapterLink == chapterLink);
}

