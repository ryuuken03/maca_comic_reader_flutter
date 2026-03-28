class AppConstants {
  static const String baseUrl = 'https://v1.komikcast.fit';
  static const String apiBaseUrl = 'https://be.komikcast.cc';

  // Selectors with fallbacks for MangaStream / Komikcast changes
  static const String homeListSelector = '.list-update .utao, .listupd .bs, .listo .bsx, .bigor';
  static const String homeImageSelector = '.imgu img, .limit img, img';
  static const String homeTitleSelector = '.luf h3, .luf h4, .bigor h3, .tt, h3, h4';
  static const String homeChapterSelector = '.manga-item-chapter, .epxs, .chapter';
  static const String homeLinkSelector = 'a';

  static const String detailTitleSelector = '.entry-title, .infox h1, h1[itemprop="name"]';
  static const String detailThumbSelector = '.thumb img, .wd-full img, .infox img';
  static const String detailDescSelector = '.entry-content, .desc, [itemprop="description"]';
  static const String detailChapterListSelector = '#chapterlist li, .cl ul li, .eplister li';
  static const String detailChapterTitleSelector = '.lchx a, .chapternum, a';
  static const String detailChapterDateSelector = '.chapterdate';

  static const String readerImageSelector = '#readerarea img, .main-reading-area img';
}
