class ComicModel {
  final String title;
  final String thumbUrl;
  final String link;
  final String? latestChapter;
  final String? chapterLink;
  final String type;
  final String status;
  final String format;

  ComicModel({
    required this.title,
    required this.thumbUrl,
    required this.link,
    this.latestChapter,
    this.chapterLink,
    this.type = '',
    this.status = '',
    this.format = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'thumbUrl': thumbUrl,
      'link': link,
      'latestChapter': latestChapter,
      'chapterLink': chapterLink,
      'type': type,
      'status': status,
      'format': format,
    };
  }

  factory ComicModel.fromMap(Map<String, dynamic> map) {
    return ComicModel(
      title: map['title'],
      thumbUrl: map['thumbUrl'],
      link: map['link'],
      latestChapter: map['latestChapter'],
      chapterLink: map['chapterLink'],
      type: map['type']?.toString() ?? '',
      status: map['status']?.toString() ?? '',
      format: map['format']?.toString() ?? '',
    );
  }
}
