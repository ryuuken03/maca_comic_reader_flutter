import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/adaptive_utils.dart';
import '../providers/home_provider.dart';
import '../widgets/comic_card.dart';
import '../widgets/search_input.dart';
import '../widgets/genre_filter_dialog.dart';

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
  bool _showBackToTop = false;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchInitialData();
      }
    });
    _scrollController.addListener(_onScroll);
  }

  Future<void> _showFilterDialog() async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return GenreFilterDialog(
          initialSelectedGenreIds: _selectedGenreIds,
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedGenreIds = result;
      });
      _fetchInitialData();
    }
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() {
      _isInitialLoading = true;
    });
    _currentPage = 1;
    final take = getAdaptiveGridTake(context);
    final effectivePreset = _searchQuery.isNotEmpty ? null : widget.preset;
    try {
      await context.read<HomeProvider>().fetchDiscover(
        searchQuery: _searchQuery,
        genres: _selectedGenreIds,
        page: _currentPage,
        preset: effectivePreset,
        type: widget.type,
        take: take,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _fetchMoreData() async {
    final provider = context.read<HomeProvider>();
    if (provider.isLoading || !provider.hasNextPage) return;

    _currentPage++;
    final take = getAdaptiveGridTake(context);
    final effectivePreset = _searchQuery.isNotEmpty ? null : widget.preset;
    provider.fetchDiscover(
      searchQuery: _searchQuery,
      genres: _selectedGenreIds,
      page: _currentPage,
      preset: effectivePreset,
      type: widget.type,
      take: take,
    );
  }

  void _onScroll() {
    // Check for "Back to Top" button
    if (_scrollController.offset > 600) {
      if (!_showBackToTop) setState(() => _showBackToTop = true);
    } else {
      if (_showBackToTop) setState(() => _showBackToTop = false);
    }

    // Check for load more
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'lib/assets/icon_voratoon.png',
              width: 28,
              height: 28,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SearchInput(
              controller: _searchController,
              hintText: AppStrings.searchComicHint,
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _selectedGenreIds.isNotEmpty ? const Color(0xFFFDD644) : null,
                ),
                onPressed: _showFilterDialog,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.trim();
                });
                _fetchInitialData();
              },
              onClear: () {
                 setState(() {
                    _searchQuery = '';
                 });
                 FocusManager.instance.primaryFocus?.unfocus();
                 _fetchInitialData();
              },
              onSubmitted: (val) {
                 setState(() {
                    _searchQuery = val.trim();
                 });
                 _fetchInitialData();
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _fetchInitialData();
        },
        child: Consumer<HomeProvider>(
          builder: (context, provider, child) {
            final isLoading = _isInitialLoading || (provider.isLoading && provider.discoverComics.isEmpty);
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.discoverComics.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      AppStrings.noComicsFound,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchInitialData,
                      icon: const Icon(Icons.refresh),
                      label: const Text(AppStrings.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDD644),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      childAspectRatio: 0.68,
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
      ),
      floatingActionButton: AnimatedSlide(
        offset: _showBackToTop ? Offset.zero : const Offset(0, 1.5),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: _showBackToTop ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            onPressed: _showBackToTop
                ? () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }
                : null,
            child: const Icon(Icons.keyboard_arrow_up),
          ),
        ),
      ),
    );
  }
}

