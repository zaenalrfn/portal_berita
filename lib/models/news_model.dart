import 'comment_model.dart';
import 'user_model.dart';

class NewsModel {
  final int id;
  final int userId;
  final String title;
  final String slug;
  final String content;
  final String? thumbnail;
  final String? thumbnailUrl;
  final DateTime? publishedAt;
  final DateTime? createdAt;
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
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.thumbnailUrl,
    required this.comments,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final user = json['user'] != null ? UserModel.fromJson(Map<String, dynamic>.from(json['user'])) : null;

    final commentsJson = json['comments'];
    final comments = (commentsJson is List)
        ? commentsJson.map((e) => CommentModel.fromJson(Map<String, dynamic>.from(e))).toList()
        : <CommentModel>[];

    return NewsModel(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse('${json['user_id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      publishedAt: parseDate(json['published_at']),
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      user: user,
      comments: comments,
    );
  }
}
