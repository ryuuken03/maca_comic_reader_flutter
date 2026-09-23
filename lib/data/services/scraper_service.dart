import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../core/constants/constants.dart';
import '../../core/utils/api_cache_manager.dart';
import '../models/comic_model.dart';
import '../models/chapter_model.dart';
import '../models/detail_comic_model.dart';
import '../models/genre_model.dart';
import '../../util/util.dart';

class ScraperService {
  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
        'User-Agent': AppConstants.userAgent,
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'en-US,en;q=0.9,id;q=0.8',
        'referer': '${AppConstants.baseUrl}/',
        'origin': AppConstants.baseUrl,
        'sec-ch-ua': '"Chromium";v="124", "Android";v="13", "Not-A.Brand";v="99"',
        'sec-ch-ua-mobile': '?1',
        'sec-ch-ua-platform': '"Android"',
        'sec-fetch-dest': 'empty',
        'sec-fetch-mode': 'cors',
        'sec-fetch-site': 'cross-site',
      };

  Future<void> _jitterDelay([int minMs = 120, int maxMs = 280]) async {
    final rand = Random();
    final delay = minMs + rand.nextInt(maxMs - minMs + 1);
    await Future.delayed(Duration(milliseconds: delay));
  }
  
  Future<DetailComicModel> getDetailComic(String url, {bool forceRefresh = false}) async {
    final cacheKey = 'detail_$url';
    if (!forceRefresh) {
      final cached = ApiCacheManager.instance.get<DetailComicModel>(cacheKey);
      if (cached != null) return cached;
    }

    String slug = url;
    if (url.contains('/komik/')) {
      slug = url.split('/komik/').last;
    } else if (url.contains('/series/')) {
      slug = url.split('/series/').last.split('?').first.split('/').firstWhere((e) => e.isNotEmpty, orElse: () => slug);
    }
    slug = slug.split('?').first.replaceAll('/', '').trim();

    final apiUrl = '${AppConstants.apiBaseUrl}/series/$slug';
    final chaptersApiUrl = '${AppConstants.apiBaseUrl}/series/$slug/chapters';

    final responses = await Future.wait([
      _client.get(Uri.parse(apiUrl), headers: _headers),
      _client.get(Uri.parse(chaptersApiUrl), headers: _headers),
    ]);

    final detailRes = responses[0];
    final chapterRes = responses[1];

    if (detailRes.statusCode == 429 || chapterRes.statusCode == 429) {
      throw Exception('Server sedang sibuk (Too Many Requests). Harap tunggu beberapa saat.');
    }

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

      bool isPinned = innerData['isPinned'] == true ||
          innerData['isPinned'] == 1 ||
          innerData['pinned'] == true ||
          rootData['isPinned'] == true;

      bool isHot = innerData['isHot'] == true ||
          innerData['isHot'] == 1 ||
          innerData['hot'] == true ||
          rootData['isHot'] == true;

      bool isRecommended = innerData['isRecommended'] == true ||
          innerData['isRecommended'] == 1 ||
          innerData['recommended'] == true ||
          rootData['isRecommended'] == true ||
          (rootData['dataMetadata'] != null && rootData['dataMetadata']['isRecommended'] == true) ||
          (innerData['dataMetadata'] != null && innerData['dataMetadata']['isRecommended'] == true);

      ComicModel comic = ComicModel(
        title: title,
        thumbUrl: thumbUrl,
        link: url,
        isPinned: isPinned,
        isHot: isHot,
        isRecommended: isRecommended,
      );

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

      final comicWithMeta = ComicModel(
        title: comic.title,
        thumbUrl: comic.thumbUrl,
        link: comic.link,
        isPinned: isPinned,
        isHot: isHot,
        isRecommended: isRecommended,
        status: status,
        type: type,
        format: format,
      );

      final detailComic = DetailComicModel(
        comic: comicWithMeta,
        description: description,
        chapters: chaptersData,
        genres: parsedGenres,
        status: status,
        type: type,
        format: format,
        isPinned: isPinned,
        isHot: isHot,
        isRecommended: isRecommended,
      );

      ApiCacheManager.instance.set<DetailComicModel>(cacheKey, detailComic, ttl: const Duration(minutes: 20));
      return detailComic;
    } catch (e) {
       throw Exception('Gagal me-parsing JSON Backend Detail: $e');
    }
  }


  Future<ReaderData> getReaderDataBE(String chapterApiUrl, {bool forceRefresh = false}) async {
    String normalizedUrl = chapterApiUrl;

    if (normalizedUrl.contains('be.komikcast.cc')) {
      normalizedUrl = normalizedUrl.replaceAll('https://be.komikcast.cc', AppConstants.apiBaseUrl);
    } else if (normalizedUrl.contains('/series/') && normalizedUrl.contains('/chapter/')) {
      final uri = Uri.tryParse(normalizedUrl);
      final segments = uri?.pathSegments ?? normalizedUrl.split('/').where((s) => s.isNotEmpty).toList();
      final seriesIdx = segments.indexOf('series');
      final chapterIdx = segments.indexOf('chapter');
      if (seriesIdx != -1 && chapterIdx != -1 && seriesIdx + 1 < segments.length && chapterIdx + 1 < segments.length) {
        final slug = segments[seriesIdx + 1];
        final chapNum = segments[chapterIdx + 1];
        normalizedUrl = '${AppConstants.apiBaseUrl}/series/$slug/chapters/$chapNum';
      }
    } else if (normalizedUrl.contains('v1.voratoon.com') || normalizedUrl.contains('v2.voratoon.com')) {
      normalizedUrl = normalizedUrl
          .replaceAll('https://v1.voratoon.com', AppConstants.apiBaseUrl)
          .replaceAll('https://v2.voratoon.com', AppConstants.apiBaseUrl);
    }

    if (!normalizedUrl.startsWith('${AppConstants.apiBaseUrl}/')) {
      throw Exception('Endpoint API tidak dikenali. Coba muat ulang daftar episode.');
    }

    final cacheKey = 'reader_$normalizedUrl';
    if (!forceRefresh) {
      final cached = ApiCacheManager.instance.get<ReaderData>(cacheKey);
      if (cached != null) return cached;
    }

    final response = await _client.get(Uri.parse(normalizedUrl), headers: _headers);
    
    if (response.statusCode == 429) {
      throw Exception('Server sedang sibuk (Too Many Requests). Harap tunggu beberapa saat.');
    }

    if (response.statusCode != 200) {
      throw Exception('Gagal memuat chapter info (Status: ${response.statusCode})');
    }
    
    final chapJson = jsonDecode(response.body);

    List<String> images = [];
    if (chapJson['data'] != null && chapJson['data']['data'] != null && chapJson['data']['data']['images'] is List) {
       for (var img in chapJson['data']['data']['images']) {
          images.add(img.toString());
       }
    }
    
    final readerData = ReaderData(images: images);
    ApiCacheManager.instance.set<ReaderData>(cacheKey, readerData, ttl: const Duration(minutes: 30));
    return readerData;
  }

  Future<List<ComicModel>> fetchSeries({
    String? searchQuery,
    String? preset, // rilisan_terbaru, popular_all
    String? type,
    String? sort, // latest
    String? sortOrder, // desc
    List<String>? genres,
    int page = 1,
    int take = 20,
  }) async {
    // 1. Definisikan parameter dasar yang selalu ada
    Map<String, dynamic> queryParameters = {
      'takeChapter': '1',
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
      // queryParameters['filter'] = 'title=like="$searchQuery",nativeTitle=like="$searchQuery"';
      queryParameters['title'] = searchQuery;
    }

    // 7. Tambahkan filter genre jika ada (Multiple values)
    if (genres != null && genres.isNotEmpty) {
      queryParameters['genreIds'] = genres;
    }

    // 8. Bangun URI (Uri.https akan otomatis menangani list genreIds menjadi genreIds=A&genreIds=B)
    Uri uri = Uri.parse('${AppConstants.apiBaseUrl}/series').replace(queryParameters: queryParameters);

    final cacheKey = 'series_${uri.toString()}';
    if (page == 1 && (searchQuery == null || searchQuery.isEmpty)) {
      final cached = ApiCacheManager.instance.get<List<ComicModel>>(cacheKey);
      if (cached != null) return cached;
    }

    await _jitterDelay();

    try {
      final response = await _client.get(uri, headers: _headers);

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
            final firstChapter = chapters[0];
            if (firstChapter is Map) {
              final chapData = firstChapter['data'] is Map ? firstChapter['data'] : {};
              
              final chapTitle = chapData['title'] ?? firstChapter['title'];
              final chapIndex = firstChapter['chapterIndex'] ?? chapData['number'] ?? firstChapter['number'];
              updatedAt = firstChapter['updatedAt'] ?? chapData['updatedAt'];
              
              if (chapTitle != null &&
                  chapTitle.toString().trim().isNotEmpty &&
                  chapTitle.toString().toLowerCase().contains('oneshot')) {
                latestChapter = chapTitle.toString().trim();
              } else if (chapIndex != null) {
                latestChapter = '$chapIndex';
              } else if (chapTitle != null && chapTitle.toString().trim().isNotEmpty) {
                latestChapter = chapTitle.toString().trim();
              }
              
              if (slug.isNotEmpty && chapIndex != null && '$chapIndex'.isNotEmpty) {
                chapterLink = '${AppConstants.apiBaseUrl}/series/$slug/chapters/$chapIndex';
              } else {
                final chapterSlug = chapData['slug'] ?? firstChapter['slug'];
                if (chapterSlug != null) {
                  chapterLink = '/chapter/$chapterSlug';
                } else if (firstChapter['id'] != null) {
                  chapterLink = '/chapter/${firstChapter['id']}';
                }
              }
            } else if (firstChapter != null) {
              latestChapter = '$firstChapter';
            }
          }

          if ((latestChapter == null || latestChapter.isEmpty) && innerData['totalChapters'] != null) {
            final total = innerData['totalChapters'].toString().trim();
            if (total.isNotEmpty && total != '0') {
              latestChapter = total;
            }
          }

          updatedAt ??= innerData['updatedAt'] ?? item['updatedAt'];

          if (linkDetail.isNotEmpty && !linkDetail.startsWith('http')) {
            linkDetail = '${AppConstants.baseUrl}$linkDetail';
          }
          if (chapterLink != null && chapterLink.isNotEmpty && !chapterLink.startsWith('http')) {
            chapterLink = '${AppConstants.baseUrl}$chapterLink';
          }
          
          String type = innerData['type']?.toString() ?? '';
          String status = innerData['status']?.toString() ?? '';
          String format = innerData['format']?.toString() ?? '';

          bool isPinned = innerData['isPinned'] == true ||
              innerData['isPinned'] == 1 ||
              innerData['pinned'] == true ||
              item['isPinned'] == true;

          bool isHot = innerData['isHot'] == true ||
              innerData['isHot'] == 1 ||
              innerData['hot'] == true ||
              item['isHot'] == true;

          bool isRecommended = innerData['isRecommended'] == true ||
              innerData['isRecommended'] == 1 ||
              innerData['recommended'] == true ||
              item['isRecommended'] == true ||
              (item['dataMetadata'] != null && item['dataMetadata']['isRecommended'] == true) ||
              (innerData['dataMetadata'] != null && innerData['dataMetadata']['isRecommended'] == true);

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
            isPinned: isPinned,
            isHot: isHot,
            isRecommended: isRecommended,
          ));
        }

        if (page == 1 && (searchQuery == null || searchQuery.isEmpty) && comics.isNotEmpty) {
          ApiCacheManager.instance.set<List<ComicModel>>(cacheKey, comics, ttl: const Duration(minutes: 3));
        }

        return comics;
      } else if (response.statusCode == 429) {
        throw Exception('Server sedang sibuk (Too Many Requests). Harap tunggu beberapa saat.');
      } else {
        print('FetchSeries Error Status: ${response.statusCode}');
        print('FetchSeries Error Body: ${response.body}');
        throw Exception('Gagal memuat data1');
      }
    } catch (e) {
      print("Error: $e");
      return [];
    }
  }

  Future<List<GenreModel>> getGenres({bool forceRefresh = false}) async {
    const cacheKey = 'genres_all';
    if (!forceRefresh) {
      final cached = ApiCacheManager.instance.get<List<GenreModel>>(cacheKey);
      if (cached != null) return cached;
    }

    Uri uri = Uri.parse('${AppConstants.apiBaseUrl}/genres');
    try {
      final response = await _client.get(uri, headers: _headers);

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

        if (genres.isNotEmpty) {
          ApiCacheManager.instance.set<List<GenreModel>>(cacheKey, genres, ttl: const Duration(hours: 24));
        }

        return genres;
      } else if (response.statusCode == 429) {
        throw Exception('Server sedang sibuk (Too Many Requests). Harap tunggu beberapa saat.');
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
  ReaderData({required this.images});
}
