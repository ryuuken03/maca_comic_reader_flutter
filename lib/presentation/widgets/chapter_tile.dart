import 'package:flutter/material.dart';
import '../../data/models/chapter_model.dart';
import 'package:go_router/go_router.dart';

class ChapterTile extends StatelessWidget {
  final ChapterModel chapter;

  const ChapterTile({Key? key, required this.chapter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(chapter.title),
      subtitle: chapter.releaseDate != null ? Text(chapter.releaseDate!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push('/reader', extra: chapter.link);
      },
    );
  }
}
