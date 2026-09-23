import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../providers/library_provider.dart';
import '../../core/constants/constants.dart';
import '../widgets/comic_card.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/search_input.dart';

class BookmarkPage extends StatefulWidget {
  const BookmarkPage({Key? key}) : super(key: key);

  @override
  _BookmarkPageState createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LibraryProvider>().fetchBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komik Tersimpan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_outlined),
            tooltip: AppStrings.navDownloads,
            onPressed: () => context.push('/downloads'),
          ),
          Consumer<LibraryProvider>(
            builder: (context, provider, _) {
              if (provider.bookmarks.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Hapus Semua Tersimpan',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return DeleteConfirmationDialog(
                        title: 'Hapus Tersimpan',
                        content: 'Apakah Anda yakin ingin menghapus semua komik tersimpan?',
                        onConfirm: () => context.read<LibraryProvider>().clearBookmarks(),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchInput(
              controller: _searchController,
              hintText: 'Cari komik tersimpan...',
              onChanged: (val) {
                 setState(() {
                    _searchQuery = val;
                 });
              },
            ),
          ),
        ),
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, provider, child) {
          final bookmarkList = provider.bookmarks.where((comic) {
             return comic.title.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          if (provider.bookmarks.isEmpty) {
            return const Center(child: Text('Belum ada komik yang tersimpan'));
          }

          if (bookmarkList.isEmpty) {
            return const Center(child: Text('Tidak ditemukan'));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 0.68,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: bookmarkList.length,
            itemBuilder: (context, index) {
              final comic = bookmarkList[index];
              return ComicCard(
                comic: comic,
                enableRetry: index < 20,
                httpHeaders: AppConstants.imageHeaders,
                onDelete: () {
                   showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return DeleteConfirmationDialog(
                        title: 'Hapus Tersimpan',
                        content: 'Apakah Anda yakin ingin menghapus "${comic.title}" dari daftar tersimpan?',
                        onConfirm: () => context.read<LibraryProvider>().removeBookmark(comic.link),
                      );
                    },
                  );
                },
                onTap: () {
                  if (comic.chapterLink != null && comic.chapterLink!.isNotEmpty) {
                    context.push('/reader', extra: {
                      'chapterUrl': comic.chapterLink!,
                      'fromDetail': false,
                    });
                  } else {
                    context.push('/detail', extra: comic.link);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

