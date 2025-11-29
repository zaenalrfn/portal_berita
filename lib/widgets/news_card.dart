import 'package:flutter/material.dart';
import '../models/news_model.dart';

class NewsCard extends StatelessWidget {
  final NewsModel news;
  const NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF3A332F),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (news.thumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(news.thumbnail!, width: 90, height: 70, fit: BoxFit.cover),
              )
            else
              Container(width: 90, height: 70, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(news.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text('by ${news.user?.name} • ${news.publishedAt.toLocal().toString().split(' ').first}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[300])),
                const SizedBox(height: 6),
                Text(news.content.length > 90 ? '${news.content.substring(0, 90)}...' : news.content,
                    style: TextStyle(color: Colors.grey[200], fontSize: 13)),
              ]),
            )
          ],
        ),
      ),
    );
  }
}
