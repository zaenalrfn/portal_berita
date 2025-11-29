import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';
import 'detail_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => provider.fetch(),
        child: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.news.length,
                itemBuilder: (c, i) {
                  final item = provider.news[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => DetailPage(newsId: item.id))),
                    child: NewsCard(news: item),
                  );
                },
              ),
      ),
    );
  }
}
