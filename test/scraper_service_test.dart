import 'package:flutter_test/flutter_test.dart';
import 'package:maca/data/services/scraper_service.dart';

void main() {
  test('ScraperService fetches series, detail, and chapters successfully', () async {
    final service = ScraperService();

    final seriesList = await service.fetchSeries(take: 3);
    expect(seriesList, isNotEmpty);
    expect(seriesList.any((c) => c.latestChapter != null && c.latestChapter!.isNotEmpty), isTrue);

    final popularList = await service.fetchSeries(preset: 'popular_all', take: 3);
    expect(popularList, isNotEmpty);
    expect(popularList.any((c) => c.latestChapter != null && c.latestChapter!.isNotEmpty), isTrue);

    final genres = await service.getGenres();
    expect(genres, isNotEmpty);

    final firstComic = seriesList.first;
    final detail = await service.getDetailComic(firstComic.link);
    expect(detail.comic.title, isNotEmpty);

    if (detail.chapters.isNotEmpty) {
      final readerData = await service.getReaderDataBE(detail.chapters.first.link);
      expect(readerData.images, isNotEmpty);
    }
  });
}
