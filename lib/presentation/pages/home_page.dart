import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/comic_provider.dart';
import '../widgets/comic_card.dart';
import 'bookmark_page.dart';
import 'history_page.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _HomeContent(),
    const HistoryPage(),
    const BookmarkPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Tersimpan'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent({Key? key}) : super(key: key);

  @override
  __HomeContentState createState() => __HomeContentState();
}

class __HomeContentState extends State<_HomeContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComicProvider>().fetchHomeComics();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<ComicProvider>().fetchMoreHomeComics();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maca Komik'),
      ),
      body: Consumer<ComicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.homeComics.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.homeComics.isEmpty) {
            return const Center(child: Text('Tidak ada komik ditemukan'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchHomeComics(),
            child: Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: provider.homeComics.length,
                    itemBuilder: (context, index) {
                      return ComicCard(comic: provider.homeComics[index]);
                    },
                  ),
                ),
                if (provider.isFetchingMore)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
