import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/constants.dart';
import '../../providers/library_provider.dart';
import '../../widgets/comic_card.dart';
import '../../widgets/delete_confirmation_dialog.dart';
import '../../widgets/search_input.dart';

class CollectionBookmarkTab extends StatefulWidget {
  const CollectionBookmarkTab({super.key});

  @override
  State<CollectionBookmarkTab> createState() => _CollectionBookmarkTabState();
}

class _CollectionBookmarkTabState extends State<CollectionBookmarkTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final bookmarkList = provider.bookmarks.where((comic) {
      if (_searchQuery.isEmpty) return true;
      return comic.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        if (provider.bookmarks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchInput(
              controller: _searchController,
              hintText: AppStrings.searchSavedHint,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),
        Expanded(
          child: provider.bookmarks.isEmpty
              ? const Center(
                  child: Text(
                    AppStrings.noSavedComics,
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                )
              : bookmarkList.isEmpty
                  ? const Center(
                      child: Text(
                        AppStrings.noComicsFound,
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
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
                                  title: AppStrings.confirmDeleteSaved,
                                  content:
                                      'Apakah Anda yakin ingin menghapus "${comic.title}" dari daftar tersimpan?',
                                  onConfirm: () => context
                                      .read<LibraryProvider>()
                                      .removeBookmark(comic.link),
                                );
                              },
                            );
                          },
                          onTap: () {
                            if (comic.chapterLink != null &&
                                comic.chapterLink!.isNotEmpty) {
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
                    ),
        ),
      ],
    );
  }
}
