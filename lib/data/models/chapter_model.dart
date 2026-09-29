import '../../util/util.dart';

class ChapterModel {
  final String title;
  final String link;
  final String? releaseDate;
  final String? updatedAt;
  final String? createdAt;

  ChapterModel({
    required this.title,
    required this.link,
    this.releaseDate,
    this.updatedAt,
    this.createdAt,
  });

  String get displayDate {
    final rawDate = (updatedAt != null && updatedAt!.trim().isNotEmpty)
        ? updatedAt
        : (createdAt != null && createdAt!.trim().isNotEmpty)
            ? createdAt
            : releaseDate;

    if (rawDate != null && rawDate.trim().isNotEmpty) {
      final trimmed = rawDate.trim();
      if (trimmed.contains('lalu') || trimmed == 'Baru saja') {
        return trimmed;
      }
      return timeAgo(trimmed);
    }
    return '';
  }
}

