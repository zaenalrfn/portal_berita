import 'dart:convert';
import '../models/news_model.dart';
import '../models/comment_model.dart';
import 'api_client.dart';

class NewsService {
  final ApiClient api;
  NewsService(this.api);

  Future<List<NewsModel>> fetchAll() async {
    final r = await api.get('/api/news');
    if (r.statusCode == 200) {
      final j = jsonDecode(r.body);

      final list = j['data']['data'] as List;

      return list.map((e) => NewsModel.fromJson(e)).toList();
    }
    throw Exception('Failed load news');
  }

  Future<NewsModel> fetchDetail(int id) async {
    final r = await api.get('/api/news/$id');
    if (r.statusCode == 200) {
      final j = jsonDecode(r.body);

      final data = j['data'];

      return NewsModel.fromJson(data);
    }
    throw Exception('Failed fetch detail');
  }

  Future<NewsModel> create(Map<String, dynamic> payload) async {
    // payload might include base64 or form-data for image - adapt per your API
    final r = await api.post(
      '/api/news',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (r.statusCode == 201 || r.statusCode == 200) {
      return NewsModel.fromJson(jsonDecode(r.body));
    }
    throw Exception('Failed create news: ${r.body}');
  }

  Future<void> update(int id, Map<String, dynamic> payload) async {
    final r = await api.put(
      '/api/news/$id',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (r.statusCode != 200) throw Exception('Failed update: ${r.body}');
  }

  Future<void> delete(int id) async {
    final r = await api.delete('/api/news/$id');
    if (r.statusCode != 200) throw Exception('Failed delete');
  }

  Future<CommentModel> addComment(int newsId, String commentText) async {
    final payload = jsonEncode({'news_id': newsId, 'comment': commentText});

    final resp = await api.post(
      '/api/comments',
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    // Accept 200 or 201 as success
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final j = jsonDecode(resp.body);

      final commentJson = (j is Map && j.containsKey('data')) ? j['data'] : j;

      // Pastikan commentJson adalah Map
      if (commentJson is Map<String, dynamic>) {
        return CommentModel.fromJson(commentJson);
      } else if (commentJson is Map) {
        // safety: cast jika tipe Map non-generic
        return CommentModel.fromJson(Map<String, dynamic>.from(commentJson));
      } else {
        throw Exception(
          'Unexpected comment data format: ${commentJson.runtimeType}',
        );
      }
    } else if (resp.statusCode == 422) {
      // validation error (Laravel)
      final j = jsonDecode(resp.body);
      throw Exception('Validation failed: ${j}');
    } else {
      throw Exception('Failed add comment: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> editComment(int newsId, String body) async {
    final r = await api.put(
      '/api/comments/$newsId',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'body': body}),
    );
    if (r.statusCode != 200) throw Exception('Failed update: ${r.body}');
  }

  Future<void> deleteComment(int newsId) async {
    final r = await api.delete('/api/comments/$newsId');
    if (r.statusCode != 200) throw Exception('Failed delete');
  }
}
