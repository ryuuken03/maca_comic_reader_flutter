import 'package:flutter/widgets.dart';

/// Calculates the adaptive number of items to fetch for a grid based on column count.
/// If the column count is odd (e.g., 3 or 5), takes 21 items.
/// If the column count is even (e.g., 2 or 4), takes 20 items.
int getAdaptiveGridTake(BuildContext context, {double maxExtent = 180}) {
  final width = MediaQuery.sizeOf(context).width;
  // Account for tablet NavigationRail (80dp) when width >= 640
  final effectiveWidth = width >= 640 ? width - 80 : width;
  final cols = (effectiveWidth / maxExtent).floor().clamp(2, 8);
  return (cols % 2 != 0) ? 21 : 20;
}
