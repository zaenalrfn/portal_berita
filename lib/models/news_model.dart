import 'user_model.dart';
import 'comment_model.dart';
class NewsModel {
  final int id;
  final int userId;
  final String title;
  final String slug;
  final String content;
  final String? thumbnail;
  final DateTime publishedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final UserModel? user;
   final List<CommentModel> comments;

  NewsModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.slug,
    required this.content,
    this.thumbnail,
    required this.publishedAt,
    required this.createdAt,
    this.updatedAt,
    this.user,
    required this.comments,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      slug: json['slug'],
      content: json['content'],
      publishedAt: DateTime.parse(json['published_at'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      comments: json['comments'] != null
          ? (json['comments'] as List)
              .map((c) => CommentModel.fromJson(c))
              .toList()
          : [],
    );
  }
}