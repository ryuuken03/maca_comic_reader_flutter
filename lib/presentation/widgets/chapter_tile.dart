import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../data/models/chapter_model.dart';
import '../providers/download_provider.dart';
import '../providers/library_provider.dart';
import 'delete_confirmation_dialog.dart';

class ChapterTile extends StatelessWidget {
  final ChapterModel chapter;
  final String comicUrl;
  final String comicTitle;
  final String comicThumbUrl;

  const ChapterTile({
    super.key,
    required this.chapter,
    required this.comicUrl,
    this.comicTitle = '',
    this.comicThumbUrl = '',
  });

  Widget _buildDownloadButton(BuildContext context) {
    final downloadProvider = Provider.of<DownloadProvider?>(context);
    final isDownloaded = downloadProvider?.isChapterDownloaded(chapter.link) ?? false;
    final isDownloading = downloadProvider?.isChapterDownloading(chapter.link) ?? false;
    final progress = downloadProvider?.getDownloadProgress(chapter.link) ?? 0.0;

    final comicSlug = comicUrl.contains('/series/')
        ? comicUrl.split('/series/').last.split('/').firstWhere((e) => e.isNotEmpty, orElse: () => 'comic')
        : 'comic';

    if (isDownloading) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 2.2,
              color: const Color(0xFFFDD644),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              iconSize: 14,
              icon: const Icon(Icons.close, color: Colors.white70),
              tooltip: AppStrings.actionCancel,
              onPressed: () => downloadProvider?.cancelDownload(chapter.link),
            ),
          ],
        ),
      );
    }

    if (isDownloaded) {
      return IconButton(
        icon: const Icon(Icons.offline_pin_rounded, color: Color(0xFFFDD644), size: 22),
        tooltip: AppStrings.downloaded,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => DeleteConfirmationDialog(
              title: AppStrings.confirmDeleteDownload,
              content: 'Hapus unduhan "${chapter.title}"?',
              onConfirm: () => downloadProvider?.deleteDownloadedChapter(chapter.link),
            ),
          );
        },
      );
    }

    return IconButton(
      icon: const Icon(Icons.file_download_outlined, size: 22, color: Colors.white60),
      tooltip: AppStrings.actionDownload,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: () {
        downloadProvider?.downloadChapter(
          comicId: comicSlug,
          comicTitle: comicTitle.isNotEmpty ? comicTitle : 'Komik',
          comicThumbUrl: comicThumbUrl,
          chapterTitle: chapter.title,
          chapterUrl: chapter.link,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final actIndexStr = chapter.link.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');

    return ListTile(
      title: Text(chapter.title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDownloadButton(context),
          const SizedBox(width: 4),
          Consumer<LibraryProvider>(
            builder: (context, library, child) {
              return FutureBuilder<bool>(
                future: library.isBookmarkedReader(comicUrl, actIndexStr),
                builder: (context, snapshot) {
                  final isBookmarked = snapshot.data ?? false;
                  if (!isBookmarked) return const SizedBox.shrink();
                  return const Padding(
                    padding: EdgeInsets.only(right: 4.0),
                    child: Icon(Icons.bookmark, color: Color(0xFFFDD644), size: 18),
                  );
                },
              );
            },
          ),
        ],
      ),
      onTap: () {
        context.push('/reader', extra: {
          'chapterUrl': chapter.link,
          'fromDetail': true,
        });
      },
    );
  }
}
