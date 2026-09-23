import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maca/core/utils/adaptive_utils.dart';

void main() {
  group('Adaptive Grid Take Tests', () {
    testWidgets('Returns 20 when column count is even (e.g., 2 columns on 360dp phone)', (tester) async {
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(360, 800)),
            child: Builder(
              builder: (context) {
                result = getAdaptiveGridTake(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, equals(20));
    });

    testWidgets('Returns 21 when column count is odd (e.g., 3 columns on 600dp mini-tablet/foldable)', (tester) async {
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(600, 800)),
            child: Builder(
              builder: (context) {
                result = getAdaptiveGridTake(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, equals(21));
    });

    testWidgets('Returns 20 when column count is even on tablet (800dp - 80dp rail = 720dp, 4 columns)', (tester) async {
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(800, 1000)),
            child: Builder(
              builder: (context) {
                result = getAdaptiveGridTake(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, equals(20));
    });

    testWidgets('Returns 21 when column count is odd on large tablet/desktop (1000dp - 80dp rail = 920dp, 5 columns)', (tester) async {
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1000, 800)),
            child: Builder(
              builder: (context) {
                result = getAdaptiveGridTake(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(result, equals(21));
    });
  });
}
