import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/constants.dart';

class DetailChapterHeader extends StatelessWidget {
  final int totalChapters;
  final int? filteredCount;
  final bool isAscending;
  final VoidCallback onToggleSort;

  const DetailChapterHeader({
    super.key,
    required this.totalChapters,
    this.filteredCount,
    required this.isAscending,
    required this.onToggleSort,
  });

  @override
  Widget build(BuildContext context) {
    final countLabel = (filteredCount != null && filteredCount != totalChapters)
        ? '$filteredCount / $totalChapters'
        : '$totalChapters';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '${AppStrings.chapterList} ($countLabel)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onToggleSort,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                  width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: AppConstants.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  isAscending ? AppStrings.sortOldest : AppStrings.sortNewest,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
