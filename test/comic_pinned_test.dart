import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maca/core/constants/constants.dart';
import 'package:maca/data/models/comic_model.dart';
import 'package:maca/presentation/widgets/comic_card.dart';

void main() {
  group('ComicModel isPinned tests', () {
    test('default isPinned is false', () {
      final comic = ComicModel(
        title: 'Solo Leveling',
        thumbUrl: 'https://example.com/thumb.jpg',
        link: '/komik/solo-leveling',
      );
      expect(comic.isPinned, isFalse);
      expect(comic.toMap()['isPinned'], equals(0));
    });

    test('isPinned true in constructor and serialization', () {
      final comic = ComicModel(
        title: 'Solo Leveling',
        thumbUrl: 'https://example.com/thumb.jpg',
        link: '/komik/solo-leveling',
        isPinned: true,
      );
      expect(comic.isPinned, isTrue);
      expect(comic.toMap()['isPinned'], equals(1));

      final fromMap = ComicModel.fromMap(comic.toMap());
      expect(fromMap.isPinned, isTrue);

      final fromBooleanMap = ComicModel.fromMap({
        'title': 'Solo Leveling',
        'thumbUrl': 'https://example.com/thumb.jpg',
        'link': '/komik/solo-leveling',
        'isPinned': true,
      });
      expect(fromBooleanMap.isPinned, isTrue);
    });
  });

  group('ComicCard isPinned widget test', () {
    testWidgets('shows yellow pin icon when isPinned is true', (tester) async {
      final pinnedComic = ComicModel(
        title: 'Pinned Manga',
        thumbUrl: '',
        link: '/komik/pinned-manga',
        isPinned: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicCard(comic: pinnedComic),
          ),
        ),
      );

      final pinIconFinder = find.byIcon(Icons.push_pin_rounded);
      expect(pinIconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(pinIconFinder);
      expect(iconWidget.color, equals(AppConstants.primaryColor));
    });

    testWidgets('does not show pin icon when isPinned is false', (tester) async {
      final unpinnedComic = ComicModel(
        title: 'Normal Manga',
        thumbUrl: '',
        link: '/komik/normal-manga',
        isPinned: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicCard(comic: unpinnedComic),
          ),
        ),
      );

      final pinIconFinder = find.byIcon(Icons.push_pin_rounded);
      expect(pinIconFinder, findsNothing);
    });

    testWidgets('displays latestChapter on ComicCard correctly', (tester) async {
      final comicWithChapter = ComicModel(
        title: 'Solo Leveling',
        thumbUrl: '',
        link: '/komik/solo-leveling',
        latestChapter: '179',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicCard(comic: comicWithChapter),
          ),
        ),
      );

      expect(find.text('Ch. 179'), findsOneWidget);
    });

    testWidgets('displays OneShot without prepending Ch.', (tester) async {
      final oneShotComic = ComicModel(
        title: 'Look Back',
        thumbUrl: '',
        link: '/komik/look-back',
        latestChapter: 'OneShot',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicCard(comic: oneShotComic),
          ),
        ),
      );

      expect(find.text('OneShot'), findsOneWidget);
    });

    testWidgets('displays latestChapter and updatedAt together on ComicCard', (tester) async {
      final comicWithTime = ComicModel(
        title: 'Solo Leveling',
        thumbUrl: '',
        link: '/komik/solo-leveling',
        latestChapter: '179',
        updatedAt: '2 jam lalu',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComicCard(comic: comicWithTime),
          ),
        ),
      );

      expect(find.text('Ch. 179 • 2 jam lalu'), findsOneWidget);
    });
  });
}
