import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maca/core/constants/constants.dart';
import 'package:maca/data/models/chapter_model.dart';
import 'package:maca/data/models/comic_model.dart';
import 'package:maca/data/models/detail_comic_model.dart';
import 'package:maca/presentation/pages/detail/detail_page.dart';
import 'package:maca/presentation/providers/detail_provider.dart';
import 'package:maca/presentation/providers/library_provider.dart';

class TestDetailProvider extends DetailProvider {
  final DetailComicModel? mockDetail;

  TestDetailProvider({this.mockDetail});

  @override
  DetailComicModel? get detailComic => mockDetail;

  @override
  bool get isLoading => false;

  @override
  Future<void> fetchDetail(String url, {bool forceRefresh = false}) async {}

  @override
  Future<bool> isBookmarked(String link) async => false;
}

class TestLibraryProvider extends LibraryProvider {
  final List<ComicModel> mockBookmarks;

  TestLibraryProvider({this.mockBookmarks = const []});

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

void main() {
  group('ComicModel isHot and isRecommended tests', () {
    test('default isHot and isRecommended are false', () {
      final comic = ComicModel(
        title: 'Solo Leveling',
        thumbUrl: 'https://example.com/thumb.jpg',
        link: '/komik/solo-leveling',
      );
      expect(comic.isHot, isFalse);
      expect(comic.isRecommended, isFalse);
      expect(comic.isPinned, isFalse);
      expect(comic.toMap()['isHot'], equals(0));
      expect(comic.toMap()['isRecommended'], equals(0));
      expect(comic.toMap()['isPinned'], equals(0));
    });

    test('isHot and isRecommended true in constructor and serialization', () {
      final comic = ComicModel(
        title: 'Solo Leveling',
        thumbUrl: 'https://example.com/thumb.jpg',
        link: '/komik/solo-leveling',
        isPinned: true,
        isHot: true,
        isRecommended: true,
      );
      expect(comic.isPinned, isTrue);
      expect(comic.isHot, isTrue);
      expect(comic.isRecommended, isTrue);

      final map = comic.toMap();
      expect(map['isPinned'], equals(1));
      expect(map['isHot'], equals(1));
      expect(map['isRecommended'], equals(1));

      final fromMap = ComicModel.fromMap(map);
      expect(fromMap.isPinned, isTrue);
      expect(fromMap.isHot, isTrue);
      expect(fromMap.isRecommended, isTrue);

      final fromBoolMap = ComicModel.fromMap({
        'title': 'Solo Leveling',
        'thumbUrl': 'https://example.com/thumb.jpg',
        'link': '/komik/solo-leveling',
        'isPinned': true,
        'isHot': true,
        'isRecommended': true,
      });
      expect(fromBoolMap.isPinned, isTrue);
      expect(fromBoolMap.isHot, isTrue);
      expect(fromBoolMap.isRecommended, isTrue);
    });
  });

  group('DetailComicModel isPinned, isHot, isRecommended tests', () {
    test('inherits defaults from comic if not explicitly set', () {
      final comic = ComicModel(
        title: 'Tower of God',
        thumbUrl: '',
        link: '/komik/tower-of-god',
        isPinned: true,
        isHot: true,
        isRecommended: true,
      );

      final detail = DetailComicModel(
        comic: comic,
        description: 'A boy who was alone...',
        chapters: [],
      );

      expect(detail.isPinned, isTrue);
      expect(detail.isHot, isTrue);
      expect(detail.isRecommended, isTrue);
    });

    test('can be explicitly set in DetailComicModel constructor', () {
      final comic = ComicModel(
        title: 'Tower of God',
        thumbUrl: '',
        link: '/komik/tower-of-god',
      );

      final detail = DetailComicModel(
        comic: comic,
        description: 'A boy who was alone...',
        chapters: [],
        isPinned: true,
        isHot: true,
        isRecommended: true,
      );

      expect(detail.isPinned, isTrue);
      expect(detail.isHot, isTrue);
      expect(detail.isRecommended, isTrue);
    });
  });

  group('DetailPage Widget Tests for pin icon, Hot badge, and Rekomendasi badge', () {
    Widget buildTestWidget({
      required bool isPinned,
      required bool isHot,
      required bool isRecommended,
    }) {
      final comic = ComicModel(
        title: 'Omniscient Reader',
        thumbUrl: '',
        link: '/komik/orv',
        type: 'Manhwa',
        status: 'Ongoing',
        format: 'manhwa',
        isPinned: isPinned,
        isHot: isHot,
        isRecommended: isRecommended,
      );

      final detail = DetailComicModel(
        comic: comic,
        description: 'Only I know the end of this world.',
        chapters: [
          ChapterModel(title: 'Chapter 1', link: '/chapter/1', releaseDate: '1 hari lalu'),
        ],
        genres: ['Action', 'Fantasy'],
        isPinned: isPinned,
        isHot: isHot,
        isRecommended: isRecommended,
      );

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<DetailProvider>(
            create: (_) => TestDetailProvider(mockDetail: detail),
          ),
          ChangeNotifierProvider<LibraryProvider>(
            create: (_) => TestLibraryProvider(),
          ),
        ],
        child: const MaterialApp(
          home: DetailPage(comicUrl: '/komik/orv'),
        ),
      );
    }

    testWidgets('shows pin icon, Hot badge, and Rekomendasi badge when all true', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          isPinned: true,
          isHot: true,
          isRecommended: true,
        ),
      );
      await tester.pumpAndSettle();

      // Pin icon check
      final pinFinder = find.byIcon(Icons.push_pin_rounded);
      expect(pinFinder, findsOneWidget);
      final pinIcon = tester.widget<Icon>(pinFinder);
      expect(pinIcon.color, equals(AppConstants.primaryColor));

      // Hot badge check
      expect(find.text('HOT'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);

      // Rekomendasi badge check
      expect(find.text('REKOMENDASI'), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsOneWidget);
    });

    testWidgets('hides pin icon, Hot badge, and Rekomendasi badge when all false', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          isPinned: false,
          isHot: false,
          isRecommended: false,
        ),
      );
      await tester.pumpAndSettle();

      // Pin icon should not be found
      expect(find.byIcon(Icons.push_pin_rounded), findsNothing);

      // Hot badge should not be found
      expect(find.text('HOT'), findsNothing);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsNothing);

      // Rekomendasi badge should not be found
      expect(find.text('REKOMENDASI'), findsNothing);
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsNothing);
    });
  });
}
