import 'package:flutter/material.dart';
import '../../data/models/comic_model.dart';
import '../../data/models/genre_model.dart';
import '../../data/services/scraper_service.dart';
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
  final ScraperService _scraperService = ScraperService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<ComicModel> _comics = [];
  String _searchQuery = '';
  List<String> _selectedGenreIds = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  int _currentPage = 1;
  bool _hasNextPage = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _showFilterDialog() async {
    List<GenreModel> allGenres = [];
    bool isDialogLoading = true;

    // Fetch genres
    try {
      allGenres = await _scraperService.getGenres();
    } catch (e) {
      debugPrint("Error fetching genres for dialog: $e");
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Filter Genre'),
              content: SizedBox(
                width: double.maxFinite,
                child: allGenres.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Wrap(
                          spacing: 8.0,
                          children: allGenres.map((genre) {
                            final isSelected = _selectedGenreIds.contains(genre.name.toString());
                            return GenreChip(
                              label: genre.name,
                              isSelected: isSelected,
                              onSelected: (bool selected) {
                                setDialogState(() {
                                  if (selected) {
                                    _selectedGenreIds.add(genre.name.toString());
                                  } else {
                                    _selectedGenreIds.remove(genre.name.toString());
                                  }
                                });
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
                    surfaceTintColor: const Color(0xFFFDD644),
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
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasNextPage = true;
      _comics.clear();
    });

    try {
      var results = await _scraperService.fetchSeries(
        searchQuery: _searchQuery,
        genres: _selectedGenreIds,
        page: _currentPage,
        preset: widget.preset ?? '',
        type: widget.type,
        take: 20,
      );
      // if(widget.type == null && widget.preset == 'rilisan_terbaru'){
      //
      //   var results = await _scraperService.fetchSeries(
      //     searchQuery: _searchQuery,
      //     genres: _selectedGenreIds,
      //     page: _currentPage,
      //     preset: widget.preset ?? '',
      //     type: widget.type,
      //     take: 20,
      //   );
      // }
      setState(() {
        _comics = results;
        if (results.isEmpty) {
          _hasNextPage = false;
        }
      });
    } catch (e) {
      debugPrint('Error fetching initial: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreData() async {
    if (_isFetchingMore || !_hasNextPage || _isLoading) return;

    setState(() {
      _isFetchingMore = true;
    });

    try {
      _currentPage++;
      final results = await _scraperService.fetchSeries(
        searchQuery: _searchQuery,
        genres: _selectedGenreIds,
        page: _currentPage,
        preset: widget.preset ?? '',
        type: widget.type,
        take: 20,
      );
      setState(() {
        if (results.isEmpty) {
          _hasNextPage = false;
        } else {
          _comics.addAll(results);
        }
      });
    } catch (e) {
      debugPrint('Error fetching more: $e');
      _currentPage--;
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingMore = false;
        });
      }
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _comics.isEmpty
              ? const Center(child: Text('Tidak ada komik ditemukan'))
              : Column(
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
                        itemCount: _comics.length,
                        itemBuilder: (context, index) {
                          return ComicCard(comic: _comics[index]);
                        },
                      ),
                    ),
                    if (_isFetchingMore)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
    );
  }
}
