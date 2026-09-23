class DownloadedChapterModel {
  final String id;
  final String comicId;
  final String comicTitle;
  final String comicThumbUrl;
  final String chapterTitle;
  final String chapterUrl;
  final String localPath;
  final int pageCount;
  final int sizeBytes;
  final int downloadedAt;

  DownloadedChapterModel({
    required this.id,
    required this.comicId,
    required this.comicTitle,
    this.comicThumbUrl = '',
    required this.chapterTitle,
    required this.chapterUrl,
    required this.localPath,
    required this.pageCount,
    this.sizeBytes = 0,
    required this.downloadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'comic_id': comicId,
      'comic_title': comicTitle,
      'comic_thumb_url': comicThumbUrl,
      'chapter_title': chapterTitle,
      'chapter_url': chapterUrl,
      'local_path': localPath,
      'page_count': pageCount,
      'size_bytes': sizeBytes,
      'downloaded_at': downloadedAt,
    };
  }

  factory DownloadedChapterModel.fromMap(Map<String, dynamic> map) {
    return DownloadedChapterModel(
      id: map['id']?.toString() ?? '',
      comicId: map['comic_id']?.toString() ?? '',
      comicTitle: map['comic_title']?.toString() ?? '',
      comicThumbUrl: map['comic_thumb_url']?.toString() ?? '',
      chapterTitle: map['chapter_title']?.toString() ?? '',
      chapterUrl: map['chapter_url']?.toString() ?? '',
      localPath: map['local_path']?.toString() ?? '',
      pageCount: (map['page_count'] as num?)?.toInt() ?? 0,
      sizeBytes: (map['size_bytes'] as num?)?.toInt() ?? 0,
      downloadedAt: (map['downloaded_at'] as num?)?.toInt() ?? 0,
    );
  }
}
