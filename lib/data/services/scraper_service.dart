import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/constants.dart';
import '../models/comic_model.dart';
import '../models/chapter_model.dart';
import '../models/detail_comic_model.dart';
import '../models/genre_model.dart';
import '../../util/util.dart';

class ScraperService {
  Map<String, String> get _headers => {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/plain, */*',
        'Referer': '${AppConstants.baseUrl}/',
      };
  
  Future<DetailComicModel> getDetailComic(String url) async {
    String slug = url;
    if (url.contains('/komik/')) {
      slug = url.split('/komik/').last.replaceAll('/', '');
    }

    final apiUrl = '${AppConstants.apiBaseUrl}/series/$slug?includeMeta=true';
    final chaptersApiUrl = '${AppConstants.apiBaseUrl}/series/$slug/chapters';

    final responses = await Future.wait([
      http.get(Uri.parse(apiUrl), headers: _headers),
      http.get(Uri.parse(chaptersApiUrl), headers: _headers),
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
      
      final chaptersList = jsonChapter['data'];

      if (chaptersList != null && chaptersList is List) {
        for (var chapterRaw in chaptersList) {
          var chapInfo = chapterRaw['data'] ?? chapterRaw;
          
          String chapIndexStr = chapterRaw['chapterIndex']?.toString() ?? chapInfo['index']?.toString() ?? '';
          String chapTitle = 'Chapter $chapIndexStr';

          String chapLink = '${AppConstants.apiBaseUrl}/series/$slug/chapters/$chapIndexStr';

          String? rawDate = chapterRaw['createdAt'] ?? chapInfo['date']?.toString();

          chaptersData.add(
            ChapterModel(
              title: chapTitle,
              link: chapLink,
              releaseDate: timeAgo(rawDate),
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


  Future<ReaderData> getReaderDataBE(String chapterApiUrl) async {
    String seriesSlug = '';
    if (chapterApiUrl.contains('/series/')) {
       final parts = chapterApiUrl.split('/series/').last.split('/');
       if (parts.isNotEmpty) {
          seriesSlug = parts.first;
       }
    }

    // Jika URL yang diklik bukan pola API (karena bookmark lama di DB), kembalikan fallback atau paksa ubah
    if (!chapterApiUrl.startsWith('${AppConstants.apiBaseUrl}/')) {
       throw Exception('Endpoint API tidak dikenali. Coba muat ulang daftar episode.');
    }

    final seriesApiUrl = '${AppConstants.apiBaseUrl}/series/$seriesSlug?includeMeta=true';
    
    final responses = await Future.wait([
      http.get(Uri.parse(chapterApiUrl), headers: _headers),
      http.get(Uri.parse(seriesApiUrl), headers: _headers),
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

  Future<List<ComicModel>> fetchSeries({
    String? searchQuery,
    String? preset, // rilisan_terbaru, popular_all
    String? type,
    bool? includeMeta,
    String? sort, // latest
    String? sortOrder, // desc
    List<String>? genres,
    int page = 1,
    int take = 20,
  }) async {
    // 1. Definisikan parameter dasar yang selalu ada
    Map<String, dynamic> queryParameters = {
      'takeChapter': '3',
      'take': take.toString(),
      'page': page.toString(),
    };

    // 2. Tambahkan preset jika ada
    if (preset != null && preset.isNotEmpty) {
      queryParameters['preset'] = preset;
    }

    // 3. Tambahkan type jika ada
    if (type != null && type.isNotEmpty) {
      queryParameters['type'] = type;
    }

    // 3. Tambahkan includeMeta jika ada
    if (includeMeta != null) {
      queryParameters['includeMeta'] = includeMeta.toString();
    }

    // 4. Tambahkan sort jika ada
    if (sort != null && sort.isNotEmpty) {
      queryParameters['sort'] = sort;
    }

    // 5. Tambahkan sortOrder jika ada
    if (sortOrder != null && sortOrder.isNotEmpty) {
      queryParameters['sortOrder'] = sortOrder;
    }

    // 6. Tambahkan filter pencarian jika ada
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParameters['filter'] = 'title=like="$searchQuery",nativeTitle=like="$searchQuery"';
    }

    // 7. Tambahkan filter genre jika ada (Multiple values)
    if (genres != null && genres.isNotEmpty) {
      queryParameters['genreIds'] = genres;
    }

    // 8. Bangun URI (Uri.https akan otomatis menangani list genreIds menjadi genreIds=A&genreIds=B)
    Uri uri = Uri.parse('${AppConstants.apiBaseUrl}/series').replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<ComicModel> comics = [];
        List<dynamic> listData = [];
        
        if (jsonResponse is List) {
          listData = jsonResponse;
        } else if (jsonResponse is Map && jsonResponse['data'] != null) {
          if (jsonResponse['data'] is List) {
            listData = jsonResponse['data'];
          } else if (jsonResponse['data']['data'] is List) {
            listData = jsonResponse['data']['data'];
          }
        }

        for (var itemRaw in listData) {
          if (itemRaw is! Map) continue;
          var item = itemRaw as Map<String, dynamic>;
          
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
          String? updatedAt;
          
          final chapters = item['chapters'] ?? innerData['chapters'];
          if (chapters != null && chapters is List && chapters.isNotEmpty) {
            final firstChapter = chapters.first;
            final chapData = firstChapter['data'] ?? {};
            
            final chapTitle = chapData['title'];
            final chapIndex = firstChapter['chapterIndex'] ?? chapData['number'];
            updatedAt = firstChapter['updatedAt'];
            
            latestChapter = '$chapIndex';
            
            final chapterSlug = chapData['slug'];
            if (chapterSlug != null) {
              chapterLink = '/chapter/$chapterSlug';
            } else if (firstChapter['id'] != null) {
              chapterLink = '/chapter/${firstChapter['id']}';
            }
          }

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
            updatedAt: updatedAt!= null?timeAgo(updatedAt):'',
          ));
        }

        return comics;
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  Future<List<GenreModel>> getGenres() async {
    Uri uri = Uri.parse('${AppConstants.apiBaseUrl}/genres');
    try {
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<GenreModel> genres = [];
        List<dynamic> listData = [];

        if (jsonResponse is List) {
          listData = jsonResponse;
        } else if (jsonResponse is Map && jsonResponse['data'] != null) {
          listData = jsonResponse['data'];
        }

        for (var item in listData) {
          if (item is Map<String, dynamic>) {
            genres.add(GenreModel.fromJson(item));
          }
        }
        return genres;
      } else {
        throw Exception('Gagal memuat genre');
      }
    } catch (e) {
      print("Error getGenres: $e");
      return [];
    }
  }
}

class ReaderData {
  final List<String> images;
  final String title;
  final String seriesLink;
  ReaderData({required this.images, required this.title, required this.seriesLink});
}
