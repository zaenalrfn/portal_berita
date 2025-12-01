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
    this.user,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      newsId: json['news_id'],
      userId: json['user_id'],
      comment: json['comment'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    );
  }

  // Tambahkan copyWith agar update comment gampang
  CommentModel copyWith({
    String? comment,
    DateTime? updatedAt,
  }) {
    return CommentModel(
      id: id,
      newsId: newsId,
      userId: userId,
      comment: comment ?? this.comment,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user,
    );
  }
}
