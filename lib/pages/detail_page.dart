import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/news_service.dart';
import '../models/news_model.dart';
import '../models/comment_model.dart';
import '../pages/login_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart' as ac;

class DetailPage extends StatefulWidget {
  final int newsId;
  const DetailPage({required this.newsId});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late NewsService newsService;
  NewsModel? news;
  bool loading = false;
  final commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final api = ApiClient(baseUrl: 'http://api-portal-berita.test');
    newsService = NewsService(api);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      news = await newsService.fetchDetail(widget.newsId);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _addComment() async {
    final auth = context.read<AuthProvider>();

    if (!auth.isLoggedIn) {
      final didLogin = await showDialog<bool>(
        context: context,
        builder: (_) => LoginDialog(),
      );
      if (didLogin != true) return;
      await context.read<AuthProvider>().loadProfile();
    }

    final text = commentController.text.trim();
    if (text.isEmpty) return;

    try {
      final created = await newsService.addComment(widget.newsId, text);
      commentController.clear();

      setState(() {
        news!.comments.insert(0, created); // <--- langsung masuk ke model
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2623),
      appBar: AppBar(title: const Text('News Detail')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : news == null
              ? const Center(child: Text("Failed to load"))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (news!.thumbnail != null)
                        Image.network(news!.thumbnail!),
                      const SizedBox(height: 12),

                      Text(
                        news!.title,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'by ${news!.user?.name} • ${news!.publishedAt.toLocal().toString().split(" ").first}',
                        style: TextStyle(color: Colors.grey[300]),
                      ),

                      const SizedBox(height: 12),
                      Text(
                        news!.content,
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 12),

                      const Text("Comments",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),

                      // 💬 Tampilkan semua komentar
                      for (final c in news!.comments)
                        ListTile(
                          title: Text(
                            c.user?.name ?? "Unknown",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            c.comment ?? "",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: Text(
                            c.createdAt
                                    ?.toLocal()
                                    .toString()
                                    .split(' ')
                                    .first ??
                                "",
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400]),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Input komentar
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              decoration: InputDecoration(
                                hintText: "Add a comment",
                                filled: true,
                                fillColor: const Color(0xFF3A332F),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _addComment,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange),
                            child: const Text("Post"),
                          )
                        ],
                      )
                    ],
                  ),
                ),
    );
  }
}

