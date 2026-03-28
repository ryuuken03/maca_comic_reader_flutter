import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'presentation/providers/comic_provider.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/detail_page.dart';
import 'presentation/pages/reader_page.dart';
import 'presentation/pages/bookmark_page.dart';
import 'presentation/pages/comic_list_page.dart';

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
        GoRoute(
          path: '/list',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return ComicListPage(
              title: extra['title'] as String? ?? 'Komik',
              preset: extra['preset'] as String?,
              type: extra['type'] as String?,
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Komik App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      theme: ThemeData.light(), // Fallback
      routerConfig: _router,
    );
  }
}
