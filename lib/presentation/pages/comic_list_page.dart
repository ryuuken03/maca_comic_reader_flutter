import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/comic_model.dart';
import '../../data/models/genre_model.dart';
import '../providers/home_provider.dart';
import '../widgets/comic_card.dart';
import '../widgets/genre_chip.dart';
import '../widgets/search_input.dart';

class ComicListPage extends StatefulWidget {
  final String title;
  final String? preset;
  final String? type;

  const ComicListPage({
    Key? key,
    required this.title,
    this.preset,
    this.type,
  }) : super(key: key);

  @override
  _ComicListPageState createState() => _ComicListPageState();
}

class _ComicListPageState extends State<ComicListPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  List<String> _selectedGenreIds = [];
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _showFilterDialog() async {
    final provider = context.read<HomeProvider>();
    provider.fetchGenres();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<HomeProvider>(
          builder: (context, provider, child) {
            return AlertDialog(
              title: const Text('Filter Genre'),
              content: SizedBox(
                width: double.maxFinite,
                child: provider.genres.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Wrap(
                          spacing: 8.0,
                          children: provider.genres.map((genre) {
                            final isSelected = _selectedGenreIds.contains(genre.name.toString());
                            return GenreChip(
                              label: genre.name,
                              isSelected: isSelected,
                              onSelected: (bool selected) {
                                if (selected) {
                                  _selectedGenreIds.add(genre.name.toString());
                                } else {
                                  _selectedGenreIds.remove(genre.name.toString());
                                }
                                (context as Element).markNeedsBuild();
                              },
                            );
                          }).toList(),
                        ),
                      ),
              ),
              actions: [
                if(_selectedGenreIds.isNotEmpty)...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedGenreIds.clear();
                      });
                      Navigator.pop(context);
                      _fetchInitialData();
                    },
                    child: const Text('Clear', style: TextStyle(color: Colors.red)),
                  ),
                ],
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _fetchInitialData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDD644),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Filter'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchInitialData() async {
    _currentPage = 1;
    context.read<HomeProvider>().fetchDiscover(
      searchQuery: _searchQuery,
      genres: _selectedGenreIds,
      page: _currentPage,
      preset: widget.preset,
      type: widget.type,
    );
  }

  Future<void> _fetchMoreData() async {
    final provider = context.read<HomeProvider>();
    if (provider.isLoading || !provider.hasNextPage) return;

    _currentPage++;
    provider.fetchDiscover(
      searchQuery: _searchQuery,
      genres: _selectedGenreIds,
      page: _currentPage,
      preset: widget.preset,
      type: widget.type,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchInput(
              controller: _searchController,
              hintText: 'Cari komik...',
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _selectedGenreIds.isNotEmpty ? const Color(0xFFFDD644) : null,
                ),
                onPressed: _showFilterDialog,
              ),
              onClear: () {
                 setState(() {
                    _searchQuery = '';
                 });
                 FocusManager.instance.primaryFocus?.unfocus();
                 _fetchInitialData();
              },
              onSubmitted: (val) {
                 setState(() {
                    _searchQuery = val;
                 });
                 _fetchInitialData();
              },
            ),
          ),
        ),
      ),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.discoverComics.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.discoverComics.isEmpty) {
            return const Center(child: Text('Tidak ada komik ditemukan'));
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: provider.discoverComics.length,
                  itemBuilder: (context, index) {
                    return ComicCard(comic: provider.discoverComics[index]);
                  },
                ),
              ),
              if (provider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }
}
