import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:maca/core/constants/app_strings.dart';
import 'package:maca/core/utils/cache_manager.dart';
import 'package:maca/presentation/pages/settings_page.dart';
import 'package:maca/presentation/providers/settings_provider.dart';

import 'package:maca/presentation/providers/download_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 6 Settings & Storage Tests', () {
    test('StorageHelper.formatBytes formats byte values accurately and concisely', () {
      expect(StorageHelper.formatBytes(0), '0 B');
      expect(StorageHelper.formatBytes(-100), '0 B');
      expect(StorageHelper.formatBytes(512), '512 B');
      expect(StorageHelper.formatBytes(1024), '1.0 KB');
      expect(StorageHelper.formatBytes(1536), '1.5 KB');
      expect(StorageHelper.formatBytes(1024 * 1024 * 12), '12.0 MB');
      expect(StorageHelper.formatBytes(1024 * 1024 * 1024 * 3), '3.0 GB');
    });

    test('StorageHelper.getDirectorySizeBytes calculates directory size accurately', () async {
      final tempDir = await Directory.systemTemp.createTemp('maca_test_cache_');
      try {
        final file1 = File('${tempDir.path}/test1.bin');
        final file2 = File('${tempDir.path}/test2.bin');
        await file1.writeAsBytes(List.filled(100, 1));
        await file2.writeAsBytes(List.filled(250, 2));

        final totalBytes = await StorageHelper.getDirectorySizeBytes(tempDir);
        expect(totalBytes, 350);

        // Test physical deletion
        await StorageHelper.deleteDirectoryContents(tempDir);
        final emptyBytes = await StorageHelper.getDirectorySizeBytes(tempDir);
        expect(emptyBytes, 0);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('StorageHelper.clearReaderCacheOnDisk clears physical files in reader directory', () async {
      final tempDir = await Directory.systemTemp.createTemp('maca_reader_root_');
      try {
        final readerDir = Directory('${tempDir.path}/${CustomCacheManager.key}');
        await readerDir.create(recursive: true);
        final file = File('${readerDir.path}/sample.jpg');
        await file.writeAsBytes(List.filled(5000, 9));

        expect(await StorageHelper.getReaderCacheSizeBytes(baseDir: tempDir), 5000);

        await StorageHelper.clearReaderCacheOnDisk(baseDir: tempDir);
        expect(await StorageHelper.getReaderCacheSizeBytes(baseDir: tempDir), 0);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    testWidgets('SettingsPage adheres to rules: no subtitles, no non-substantive icons, uses AppStrings', (tester) async {
      final settingsProvider = SettingsProvider(autoLoad: false);

      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
              ChangeNotifierProvider<DownloadProvider>(
                create: (_) => DownloadProvider(autoLoad: false),
              ),
            ],
            child: const SettingsPage(),
          ),
        ),
      );

      // Verify section titles rendered from AppStrings
      expect(find.text(AppStrings.navSettings), findsOneWidget);
      expect(find.text(AppStrings.sectionReading), findsOneWidget);
      expect(find.text(AppStrings.sectionStorage), findsOneWidget);

      // Verify option titles rendered from AppStrings
      expect(find.text(AppStrings.readerMode), findsOneWidget);
      expect(find.text(AppStrings.mangaDirection), findsOneWidget);
      expect(find.text(AppStrings.portraitLock), findsOneWidget);
      expect(find.text(AppStrings.comicDownloads), findsOneWidget);
      expect(find.text(AppStrings.coverCache), findsOneWidget);
      expect(find.text(AppStrings.readerCache), findsOneWidget);
      expect(find.text(AppStrings.totalCache), findsOneWidget);

      // Verify Rule: NO ListTile has subtitles
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(listTiles.isNotEmpty, isTrue);
      for (final tile in listTiles) {
        expect(tile.subtitle, isNull, reason: 'Rule violation: ListTile must not contain subtitles');
      }

      // Verify Rule: NO ListTile has decorative leading icons
      for (final tile in listTiles) {
        expect(tile.leading, isNull, reason: 'Rule violation: ListTile must not contain decorative leading icons');
      }

      // Verify interactive controls exist (Switch, SegmentedButton, TextButton)
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(SegmentedButton<String>), findsNWidgets(2));
      expect(find.widgetWithText(TextButton, AppStrings.actionDelete), findsNWidgets(2));
      expect(find.widgetWithText(TextButton, AppStrings.actionDeleteAll), findsOneWidget);
    });
  });
}
