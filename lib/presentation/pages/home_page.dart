import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/comic_model.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ComicProvider>().fetchHomeComics();
    });
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String? preset, String? type}) {
    return InkWell(
      onTap: () {
        context.push('/list', extra: {'title': title, 'preset': preset, 'type': type});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Widget _buildLihatSemuaButton(BuildContext context, String title, {String? preset, String? type}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            context.push('/list', extra: {'title': title, 'preset': preset, 'type': type});
          },
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text('Lihat Semua'),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<ComicModel> comics) {
    if (comics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Tidak ada komik ditemukan')),
      );
    }
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: comics.length,
        itemBuilder: (context, index) {
          return SizedBox(
            width: 140,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ComicCard(comic: comics[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(List<ComicModel> comics) {
    if (comics.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Tidak ada komik ditemukan')),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: comics.length,
      itemBuilder: (context, index) {
        return ComicCard(comic: comics[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maca Komik'),
      ),
      body: Consumer<ComicProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.homeComics.isEmpty && provider.popularComics.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchHomeComics(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(context, 'Komik Popular', preset: 'popular_all'),
                  _buildHorizontalList(provider.popularComics),
                  _buildLihatSemuaButton(context, 'Komik Popular', preset: 'popular_all'),

                  const SizedBox(height: 16),
                  _buildSectionHeader(context, 'Proyek', type: 'project'),
                  _buildHorizontalList(provider.projectComics),
                  _buildLihatSemuaButton(context, 'Proyek', type: 'project'),

                  const SizedBox(height: 16),
                  _buildSectionHeader(context, 'Komik Terbaru', preset: 'rilisan_terbaru'),
                  _buildGrid(provider.homeComics),
                  _buildLihatSemuaButton(context, 'Komik Terbaru', preset: 'rilisan_terbaru'),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
