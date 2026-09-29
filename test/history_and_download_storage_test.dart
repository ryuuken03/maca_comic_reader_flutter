import 'package:flutter_test/flutter_test.dart';
import 'package:maca/data/models/comic_model.dart';
import 'package:maca/data/models/downloaded_chapter_model.dart';

void main() {
  group('History Storage & Metadata Preservation Tests', () {
    test('Reading offline preserves existing metadata (type, status, format, badges)', () {
      final historyDb = <String, Map<String, dynamic>>{};

      void simulateSaveHistory(ComicModel comic) {
        if (comic.link.trim().isEmpty) return;

        final existing = historyDb[comic.link];
        String type = comic.type;
        String status = comic.status;
        String format = comic.format;
        int isPinned = comic.isPinned ? 1 : 0;
        int isHot = comic.isHot ? 1 : 0;
        int isRecommended = comic.isRecommended ? 1 : 0;

        if (existing != null) {
          if (type.isEmpty) type = (existing['type'] as String?) ?? '';
          if (status.isEmpty) status = (existing['status'] as String?) ?? '';
          if (format.isEmpty) format = (existing['format'] as String?) ?? '';
          if (isPinned == 0) isPinned = (existing['isPinned'] as int?) ?? 0;
          if (isHot == 0) isHot = (existing['isHot'] as int?) ?? 0;
          if (isRecommended == 0) isRecommended = (existing['isRecommended'] as int?) ?? 0;
        }

        final map = comic.toMap();
        map['type'] = type;
        map['status'] = status;
        map['format'] = format;
        map['isPinned'] = isPinned;
        map['isHot'] = isHot;
        map['isRecommended'] = isRecommended;
        map['updatedAt'] = DateTime.now().toIso8601String();

        historyDb[comic.link] = map;
      }

      // Step 1: Initial online read with full metadata
      final initialComic = ComicModel(
        title: 'Solo Leveling',
        thumbUrl: 'https://example.com/sl.jpg',
        link: 'https://v2.voratoon.com/series/solo-leveling',
        latestChapter: 'Chapter 1',
        chapterLink: 'https://v2.voratoon.com/series/solo-leveling/chapter-1',
        type: 'Manhwa',
        status: 'Completed',
        format: 'Color',
        isPinned: true,
        isHot: true,
      );
      simulateSaveHistory(initialComic);

      expect(historyDb[initialComic.link]!['type'], 'Manhwa');
      expect(historyDb[initialComic.link]!['status'], 'Completed');
      expect(historyDb[initialComic.link]!['isPinned'], 1);
      expect(historyDb[initialComic.link]!['isHot'], 1);

      // Step 2: User reads Chapter 2 offline (missing type, status, format, badges)
      final offlineComic = ComicModel(
        title: 'Solo Leveling',
        thumbUrl: 'https://example.com/sl.jpg',
        link: 'https://v2.voratoon.com/series/solo-leveling',
        latestChapter: 'Chapter 2',
        chapterLink: 'https://v2.voratoon.com/series/solo-leveling/chapter-2',
      );
      simulateSaveHistory(offlineComic);

      // Verify metadata is preserved and latest chapter is updated
      final updated = historyDb[initialComic.link]!;
      expect(updated['latestChapter'], 'Chapter 2');
      expect(updated['chapterLink'], 'https://v2.voratoon.com/series/solo-leveling/chapter-2');
      expect(updated['type'], 'Manhwa');
      expect(updated['status'], 'Completed');
      expect(updated['format'], 'Color');
      expect(updated['isPinned'], 1);
      expect(updated['isHot'], 1);
    });
  });

  group('Offline Chapter Navigation Tests', () {
    test('Offline chapters navigate in descending order of chapters', () {
      final offlineChaps = [
        DownloadedChapterModel(
          id: 'solo_chap-3',
          comicId: 'solo',
          comicTitle: 'Solo',
          chapterTitle: 'Chapter 3',
          chapterUrl: 'https://api.example.com/series/solo/3',
          localPath: 'solo/3',
          pageCount: 20,
          downloadedAt: 3000,
        ),
        DownloadedChapterModel(
          id: 'solo_chap-2',
          comicId: 'solo',
          comicTitle: 'Solo',
          chapterTitle: 'Chapter 2',
          chapterUrl: 'https://api.example.com/series/solo/2',
          localPath: 'solo/2',
          pageCount: 20,
          downloadedAt: 2000,
        ),
        DownloadedChapterModel(
          id: 'solo_chap-1',
          comicId: 'solo',
          comicTitle: 'Solo',
          chapterTitle: 'Chapter 1',
          chapterUrl: 'https://api.example.com/series/solo/1',
          localPath: 'solo/1',
          pageCount: 20,
          downloadedAt: 1000,
        ),
      ];

      // Current chapter is Chapter 2
      final currentUrl = 'https://api.example.com/series/solo/2';
      final currentIndex = offlineChaps.indexWhere((c) => c.chapterUrl == currentUrl);
      expect(currentIndex, 1);

      String? nextChapterUrl;
      String? prevChapterUrl;

      if (currentIndex > 0) {
        nextChapterUrl = offlineChaps[currentIndex - 1].chapterUrl;
      }
      if (currentIndex < offlineChaps.length - 1) {
        prevChapterUrl = offlineChaps[currentIndex + 1].chapterUrl;
      }

      // Next chapter should be Chapter 3
      expect(nextChapterUrl, 'https://api.example.com/series/solo/3');
      // Previous chapter should be Chapter 1
      expect(prevChapterUrl, 'https://api.example.com/series/solo/1');
    });
  });
}
