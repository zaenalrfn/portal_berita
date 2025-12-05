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
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

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
    _searchController.dispose();
    super.dispose();
  }

  List filteredList(List all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((item) {
      final t = (item.title ?? '').toString().toLowerCase();
      final c = (item.content ?? '').toString().toLowerCase();
      return t.contains(q) || c.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();
    final visibleNews = filteredList(provider.news);

    return Scaffold(
      backgroundColor: const Color(0xFF231F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B2623),
        elevation: 0.5,
        title: const Text(
          'Berita',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar (client-side)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Material(
                color: const Color(0xFF2B2623),
                borderRadius: BorderRadius.circular(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.orange,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    hintText: 'Cari judul atau isi berita...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close, color: Colors.white70),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),

            // Content list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.refresh(),
                child: provider.loading && provider.news.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: visibleNews.isEmpty
                            ? Center(
                                child: Text(
                                  provider.news.isEmpty ? 'Belum ada berita' : 'Hasil pencarian tidak ditemukan',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              )
                            : ListView.separated(
                                controller: _sc,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: visibleNews.length + (provider.loadingMore ? 1 : 0),
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (c, i) {
                                  if (i < visibleNews.length) {
                                    final item = visibleNews[i];
                                    return Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(14),
                                        onTap: () => Navigator.push(
                                          c,
                                          MaterialPageRoute(
                                            builder: (_) => DetailPage(newsId: item.id),
                                          ),
                                        ),
                                        child: NewsCard(news: item),
                                      ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
