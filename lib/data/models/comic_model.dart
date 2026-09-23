class ComicModel {
  final String title;
  final String thumbUrl;
  final String link;
  final String? latestChapter;
  final String? chapterLink;
  final String type;
  final String status;
  final String format;
  final String updatedAt;
  final bool isPinned;
  final bool isHot;
  final bool isRecommended;

  ComicModel({
    required this.title,
    required this.thumbUrl,
    required this.link,
    this.latestChapter,
    this.chapterLink,
    this.type = '',
    this.status = '',
    this.format = '',
    this.updatedAt = '',
    this.isPinned = false,
    this.isHot = false,
    this.isRecommended = false,
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
      'updatedAt': updatedAt,
      'isPinned': isPinned ? 1 : 0,
      'isHot': isHot ? 1 : 0,
      'isRecommended': isRecommended ? 1 : 0,
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
      updatedAt: map['updatedAt']?.toString() ?? '',
      isPinned: map['isPinned'] == true ||
          map['isPinned'] == 1 ||
          map['isPinned'] == 'true' ||
          map['isPinned'] == '1',
      isHot: map['isHot'] == true ||
          map['isHot'] == 1 ||
          map['isHot'] == 'true' ||
          map['isHot'] == '1',
      isRecommended: map['isRecommended'] == true ||
          map['isRecommended'] == 1 ||
          map['isRecommended'] == 'true' ||
          map['isRecommended'] == '1',
    );
  }

  void operator []=(String other, String value) {}

  String get formatEmoji {
    final f = format.toLowerCase();
    if (f.contains('manga')) return '🇯🇵';
    if (f.contains('manhwa')) return '🇰🇷';
    if (f.contains('manhua')) return '🇨🇳';
    return '';
  }

  String get statusLabel => status.toUpperCase();
  String get typeLabel => type.toUpperCase();

  bool get isManga => format.toLowerCase().contains('manga');
  bool get isManhwa => format.toLowerCase().contains('manhwa');
  bool get isManhua => format.toLowerCase().contains('manhua');
}
