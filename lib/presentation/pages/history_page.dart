import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/comic_provider.dart';
import '../widgets/comic_card.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/search_input.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
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
      context.read<ComicProvider>().fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Baca'),
        actions: [
          Consumer<ComicProvider>(
            builder: (context, provider, _) {
              if (provider.history.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Hapus Semua Riwayat',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return DeleteConfirmationDialog(
                        title: 'Hapus Riwayat',
                        content: 'Apakah Anda yakin ingin menghapus semua riwayat?',
                        onConfirm: () => context.read<ComicProvider>().clearHistory(),
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
              hintText: 'Cari riwayat komik...',
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
          final historyList = provider.history.where((comic) {
             return comic.title.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          if (provider.history.isEmpty) {
            return const Center(child: Text('Riwayat masih kosong'));
          }

          if (historyList.isEmpty) {
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
            itemCount: historyList.length,
            itemBuilder: (context, index) {
              final comic = historyList[index];
              return ComicCard(
                comic: comic,
                onDelete: () {
                   showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return DeleteConfirmationDialog(
                        title: 'Hapus Riwayat',
                        content: 'Apakah Anda yakin ingin menghapus "${comic.title}" dari riwayat?',
                        onConfirm: () => context.read<ComicProvider>().removeHistory(comic.link),
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
