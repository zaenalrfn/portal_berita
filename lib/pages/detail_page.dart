import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/news_service.dart';
import '../models/news_model.dart';
import '../models/comment_model.dart';
import '../pages/login_dialog.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/time_ago.dart';

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
   WidgetsBinding.instance.addPostFrameCallback((_) {
      final api = Provider.of<ApiClient>(context, listen: false);
      newsService = NewsService(api);
      _load();
    });
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),

      title: Row(
        children: [
          const Icon(Icons.edit, color: Colors.deepOrange),
          const SizedBox(width: 10),
          const Text(
            "Edit komen",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ],
      ),

      content: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.deepOrange,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF3A332F),
          hintText: "Edit komen...",
          hintStyle: const TextStyle(color: Colors.white54),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepOrange, width: 1),
          ),
        ),
      ),

      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Batal",
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
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
          child: const Text(
            "Simpan",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
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
        title: const Text(
          "Hapus Komen?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Kamu yakin mau hapus komen ini?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
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
            child: const Text("Hapus", style: TextStyle(color: Colors.white),),
          ),
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
      appBar: AppBar(title: const Text("Detail Berita")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : news == null
          ? const Center(child: Text("Gagal memuat berita"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (news!.thumbnailUrl != null)
                    Image.network(news!.thumbnailUrl!),

                  const SizedBox(height: 12),
                  Text(
                    news!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),

                  Text(
                    "Ditulis oleh ${news!.user?.name}",
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    news!.content,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Komen",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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
                            c.createdAt != null
                                ? timeAgo(c.createdAt!.toLocal())
                                : "",
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // OWNER ONLY → EDIT & DELETE
                          if (currentUserId == c.userId) ...[
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.deepOrangeAccent,
                                size: 20,
                              ),
                              onPressed: () => _editCommentDialog(c),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () => _deleteComment(c),
                            ),
                          ],
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
                            hintText: "Tambah Komen...",
                            hintStyle: const TextStyle(color: Colors.white54),
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
                          backgroundColor: Colors.deepOrange,
                        ),
                        onPressed: _addComment,
                        child: const Text(
                          "Tambah",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
