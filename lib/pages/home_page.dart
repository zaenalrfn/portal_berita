import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScrollController _sc;

  @override
  void initState() {
    super.initState();
    _sc = ScrollController()..addListener(_onScroll);

    // fetch initial after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<NewsProvider>();
      provider.fetchInitial();
    });
  }

  void _onScroll() {
    final prov = context.read<NewsProvider>();
    if (_sc.position.pixels >= _sc.position.maxScrollExtent - 200) {
      // near bottom -> load more
      if (!prov.loadingMore && prov.hasMore) prov.loadMore();
    }
  }

  @override
  void dispose() {
    _sc.removeListener(_onScroll);
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => provider.refresh(),
        child: provider.loading && provider.news.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _sc,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: provider.news.length + (provider.loadingMore ? 1 : 0),
                itemBuilder: (c, i) {
                  if (i < provider.news.length) {
                    final item = provider.news[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        c,
                        MaterialPageRoute(
                          builder: (_) => DetailPage(newsId: item.id),
                        ),
                      ),
                      child: NewsCard(news: item),
                    );
                  } else {
                    // loading more footer
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                },
              ),
      ),
    );
  }
}
