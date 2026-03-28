import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'presentation/providers/comic_provider.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/detail_page.dart';
import 'presentation/pages/reader_page.dart';
import 'presentation/pages/bookmark_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ComicProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomePage()),
        GoRoute(
          path: '/detail',
          builder: (context, state) {
            final comicUrl = state.extra as String;
            return DetailPage(comicUrl: comicUrl);
          },
        ),
        GoRoute(
          path: '/reader',
          builder: (context, state) {
            final chapterUrl = state.extra as String;
            return ReaderPage(chapterUrl: chapterUrl);
          },
        ),
        GoRoute(
          path: '/bookmark',
          builder: (context, state) => const BookmarkPage(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Komik App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: _router,
    );
  }
}
