import 'package:flutter/material.dart';

class AppConstants {
  static const String baseUrl = 'https://v2.voratoon.com';
  static const String apiBaseUrl = 'https://api.voratoon.com';

  // UI Colors
  static const Color primaryColor = Color(0xFFFDD644);
  static const Color scaffoldDarkBackground = Color(0xFF121212);
  static const Color appBarDarkBackground = Color(0xFF1E1E1E);
  static const Color cardDarkBackground = Color(0xFF1E1E1E);
  static const Color orange = Colors.orange;

  static const String userAgent =
      'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  static Map<String, String> get imageHeaders => {
    'Referer': '$baseUrl/',
    'User-Agent': userAgent,
    'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  // Selectors with fallbacks for MangaStream / Voratoon changes
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
