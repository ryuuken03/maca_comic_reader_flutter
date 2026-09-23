import 'comic_model.dart';
import 'chapter_model.dart';

class DetailComicModel {
  final ComicModel comic;
  final String description;
  final List<ChapterModel> chapters;
  final List<String> genres;
  final String status;
  final String type;
  final String format;
  final bool isPinned;
  final bool isHot;
  final bool isRecommended;

  DetailComicModel({
    required this.comic,
    required this.description,
    required this.chapters,
    this.genres = const [],
    this.status = '',
    this.type = '',
    this.format = '',
    bool? isPinned,
    bool? isHot,
    bool? isRecommended,
  })  : isPinned = isPinned ?? comic.isPinned,
        isHot = isHot ?? comic.isHot,
        isRecommended = isRecommended ?? comic.isRecommended;

  String get statusLabel => (status.isNotEmpty ? status : comic.status).toUpperCase();
  String get typeLabel => (type.isNotEmpty ? type : comic.type).toUpperCase();
  String get formatEmoji {
    final f = (format.isNotEmpty ? format : comic.format).toLowerCase();
    if (f.contains('manga')) return '🇯🇵';
    if (f.contains('manhwa')) return '🇰🇷';
    if (f.contains('manhua')) return '🇨🇳';
    return '';
  }
}
