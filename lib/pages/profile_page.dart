import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool _initialLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final prov = context.read<NewsProvider>();
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      if (!prov.loadingMoreMy && prov.hasMoreMy) prov.loadMoreMy();
    }
  }

  Future<void> _loadInitial() async {
    try {
      await context.read<NewsProvider>().fetchMyNews(page: 1, perPage: 10);
      if (mounted) setState(() => _initialLoaded = true);
    } catch (e) {
      debugPrint("Error fetchMyNews: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal memuat berita: $e")));
      }
    }
  }

  Future<void> _refresh() async {
    await context.read<NewsProvider>().fetchMyNews(page: 1, perPage: 10, refresh: true);
  }

  Future<void> _onEdit(NewsModel news) async {
    final result = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(builder: (_) => AddNewsPage(news: news)),
    );

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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _thumb(NewsModel item) {
    final thumb = item.thumbnail;
    final double size = 72;
    if (thumb != null && thumb.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          thumb,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbPlaceholder(size),
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return SizedBox(width: size, height: size, child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))));
          },
        ),
      );
    } else {
      return _thumbPlaceholder(size);
    }
  }

  Widget _thumbPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(6)),
      child: const Icon(Icons.image_not_supported, color: Colors.white54),
    );
  }

  /// Use same approach as Home: prefer comments?.length
  /// but fallback to possible API-provided fields (commentCount / commentsCount)
  int _getCommentCount(NewsModel item) {
    // Primary: local comments list length (matches HomePage)
    final int localLen = item.comments?.length ?? 0;

    // Fallback: named count fields that API might provide in list response
    try {
      final dynamic c1 = (item as dynamic).commentCount; // try commentCount
      if (c1 is int && c1 > localLen) return c1;
    } catch (_) {}

    try {
      final dynamic c2 = (item as dynamic).commentsCount; // try commentsCount
      if (c2 is int && c2 > localLen) return c2;
    } catch (_) {}

    // Default to localLen (0 if absent)
    return localLen;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final prov = context.watch<NewsProvider>();
    final user = auth.user;
    final myNews = prov.myNews;

    return Scaffold(
      backgroundColor: const Color(0xFF231F1D),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Column(
            children: [
              // header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.orangeAccent,
                      child: Text(
                        (user?.name.isNotEmpty ?? false) ? user!.name.substring(0, 1).toUpperCase() : '?',
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(user?.name ?? 'Tamu', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(user?.email ?? '', style: TextStyle(color: Colors.grey[300], fontSize: 13)),
                    const SizedBox(height: 12),
                    Card(
                      color: const Color(0xFF3A332F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        title: const Text('Total Berita', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                        trailing: Text((user?.totalNews ?? 0).toString(), style: const TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: auth.isLoggedIn ? () async => await context.read<AuthProvider>().logout() : null,
                      child: const Text('Logout', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Berita Saya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        TextButton.icon(onPressed: _refresh, icon: const Icon(Icons.refresh, color: Colors.orangeAccent, size: 18), label: const Text('Refresh', style: TextStyle(color: Colors.orangeAccent))),
                      ],
                    ),
                  ],
                ),
              ),

              // list
              Expanded(
                child: Builder(builder: (context) {
                  if (prov.loadingMy && myNews.isEmpty && !_initialLoaded) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (myNews.isEmpty) {
                    return Center(child: Text('Belum ada berita', style: TextStyle(color: Colors.grey[400])));
                  }

                  return ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: myNews.length + (prov.hasMoreMy ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
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
                      final int commentCount = _getCommentCount(item);

                      return Card(
                        color: const Color(0xFF2F2A27),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          leading: _thumb(item),
                          title: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          // trailing: comment chip + edit + delete (compact, won't overflow)
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // comment chip
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF413732),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.comment, size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Text('$commentCount', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // edit button
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.lightBlueAccent, size: 20),
                                onPressed: () => _onEdit(item),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: 'Edit',
                              ),

                              // delete button or loader
                              _deletingId == item.id
                                  ? SizedBox(width: 32, height: 32, child: Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(strokeWidth: 2)))
                                  : IconButton(
                                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                                      onPressed: () => _onDelete(item.id),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                      tooltip: 'Hapus',
                                    ),
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
      ),
    );
  }
}
