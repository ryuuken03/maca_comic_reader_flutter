import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/chapter_model.dart';
import '../providers/library_provider.dart';

class ChapterTile extends StatelessWidget {
  final ChapterModel chapter;
  final String comicUrl;

  const ChapterTile({Key? key, required this.chapter, required this.comicUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final actIndexStr = chapter.link.split('/').lastWhere((e) => e.isNotEmpty, orElse: () => '');
    
    return ListTile(
      title: Text(chapter.title),
      subtitle: chapter.releaseDate != null ? Text(chapter.releaseDate!) : null,
      trailing: Consumer<LibraryProvider>(
        builder: (context, library, child) {
          return FutureBuilder<bool>(
            future: library.isBookmarkedReader(comicUrl, actIndexStr),
            builder: (context, snapshot) {
              final isBookmarked = snapshot.data ?? false;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   if (isBookmarked) 
                    const Icon(Icons.bookmark, color: Color(0xFFFDD644), size: 18),
                  const Icon(Icons.chevron_right),
                ],
              );
            },
          );
        },
      ),
      onTap: () {
        context.push('/reader', extra: {
          'chapterUrl': chapter.link,
          'fromDetail': true,
        });
      },
    );
  }
}
