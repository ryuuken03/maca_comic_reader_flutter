String timeAgo(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final parsedDate = DateTime.parse(dateStr);
    final difference = DateTime.now().difference(parsedDate);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lalu';
    } else {
      return 'Baru saja';
    }
  } catch (e) {
    return dateStr; // Fallback jika tidak standard
  }
}
