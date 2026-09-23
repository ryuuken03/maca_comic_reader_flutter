import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maca/core/constants/app_strings.dart';
import 'package:maca/data/models/chapter_model.dart';
import 'package:maca/data/models/downloaded_chapter_model.dart';
import 'package:maca/presentation/pages/downloads_page.dart';
import 'package:maca/presentation/providers/download_provider.dart';
import 'package:maca/presentation/providers/library_provider.dart';
import 'package:maca/presentation/widgets/chapter_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fase 7 Download & Offline Mode Tests', () {
    test('DownloadedChapterModel serializes and deserializes accurately', () {
      final model = DownloadedChapterModel(
        id: 'solo-leveling_chap-1',
        comicId: 'solo-leveling',
        comicTitle: 'Solo Leveling',
        comicThumbUrl: 'https://example.com/thumb.jpg',
        chapterTitle: 'Chapter 1',
        chapterUrl: 'https://api.example.com/series/solo-leveling/chapters/1',
        localPath: '/data/user/0/com.maca.reader/downloads/solo-leveling/1',
        pageCount: 35,
        sizeBytes: 15420000,
        downloadedAt: 1727000000000,
      );

      final map = model.toMap();
      expect(map['id'], 'solo-leveling_chap-1');
      expect(map['comic_id'], 'solo-leveling');
      expect(map['comic_title'], 'Solo Leveling');
      expect(map['comic_thumb_url'], 'https://example.com/thumb.jpg');
      expect(map['chapter_title'], 'Chapter 1');
      expect(map['chapter_url'], 'https://api.example.com/series/solo-leveling/chapters/1');
      expect(map['local_path'], '/data/user/0/com.maca.reader/downloads/solo-leveling/1');
      expect(map['page_count'], 35);
      expect(map['size_bytes'], 15420000);
      expect(map['downloaded_at'], 1727000000000);

      final fromMap = DownloadedChapterModel.fromMap(map);
      expect(fromMap.id, model.id);
      expect(fromMap.comicId, model.comicId);
      expect(fromMap.comicTitle, model.comicTitle);
      expect(fromMap.comicThumbUrl, model.comicThumbUrl);
      expect(fromMap.chapterTitle, model.chapterTitle);
      expect(fromMap.chapterUrl, model.chapterUrl);
      expect(fromMap.localPath, model.localPath);
      expect(fromMap.pageCount, model.pageCount);
      expect(fromMap.sizeBytes, model.sizeBytes);
      expect(fromMap.downloadedAt, model.downloadedAt);
    });

    testWidgets('DownloadsPage displays empty state when no chapters are downloaded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => DownloadProvider(autoLoad: false)),
            ],
            child: const DownloadsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(AppStrings.navDownloads), findsOneWidget);
      expect(find.text(AppStrings.noDownloads), findsOneWidget);
    });

    testWidgets('ChapterTile displays download button and triggers download', (tester) async {
      final chapter = ChapterModel(
        title: 'Chapter 15',
        link: 'https://api.example.com/series/magic-emperor/chapters/15',
        releaseDate: '1 jam yang lalu',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => DownloadProvider(autoLoad: false)),
                ChangeNotifierProvider(create: (_) => LibraryProvider()),
              ],
              child: ChapterTile(
                chapter: chapter,
                comicUrl: 'https://example.com/series/magic-emperor',
                comicTitle: 'Magic Emperor',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Chapter 15'), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    });
  });
}
