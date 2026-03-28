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

  DetailComicModel({
    required this.comic,
    required this.description,
    required this.chapters,
    this.genres = const [],
    this.status = '',
    this.type = '',
    this.format = '',
  });
}
