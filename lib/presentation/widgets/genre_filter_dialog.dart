import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import 'genre_chip.dart';

class GenreFilterDialog extends StatefulWidget {
  final List<String> initialSelectedGenreIds;

  const GenreFilterDialog({
    Key? key,
    required this.initialSelectedGenreIds,
  }) : super(key: key);

  @override
  _GenreFilterDialogState createState() => _GenreFilterDialogState();
}

class _GenreFilterDialogState extends State<GenreFilterDialog> {
  late List<String> _selectedGenreIds;

  @override
  void initState() {
    super.initState();
    _selectedGenreIds = List<String>.from(widget.initialSelectedGenreIds);
    // Fetch genres on load if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().fetchGenres();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Filter Genre',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: provider.genres.isEmpty
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: provider.genres.map((genre) {
                        final isSelected = _selectedGenreIds.contains(genre.name.toString());
                        return GenreChip(
                          label: genre.name,
                          isSelected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
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
            if (_selectedGenreIds.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedGenreIds.clear();
                  });
                  Navigator.of(context).pop(<String>[]);
                },
                child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(_selectedGenreIds);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDD644),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Filter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
