import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news_model.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart';

class NewsCard extends StatelessWidget {
  final NewsModel news;
  const NewsCard({required this.news});
  
  String formatTanggal(DateTime dt) {
    return DateFormat('dd MMMM yyyy • HH:mm', 'id_ID').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Print URL
    if (news.thumbnailUrl != null) {
      print("=== DEBUG IMAGE URL ===");
      print("Thumbnail URL: ${news.thumbnailUrl}");
    }

    return Card(
      color: const Color(0xFF3A332F),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: news.thumbnailUrl == null
                  ? Container(
                      width: 90,
                      height: 70,
                      color: Colors.black26,
                      child: const Icon(Icons.image_not_supported, color: Colors.white54),
                    )
                  : Image.network(
                      news.thumbnailUrl!,
                      width: 90,
                      height: 70,
                      fit: BoxFit.cover,
                      
                      // Loading indicator
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Container(
                          width: 90,
                          height: 70,
                          color: Colors.black26,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      
                      // Error handler dengan debug info
                      errorBuilder: (context, error, stackTrace) {
                        print("=== IMAGE ERROR ===");
                        print("URL: ${news.thumbnailUrl}");
                        print("Error: $error");
                        print("StackTrace: $stackTrace");
                        
                        return Container(
                          width: 90,
                          height: 70,
                          color: Colors.red.shade900,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.broken_image, color: Colors.white, size: 30),
                              const SizedBox(height: 4),
                              Text(
                                'Error',
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(news.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                    'Ditulis oleh ${news.user?.name ?? "-"} • ${formatTanggal(news.publishedAt!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    news.content.length > 90
                        ? '${news.content.substring(0, 90)}...'
                        : news.content,
                    style: TextStyle(color: Colors.grey[200], fontSize: 13),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
