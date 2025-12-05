import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/news_provider.dart';
import '../models/news_model.dart';
import 'add_news_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ScrollController _scrollController = ScrollController();
  int? _deletingId;
  bool _initialLoaded = false; // tahu kalau initial load sudah selesai

  @override
  void initState() {
    super.initState();

    // initial load page 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });

    // infinite scroll listener
    _scrollController.addListener(() {
      final prov = context.read<NewsProvider>();
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      // jika mendekati bottom (200 px) -> load more
      if (pos.pixels >= pos.maxScrollExtent - 200) {
        if (!prov.loadingMoreMy && prov.hasMoreMy) prov.loadMoreMy();
      }
    });
  }

  Future<void> _loadInitial() async {
    try {
      await context.read<NewsProvider>().fetchMyNews(page: 1, perPage: 5);
      setState(() => _initialLoaded = true);
    } catch (e) {
      debugPrint("Error fetchMyNews: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat berita: $e")));
      }
    }
  }

  Future<void> _refresh() async {
    await context.read<NewsProvider>().fetchMyNews(page: 1, perPage: 5, refresh: true);
  }

  Future<void> _onEdit(NewsModel news) async {
    final result = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(builder: (_) => AddNewsPage(news: news)),
    );

    // reload page 1 setelah edit
    await _refresh();
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perubahan tersimpan")));
    }
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Berita'),
        content: const Text('Apakah Anda yakin ingin menghapus berita ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _deletingId = id);
    try {
      await context.read<NewsProvider>().deleteNews(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berita berhasil dihapus')));
        // refresh page 1 supaya konsisten
        await _refresh();
      }
    } catch (e) {
      debugPrint("deleteNews error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus berita: $e')));
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildThumb(NewsModel item) {
    final thumb = item.thumbnail;
    if (thumb != null && thumb.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          thumb,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbPlaceholder(),
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return SizedBox(width: 72, height: 72, child: Center(child: CircularProgressIndicator()));
          },
        ),
      );
    } else {
      return _thumbPlaceholder();
    }
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.white54),
    );
  }

  String _shortExcerpt(String? content) {
    if (content == null) return '';
    return content.length <= 90 ? content : '${content.substring(0, 90)}...';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<NewsProvider>();
    final user = auth.user;
    final myNews = prov.myNews;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            // header (profile info)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orangeAccent,
                    child: Text(
                      (user?.name.isNotEmpty ?? false) ? user!.name.substring(0, 1).toUpperCase() : '?',
                      style: const TextStyle(fontSize: 28, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'Guest', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: TextStyle(color: Colors.grey[300])),
                  const SizedBox(height: 12),
                  Card(
                    color: const Color(0xFF3A332F),
                    child: ListTile(
                      title: const Text('News Created', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                      trailing: Text((user?.totalNews ?? 0).toString(), style: const TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                    onPressed: auth.isLoggedIn ? () async => await context.read<AuthProvider>().logout() : null,
                    child: const Text('Logout', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('My News', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh), label: const Text('Refresh')),
                    ],
                  ),
                ],
              ),
            ),

            // list area
            Expanded(
              child: Builder(builder: (context) {
                // show initial loader if provider.loadingMy true and no items yet
                if (prov.loadingMy && myNews.isEmpty && !_initialLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (myNews.isEmpty) {
                  return Center(child: Text('Belum ada berita', style: TextStyle(color: Colors.grey[400])));
                }

                return ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: myNews.length + (prov.hasMoreMy ? 1 : 0), // extra slot for loadingMore
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    // footer loader
                    if (index >= myNews.length) {
                      if (prov.loadingMoreMy) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }

                    final item = myNews[index];
                    return Card(
                      color: const Color(0xFF2F2A27),
                      child: ListTile(
                        leading: _buildThumb(item),
                        title: Text(item.title, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(_shortExcerpt(item.content), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[400])),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(onPressed: () => _onEdit(item), icon: const Icon(Icons.edit, color: Colors.lightBlueAccent)),
                            _deletingId == item.id
                                ? SizedBox(width: 36, height: 36, child: Padding(padding: const EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2)))
                                : IconButton(onPressed: () => _onDelete(item.id), icon: const Icon(Icons.delete_forever, color: Colors.redAccent)),
                          ],
                        ),
                        onTap: () => _onEdit(item),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
