import 'package:flutter/material.dart';
import '../models/news_model.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class NewsCard extends StatelessWidget {
  final NewsModel news;
  const NewsCard({required this.news});

  String formatTanggal(DateTime dt) {
    return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(dt);
  }

  // estimate lines needed based on text length (fast, no costly layout measuring)
  int _estimateLines(String text, int approxCharsPerLine, int maxLines) {
    final len = text.trim().length;
    if (len == 0) return 1;
    return min(maxLines, (len / approxCharsPerLine).ceil().clamp(1, maxLines));
  }

  @override
  Widget build(BuildContext context) {
    // estimate number of visual lines for title & excerpt
    final titleLines = _estimateLines(news.title ?? '', 28, 2); // title usually 1-2 lines
    final excerptLines = _estimateLines(news.content ?? '', 50, 5); // excerpt up to 5 lines

    // estimate height: title + meta + excerpt + paddings (values tuned empirically)
    final double lineHeight = 18.0;
    final double titleBlock = titleLines * lineHeight + 6; // small gap after title
    final double metaBlock = 16.0; // author/date line
    final double excerptBlock = excerptLines * (lineHeight);
    final double paddingBlock = 20.0 + 20.0; // vertical paddings inside card

    // If there is a comment chip, reserve a small extra vertical room so the meta row + chip won't push content.
    final int commentCount = (news.comments?.length ?? 0);
    final double extraForChip = commentCount > 0 ? 10.0 : 0.0;

    double thumbHeight = titleBlock + metaBlock + excerptBlock + paddingBlock + extraForChip;

    // clamp height so UI stays consistent across items
    thumbHeight = thumbHeight.clamp(100.0, 240.0);

    const double thumbWidth = 120.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF332c29),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.hardEdge,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail (fixed width, adaptive height)
          SizedBox(
            width: thumbWidth,
            height: thumbHeight,
            child: Container(
              color: const Color(0xFF2F2A27),
              child: news.thumbnailUrl == null
                  ? Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.white54, size: 36),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(0),
                      ),
                      child: Image.network(
                        news.thumbnailUrl!,
                        width: thumbWidth,
                        height: thumbHeight,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.black26,
                            child: Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.red.shade900,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.broken_image, color: Colors.white, size: 30),
                                SizedBox(height: 4),
                                Text('Gagal muat', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),

          // Content area: use SizedBox with same height to avoid parentData/semantics issues
          Expanded(
            child: SizedBox(
              height: thumbHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title + meta
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          news.title,
                          maxLines: titleLines,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.18,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Meta row: author/date on left, comment chip on right
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ditulis oleh ${news.user?.name ?? "-"} • ${news.publishedAt != null ? formatTanggal(news.publishedAt!) : "-"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[300], fontSize: 12),
                              ),
                            ),

                            // komentar chip (UI-only) - smaller vertical padding to reduce required height
                            if (commentCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF413732),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.comment, size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$commentCount',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    // Excerpt placed bottom to balance card
                    Text(
                      news.content.length > (excerptLines * 50)
                          ? '${news.content.substring(0, min(news.content.length, excerptLines * 50))}...'
                          : news.content,
                      maxLines: excerptLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[200], fontSize: 13, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
