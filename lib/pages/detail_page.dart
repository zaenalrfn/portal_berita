import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/news_service.dart';
import '../models/news_model.dart';
import '../models/comment_model.dart';
import '../pages/login_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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
        news!.comments.insert(0, created);
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // EDIT DIALOG
  void _editCommentDialog(CommentModel c) {
    final controller = TextEditingController(text: c.comment);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2B2623),
        title: const Text("Edit Comment", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Edit comment...",
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty) return;

              try {
                await newsService.editComment(c.id, newText);

                setState(() {
                  final index = news!.comments.indexWhere((x) => x.id == c.id);
                  news!.comments[index] = c.copyWith(comment: newText);
                });

                Navigator.pop(context);
              } catch (e) {
                debugPrint(e.toString());
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // DELETE DIALOG
  void _deleteComment(CommentModel c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2B2623),
        title: const Text("Delete Comment?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Are you sure you want to delete this comment?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await newsService.deleteComment(c.id);

                setState(() {
                  news!.comments.removeWhere((x) => x.id == c.id);
                });

                Navigator.pop(context);
              } catch (e) {
                debugPrint(e.toString());
              }
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.user?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF2B2623),
      appBar: AppBar(title: const Text("News Detail")),
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
                      Text(news!.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),

                      Text(
                        "by ${news!.user?.name}",
                        style: const TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 10),
                      Text(news!.content,
                          style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 20),

                      const Text("Comments",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 10),

                      // COMMENTS
                      for (final c in news!.comments)
                        ListTile(
                          title: Text(
                            c.user?.name ?? "Unknown",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            c.comment as String,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                c.createdAt
                                        ?.toLocal()
                                        .toString()
                                        .split(" ")
                                        .first ??
                                    "",
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                              const SizedBox(width: 8),

                              // OWNER ONLY → EDIT & DELETE
                              if (currentUserId == c.userId) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orangeAccent, size: 20),
                                  onPressed: () => _editCommentDialog(c),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteComment(c),
                                ),
                              ]
                            ],
                          ),
                        ),

                      const SizedBox(height: 10),

                      // ADD COMMENT
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Add a comment...",
                                hintStyle:
                                    const TextStyle(color: Colors.white54),
                                filled: true,
                                fillColor: const Color(0xFF3A332F),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange),
                            onPressed: _addComment,
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
