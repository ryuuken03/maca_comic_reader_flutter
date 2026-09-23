import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/constants.dart';

class DetailChapterFilter extends StatelessWidget {
  final int totalChapters;
  final int downloadedCount;
  final bool onlyDownloaded;
  final VoidCallback onSelectAll;
  final VoidCallback onSelectDownloaded;

  const DetailChapterFilter({
    super.key,
    required this.totalChapters,
    required this.downloadedCount,
    required this.onlyDownloaded,
    required this.onSelectAll,
    required this.onSelectDownloaded,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterPill(
              label: '${AppStrings.filterAll} ($totalChapters)',
              isSelected: !onlyDownloaded,
              onTap: onSelectAll,
            ),
            const SizedBox(width: 8),
            _FilterPill(
              label: '${AppStrings.filterDownloaded} ($downloadedCount)',
              icon: Icons.download_done_rounded,
              isSelected: onlyDownloaded,
              onTap: onSelectDownloaded,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppConstants.primaryColor
                : Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.black : Colors.white70,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
