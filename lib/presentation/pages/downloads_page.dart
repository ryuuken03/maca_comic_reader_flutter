import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/cache_manager.dart';
import '../../data/models/downloaded_chapter_model.dart';
import '../providers/download_provider.dart';
import '../widgets/delete_confirmation_dialog.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final chapters = downloadProvider.downloadedChapters;

    // Kelompokkan chapter berdasarkan comicId
    final Map<String, List<DownloadedChapterModel>> groupedComics = {};
    for (final chap in chapters) {
      groupedComics.putIfAbsent(chap.comicId, () => []).add(chap);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navDownloads),
        actions: [
          if (chapters.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: AppStrings.actionDeleteAll,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => DeleteConfirmationDialog(
                    title: AppStrings.confirmDeleteAllDownloads,
                    content: 'Apakah Anda yakin ingin menghapus semua komik yang diunduh?',
                    onConfirm: () => downloadProvider.clearAllDownloads(),
                  ),
                );
              },
            ),
        ],
      ),
      body: chapters.isEmpty
          ? const Center(
              child: Text(
                AppStrings.noDownloads,
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  itemCount: groupedComics.keys.length,
                  itemBuilder: (context, index) {
                    final comicId = groupedComics.keys.elementAt(index);
                    final comicChapters = groupedComics[comicId]!;
                    final firstChap = comicChapters.first;

                    int comicSizeBytes = 0;
                    for (final c in comicChapters) {
                      comicSizeBytes += c.sizeBytes;
                    }

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ExpansionTile(
                        shape: const Border(),
                        collapsedShape: const Border(),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 44,
                            height: 60,
                            child: firstChap.comicThumbUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: firstChap.comicThumbUrl,
                                    httpHeaders: AppConstants.imageHeaders,
                                    memCacheWidth: 350,
                                    maxWidthDiskCache: 600,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => const Icon(Icons.book, size: 28),
                                  )
                                : const Icon(Icons.book, size: 28),
                          ),
                        ),
                        title: Text(
                          firstChap.comicTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${comicChapters.length} Chapter • ${StorageHelper.formatBytes(comicSizeBytes)}',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          tooltip: 'Hapus komik ini',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => DeleteConfirmationDialog(
                                title: AppStrings.confirmDeleteComicDownloads,
                                content: 'Hapus seluruh chapter unduhan untuk "${firstChap.comicTitle}"?',
                                onConfirm: () => downloadProvider.deleteDownloadedChaptersByComic(comicId),
                              ),
                            );
                          },
                        ),
                        children: comicChapters.map((chap) {
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.only(left: 32, right: 16),
                            title: Text(
                              chap.chapterTitle,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              '${chap.pageCount} Hal • ${StorageHelper.formatBytes(chap.sizeBytes)}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Colors.white60),
                              tooltip: 'Hapus chapter',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => DeleteConfirmationDialog(
                                    title: AppStrings.confirmDeleteDownload,
                                    content: 'Hapus unduhan "${chap.chapterTitle}"?',
                                    onConfirm: () =>
                                        downloadProvider.deleteDownloadedChapter(chap.chapterUrl),
                                  ),
                                );
                              },
                            ),
                            onTap: () {
                              context.push('/reader', extra: {
                                'chapterUrl': chap.chapterUrl,
                                'fromDetail': true,
                              });
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}
