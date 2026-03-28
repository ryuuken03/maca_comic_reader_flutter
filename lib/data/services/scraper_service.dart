import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../../core/constants/constants.dart';
import '../models/comic_model.dart';
import '../models/chapter_model.dart';
import '../models/detail_comic_model.dart';

class ScraperService {
  Future<List<ComicModel>> getHomeComicsBE({int page = 1}) async {
    final url =
        'https://be.komikcast.cc/series?preset=rilisan_terbaru&take=20&takeChapter=3&page=$page';
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      'Referer': 'https://v1.komikcast.fit/',
    });

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat API Backend (Status: ${response.statusCode}). Kemungkinan diblokir Cloudflare.');
    }

    List<ComicModel> comics = [];
    try {
      final jsonResponse = jsonDecode(response.body);
      
      // Ambil metadata jika ada, untuk mengetahui batas lastPage
      final meta = jsonResponse['meta'];
      if (meta != null && meta['lastPage'] != null) {
        int lastPage = meta['lastPage'] is int ? meta['lastPage'] : int.tryParse(meta['lastPage'].toString()) ?? page;
        if (page > lastPage) {
          return comics; // Langsung return kosong (sudah mentok)
        }
      }
      
      // Mengantisipasi ragam struktur JSON API dan mencegah tipe akses error (String vs int)
      List<dynamic> listData = [];
      if (jsonResponse is List) {
        listData = jsonResponse;
      } else if (jsonResponse is Map) {
        // if (jsonResponse['data'] is Map && jsonResponse['data']['data'] is List) {
        //   listData = jsonResponse['data']['data'];
        // } else if (jsonResponse['data'] is List) {
          listData = jsonResponse['data'];
        // } else if (jsonResponse['result'] is List) {
        //   listData = jsonResponse['result'];
        // }
      }
      
      for (var itemRaw in listData) {
        if (itemRaw is! Map) continue;
        var item = itemRaw as Map<String, dynamic>;
        
        // Data komik utama biasanya tersarang di dalam key 'data'
        var innerData = item['data'];
        if (innerData == null || innerData is! Map) {
          innerData = item;
        }

        String title = innerData['title'] ?? innerData['name'] ?? 'No Title';
        String thumbUrl = innerData['coverImage'] ?? innerData['thumbnail'] ?? innerData['cover'] ?? innerData['backgroundImage'] ?? '';
        String slug = innerData['slug'] ?? '';
        String linkDetail = slug.isNotEmpty ? '/komik/$slug' : '';
        
        String? latestChapter;
        String? chapterLink;
        
        // Chapter list ada di key 'chapters' dari item
        final chapters = item['chapters'] ?? innerData['chapters'];
        if (chapters != null && chapters is List && chapters.isNotEmpty) {
          final firstChapter = chapters.first;
          final chapData = firstChapter['data'] ?? {};
          
          final chapTitle = chapData['title'];
          final chapIndex = firstChapter['chapterIndex'] ?? chapData['number'];
          
          latestChapter = chapTitle != null ? chapTitle.toString() : 'Chapter $chapIndex';
          if (latestChapter == 'Chapter null') {
            latestChapter = 'Chapter ${firstChapter['id']}';
          }
          
          final chapterSlug = chapData['slug'];
          if (chapterSlug != null) {
            chapterLink = '/chapter/$chapterSlug';
          } else if (firstChapter['id'] != null) {
            chapterLink = '/chapter/${firstChapter['id']}';
          }
        }

        // Resolusi link jadi absolute
        if (linkDetail.isNotEmpty && !linkDetail.startsWith('http')) {
          linkDetail = '${AppConstants.baseUrl}$linkDetail';
        }
        if (chapterLink != null && chapterLink.isNotEmpty && !chapterLink.startsWith('http')) {
          chapterLink = '${AppConstants.baseUrl}$chapterLink';
        }
        
        String type = innerData['type']?.toString() ?? '';
        String status = innerData['status']?.toString() ?? '';
        String format = innerData['format']?.toString() ?? '';

        comics.add(ComicModel(
          title: title,
          thumbUrl: thumbUrl,
          link: linkDetail,
          latestChapter: latestChapter,
          chapterLink: chapterLink,
          type: type,
          status: status,
          format: format,
        ));
      }
    } catch (e) {
      throw Exception('Gagal me-parsing JSON Backend: $e');
    }
    
    return comics;
  }

  Future<List<ComicModel>> getHomeComics() async {
    final response = await http.get(Uri.parse(AppConstants.baseUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load home');
    }

    final document = parser.parse(response.body);

    final rootDiv = document.querySelector('#root');
    if (rootDiv != null) {
      print('=== FOUND DIV ID ROOT ===');
      if (rootDiv.children.isNotEmpty) {
        print('First element inside root: ${rootDiv.children.first.localName}');
        print('First element HTML:');
        print(rootDiv.children.first.outerHtml);
      } else {
        print('DIV ID ROOT IS EMPTY (No children).');
      }
      print('========================');
    } else {
      print('=== DIV ID ROOT NOT FOUND ===');
    }

    // Cari elemen main terlebih dahulu
    final mainElement = document.querySelector('main');
    if (mainElement == null) {
      throw Exception('Elemen <main> tidak ditemukan. Struktur web mungkin telah berubah.');
    }

    // Cari section di dalam main, index 2 sesuai request
    final sections = mainElement.querySelectorAll('section');
    if (sections.length < 3) {
      throw Exception('Daftar komik tidak ditemukan (section < 3 di dalam main). Kemungkinan web menggunakan proteksi Cloudflare atau struktur web telah berubah.');
    }
    
    // Ambil section index ke-2 dan cari semua elemen "article"
    final targetSection = sections[2];
    final elements = targetSection.querySelectorAll('article');

    print("ScraperService:getHomeComics");
    if (elements.isEmpty) {
      throw Exception('Daftar article tidak ditemukan pada section index ke-2. Kemungkinan struktur web telah berubah.');
    }

    List<ComicModel> comics = [];
    for (var element in elements) {
      try {
        final imgEl = element.querySelector('img');
        
        // title: asumsikan di h3, h4, .title, atau .tt
        final titleEl = element.querySelector('h3') ?? 
                        element.querySelector('h4') ?? 
                        element.querySelector('.title') ?? 
                        element.querySelector('.tt');
                        
        // Ambil kumpulan anchor (a) untuk memisahkan link detail dan link chapter
        final aElements = element.querySelectorAll('a');
        
        // chapter 
        final chapterEl = element.querySelector('.chapter') ?? 
                          element.querySelector('.epxs') ??
                          element.querySelector('.list-chapter') ??
                          element.querySelector('.chap');

        String thumbUrl = imgEl?.attributes['src'] ?? imgEl?.attributes['data-src'] ?? '';
        String title = titleEl?.text.trim() ?? '';
        
        if (title.isEmpty && aElements.isNotEmpty) {
           title = aElements.first.attributes['title'] ?? aElements.first.text.trim();
        }

        // Link detail chapter: umumnya anchor tag pertama di article
        String linkDetail = '';
        if (aElements.isNotEmpty) {
          linkDetail = aElements.first.attributes['href'] ?? '';
          if (linkDetail.isNotEmpty && !linkDetail.startsWith('http')) {
            linkDetail = '${AppConstants.baseUrl}$linkDetail';
          }
        }
        
        // Link list chapter: ekstrak dari elemen chapter atau anchor kedua/terakhir
        String linkChapter = '';
        if (chapterEl != null) {
          final chapterA = chapterEl.querySelector('a');
          if (chapterA != null) {
             linkChapter = chapterA.attributes['href'] ?? '';
          }
        }
        if (linkChapter.isEmpty && aElements.length > 1) {
           // Fallback anchor
           linkChapter = aElements.last.attributes['href'] ?? '';
        }
        if (linkChapter.isNotEmpty && !linkChapter.startsWith('http')) {
           linkChapter = '${AppConstants.baseUrl}$linkChapter';
        }

        String? latestChapter = chapterEl?.text.trim();
        if (latestChapter != null && latestChapter.contains('\n')) {
           latestChapter = latestChapter.split('\n').first.trim();
        }

        if (title.isNotEmpty && linkDetail.isNotEmpty) {
          comics.add(
            ComicModel(
              title: title,
              thumbUrl: thumbUrl,
              link: linkDetail, // "link detail chapter"
              latestChapter: latestChapter, // "chapter"
              chapterLink: linkChapter.isNotEmpty ? linkChapter : null, // "link list chapter"
            ),
          );
        }
      } catch (e) {
        // abaikan error formasi untuk satu item
      }
    }
    return comics;
  }

  Future<DetailComicModel> getDetailComic(String url) async {
    // Ekstrak slug dari URL lama seperti https://v1.komikcast.fit/komik/manga-slug/
    String slug = url;
    if (url.contains('/komik/')) {
      slug = url.split('/komik/').last.replaceAll('/', '');
    }

    final apiUrl = 'https://be.komikcast.cc/series/$slug?includeMeta=true';
    final chaptersApiUrl = 'https://be.komikcast.cc/series/$slug/chapters';

    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      'Referer': 'https://v1.komikcast.fit/',
    };

    final responses = await Future.wait([
      http.get(Uri.parse(apiUrl), headers: headers),
      http.get(Uri.parse(chaptersApiUrl), headers: headers),
    ]);

    final detailRes = responses[0];
    final chapterRes = responses[1];

    if (detailRes.statusCode != 200) {
      throw Exception('Gagal memuat API Detail Backend (Status: ${detailRes.statusCode}).');
    }

    try {
      final jsonResponse = jsonDecode(detailRes.body);
      final jsonChapter = jsonDecode(chapterRes.body);
      
      final rootData = jsonResponse['data'];
      if (rootData == null) {
        throw Exception('Data komik tidak ditemukan pada JSON.');
      }

      final innerData = rootData['data'] ?? rootData;

      String title = innerData['title'] ?? innerData['name'] ?? 'No Title';
      String thumbUrl = innerData['coverImage'] ?? innerData['thumbnail'] ?? innerData['cover'] ?? innerData['backgroundImage'] ?? '';
      String description = innerData['synopsis'] ?? innerData['description'] ?? '';

      ComicModel comic = ComicModel(title: title, thumbUrl: thumbUrl, link: url);

      List<ChapterModel> chaptersData = [];
      
      // Mengambil daftar chapters dari endpoint /chapters khusus
      final chaptersList = jsonChapter['data'];

      if (chaptersList != null && chaptersList is List) {
        for (var chapterRaw in chaptersList) {
          var chapInfo = chapterRaw['data'] ?? chapterRaw;
          
          String chapIndexStr = chapterRaw['chapterIndex']?.toString() ?? chapInfo['index']?.toString() ?? '';
          String chapTitle = 'Chapter $chapIndexStr';

          String chapLink = 'https://be.komikcast.cc/series/$slug/chapters/$chapIndexStr';

          String? rawDate = chapterRaw['createdAt'] ?? chapInfo['date']?.toString();

          chaptersData.add(
            ChapterModel(
              title: chapTitle,
              link: chapLink,
              releaseDate: _timeAgo(rawDate),
            ),
          );
        }
      }

      List<String> parsedGenres = [];
      if (innerData['genres'] != null && innerData['genres'] is List) {
        for (var g in innerData['genres']) {
           if (g is Map && g['data'] != null && g['data']['name'] != null) {
              parsedGenres.add(g['data']['name'].toString());
           } else if (g is Map && g['name'] != null) {
              parsedGenres.add(g['name'].toString());
           } else if (g is String) {
              parsedGenres.add(g);
           }
        }
      }

      String status = innerData['status']?.toString() ?? '';
      String type = innerData['type']?.toString() ?? '';
      String format = innerData['format']?.toString() ?? '';

      return DetailComicModel(
        comic: comic,
        description: description,
        chapters: chaptersData,
        genres: parsedGenres,
        status: status,
        type: type,
        format: format,
      );
    } catch (e) {
       throw Exception('Gagal me-parsing JSON Backend Detail: $e');
    }
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateStr);
      final difference = DateTime.now().difference(parsedDate);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()} tahun lalu';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} bulan lalu';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} hari lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} menit lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return dateStr; // Fallback jika tidak standard
    }
  }

  Future<ReaderData> getReaderDataBE(String chapterApiUrl) async {
    print("chapterApiUrl:"+chapterApiUrl);
    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Accept': 'application/json, text/plain, */*',
      'Referer': 'https://v1.komikcast.fit/',
    };

    String seriesSlug = '';
    if (chapterApiUrl.contains('/series/')) {
       final parts = chapterApiUrl.split('/series/').last.split('/');
       if (parts.isNotEmpty) {
          seriesSlug = parts.first;
       }
    }

    // Jika URL yang diklik bukan pola API (karena bookmark lama di DB), kembalikan fallback atau paksa ubah
    if (!chapterApiUrl.startsWith('https://be.komikcast.cc/')) {
       throw Exception('Endpoint API tidak dikenali. Coba muat ulang daftar episode.');
    }

    final seriesApiUrl = 'https://be.komikcast.cc/series/$seriesSlug?includeMeta=true';
    
    final responses = await Future.wait([
      http.get(Uri.parse(chapterApiUrl), headers: headers),
      http.get(Uri.parse(seriesApiUrl), headers: headers),
    ]);
    
    final chapRes = responses[0];
    final seriesRes = responses[1];

    if (chapRes.statusCode != 200) {
      throw Exception('Gagal memuat chapter info (Status: ${chapRes.statusCode})');
    }
    
    final chapJson = jsonDecode(chapRes.body);
    final seriesJson = jsonDecode(seriesRes.body);

    List<String> images = [];
    if (chapJson['data'] != null && chapJson['data']['data'] != null && chapJson['data']['data']['images'] is List) {
       for (var img in chapJson['data']['data']['images']) {
          images.add(img.toString());
       }
    }
    
    String title = '';
    String seriesLink = '';
    if (seriesJson['data'] != null) {
       final inner = seriesJson['data']['data'] ?? seriesJson['data'];
       title = inner['title'] ?? inner['name'] ?? 'Membaca Chapter';
       if (seriesSlug.isNotEmpty) {
          seriesLink = '${AppConstants.baseUrl}/komik/$seriesSlug';
       }
    }
    
    return ReaderData(images: images, title: title, seriesLink: seriesLink);
  }
}

class ReaderData {
  final List<String> images;
  final String title;
  final String seriesLink;
  ReaderData({required this.images, required this.title, required this.seriesLink});
}
