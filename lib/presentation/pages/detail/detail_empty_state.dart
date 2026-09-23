import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';

class DetailEmptyChapterState extends StatelessWidget {
  final bool isDownloadedFilter;
  final String searchQuery;

  const DetailEmptyChapterState({
    super.key,
    this.isDownloadedFilter = false,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    if (isDownloadedFilter && searchQuery.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.download_for_offline_outlined,
                size: 48,
                color: Colors.grey.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              const Text(
                AppStrings.noDownloadedChapters,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70),
              ),
              const SizedBox(height: 6),
              const Text(
                AppStrings.downloadHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: Colors.grey.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              searchQuery.isNotEmpty
                  ? '${AppStrings.noChaptersFound} "$searchQuery"'
                  : AppStrings.noChaptersFound,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
