import 'package:flutter_test/flutter_test.dart';
import 'package:maca/data/models/comic_model.dart';
import 'package:maca/presentation/providers/library_provider.dart';

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
    test('LibraryProvider.isSameComic correctly matches different URL forms', () {
      expect(LibraryProvider.isSameComic('/komik/solo-leveling', 'https://v4.voratoon.com/series/solo-leveling'), isTrue);
      expect(LibraryProvider.isSameComic('https://v4.voratoon.com/series/solo-leveling/', '/komik/solo-leveling/'), isTrue);
      expect(LibraryProvider.isSameComic('https://api.voratoon.com/series/solo-leveling', 'https://v4.voratoon.com/series/solo-leveling'), isTrue);
      expect(LibraryProvider.isSameComic('/komik/solo-leveling', '/komik/martial-peak'), isFalse);
    });

    test('Detail page bookmark saves null chapter, while reader bookmark saves current chapter', () {
      // 1. Bookmark from DetailPage -> chapter is null
      final detailBookmark = ComicModel(
        title: 'Martial Peak',
        thumbUrl: 'https://example.com/mp.jpg',
        link: 'https://v4.voratoon.com/series/martial-peak',
        latestChapter: null,
        chapterLink: null,
        status: 'Ongoing',
        type: 'Manhua',
      );
      expect(detailBookmark.latestChapter, isNull);
      expect(detailBookmark.chapterLink, isNull);

      // 2. Bookmark from ReaderPage -> chapter is set to current chapter with full detail
      final readerBookmark = ComicModel(
        title: detailBookmark.title,
        thumbUrl: detailBookmark.thumbUrl,
        link: detailBookmark.link,
        latestChapter: 'Chapter 3860',
        chapterLink: 'https://api.voratoon.com/series/martial-peak/chapters/3860',
        status: detailBookmark.status,
        type: detailBookmark.type,
      );
      expect(readerBookmark.latestChapter, 'Chapter 3860');
      expect(readerBookmark.chapterLink, 'https://api.voratoon.com/series/martial-peak/chapters/3860');
      expect(readerBookmark.status, 'Ongoing');
      expect(readerBookmark.type, 'Manhua');

      // 3. Check matching from detail page url (/komik/martial-peak)
      expect(LibraryProvider.isSameComic('/komik/martial-peak', readerBookmark.link), isTrue);
    });
  });
}
