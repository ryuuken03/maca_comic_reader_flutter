import 'package:flutter_test/flutter_test.dart';
import 'package:maca/data/models/comic_model.dart';

void main() {
  group('Bookmark Replacement Logic Tests', () {
    test('Saving bookmark with last chapter replaces old bookmark with the same detail url', () {
      final bookmarks = <String, ComicModel>{};

      void saveBookmark(ComicModel comic) {
        // Simulates DatabaseHelper.saveBookmark replacing by detail link
        bookmarks[comic.link] = comic;
      }

      // Step 1: Save from DetailPage (detail URL only, no chapter)
      final detailBookmark = ComicModel(
        title: 'Solo Leveling',
        thumbUrl: 'https://example.com/sl.jpg',
        link: 'https://v2.voratoon.com/series/solo-leveling',
        latestChapter: null,
        chapterLink: null,
      );
      saveBookmark(detailBookmark);

      expect(bookmarks.length, 1);
      expect(bookmarks[detailBookmark.link]!.chapterLink, isNull);
      expect(bookmarks[detailBookmark.link]!.latestChapter, isNull);

      // Step 2: Read Chapter 179 and bookmark
      final chapterBookmark = ComicModel(
        title: 'Solo Leveling',
        thumbUrl: 'https://example.com/sl.jpg',
        link: 'https://v2.voratoon.com/series/solo-leveling',
        latestChapter: 'chapter-179',
        chapterLink: 'https://v2.voratoon.com/series/solo-leveling/chapter-179/',
      );
      saveBookmark(chapterBookmark);

      // Verify old detail bookmark is replaced and now contains detail url + last chapter url
      expect(bookmarks.length, 1);
      expect(bookmarks[chapterBookmark.link]!.link, 'https://v2.voratoon.com/series/solo-leveling');
      expect(bookmarks[chapterBookmark.link]!.latestChapter, 'chapter-179');
      expect(bookmarks[chapterBookmark.link]!.chapterLink, 'https://v2.voratoon.com/series/solo-leveling/chapter-179/');
    });
  });
}
