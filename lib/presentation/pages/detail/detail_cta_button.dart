import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DetailCtaButton extends StatelessWidget {
  final String? targetChapterUrl;
  final String ctaLabel;
  final bool isContinue;

  const DetailCtaButton({
    super.key,
    required this.targetChapterUrl,
    required this.ctaLabel,
    required this.isContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: targetChapterUrl != null
            ? () {
                context.push('/reader', extra: {
                  'chapterUrl': targetChapterUrl,
                  'fromDetail': true,
                });
              }
            : null,
        icon: Icon(
          isContinue ? Icons.play_arrow_rounded : Icons.menu_book_rounded,
          size: 18,
        ),
        label: Text(
          ctaLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFDD644),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
