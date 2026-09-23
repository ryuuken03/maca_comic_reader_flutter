import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:maca/core/utils/cache_manager.dart';
import 'package:maca/core/constants/constants.dart';

void main() {
  testWidgets('Reader CachedNetworkImage with CustomCacheManager initializes without ImageCacheManager assertion error', (tester) async {
    const testImageUrl = 'https://cdn.voratoon.com/wp-content/img/S/test/001/001.jpg';
    const targetMemCacheWidth = 1080;

    // Building CachedNetworkImage without maxWidthDiskCache should NOT throw assertion error
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CachedNetworkImage(
            imageUrl: testImageUrl,
            cacheManager: CustomCacheManager.instance,
            httpHeaders: AppConstants.imageHeaders,
            memCacheWidth: targetMemCacheWidth,
            fit: BoxFit.fitWidth,
            placeholder: (context, url) => const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });
}
