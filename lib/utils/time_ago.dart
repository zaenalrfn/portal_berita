String timeAgo(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 60) {
    return "${diff.inSeconds} detik lalu";
  } else if (diff.inMinutes < 60) {
    return "${diff.inMinutes} menit lalu";
  } else if (diff.inHours < 24) {
    return "${diff.inHours} jam lalu";
  } else if (diff.inDays < 7) {
    return "${diff.inDays} hari lalu";
  } else if (diff.inDays < 30) {
    return "${(diff.inDays / 7).floor()} minggu lalu";
  } else if (diff.inDays < 365) {
    return "${(diff.inDays / 30).floor()} bulan lalu";
  } else {
    return "${(diff.inDays / 365).floor()} tahun lalu";
  }
}
