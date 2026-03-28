import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/comic_provider.dart';
import '../widgets/comic_card.dart';

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
      context.read<ComicProvider>().fetchBookmarks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Komik Tersimpan'),
        actions: [
          Consumer<ComicProvider>(
            builder: (context, provider, _) {
              if (provider.bookmarks.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Hapus Semua Tersimpan',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Hapus Tersimpan'),
                        content: const Text('Apakah Anda yakin ingin menghapus semua komik tersimpan?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              context.read<ComicProvider>().clearBookmarks();
                              Navigator.of(dialogContext).pop();
                            },
                            child: const Text('Ya, Hapus', style: TextStyle(color: Colors.red)),
                          ),
                        ],
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                 hintText: 'Cari komik tersimpan...',
                 prefixIcon: const Icon(Icons.search),
                 suffixIcon: _searchQuery.isNotEmpty ? IconButton(
                   icon: const Icon(Icons.clear),
                   onPressed: () {
                      _searchController.clear();
                      setState(() {
                         _searchQuery = '';
                      });
                   },
                 ) : null,
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(8.0),
                 ),
                 filled: true,
                 fillColor: const Color(0xFF2C2C2C),
                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onChanged: (val) {
                 setState(() {
                    _searchQuery = val;
                 });
              },
            ),
          ),
        ),
      ),
      body: Consumer<ComicProvider>(
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: bookmarkList.length,
            itemBuilder: (context, index) {
              final comic = bookmarkList[index];
              return ComicCard(
                comic: comic,
                onTap: () {
                  if (comic.chapterLink != null && comic.chapterLink!.isNotEmpty) {
                    context.push('/reader', extra: comic.chapterLink!);
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
