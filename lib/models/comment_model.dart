import 'user_model.dart';
class CommentModel {
  final int id;
  final int? newsId;
  final int? userId;
  final String? comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final UserModel? user;

  CommentModel({
    required this.id,
    this.newsId,
    this.userId,
    this.comment,
    this.createdAt,
    this.updatedAt,
    this.user
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      newsId: json['news_id'],
      userId: json['user_id'],
      comment: json['comment'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null
    );
  }
}