// lib/services/news_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import '../models/news_model.dart';
import '../models/comment_model.dart';
import 'api_client.dart';

class NewsService {
  final ApiClient api;
  NewsService(this.api);

  // ============================================================
  // FETCH ALL (Fallback)
  // ============================================================
  Future<List<NewsModel>> fetchAll() async {
    final r = await api.get('/api/news');
    if (r.statusCode == 200) {
      final j = jsonDecode(r.body);

      dynamic data = j;
      if (j is Map && j.containsKey('data')) data = j['data'];

      final listJson = data is Map && data.containsKey('data') ? data['data'] : data;

      if (listJson is List) {
        return listJson
            .map((e) => NewsModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        throw Exception('Unexpected list format');
      }
    }
    throw Exception('Failed load news: ${r.statusCode} ${r.body}');
  }

  // ============================================================
  // PAGINATION
  // ============================================================
  Future<Map<String, dynamic>> fetchPage({
    int page = 1,
    int perPage = 10,
  }) async {
    final resp = await api.get('/api/news?page=$page&per_page=$perPage');

    if (resp.statusCode == 200) {
      final j = jsonDecode(resp.body);
      final data = j['data'] ?? j;

      final rawList = data['data'] ?? data;
      final items = (rawList as List)
          .map((e) => NewsModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      return {
        'items': items,
        'current_page': data['current_page'] ?? 1,
        'last_page': data['last_page'] ?? 1,
        'per_page': data['per_page'] ?? perPage,
        'total': data['total'] ?? items.length,
        'next_page_url': data['next_page_url'],
      };
    }

    throw Exception('Failed fetch page: ${resp.statusCode} ${resp.body}');
  }

  // ============================================================
  // DETAIL
  // ============================================================
  Future<NewsModel> fetchDetail(int id) async {
    final r = await api.get('/api/news/$id');
    if (r.statusCode == 200) {
      final j = jsonDecode(r.body);
      final data = j['data'] ?? j;
      return NewsModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Failed fetch detail: ${r.statusCode} ${r.body}');
  }

  // ============================================================
  // JSON CREATE
  // ============================================================
  Future<NewsModel> create(Map<String, dynamic> payload) async {
    final r = await api.post(
      '/api/news',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (r.statusCode == 201 || r.statusCode == 200) {
      final j = jsonDecode(r.body);
      final data = j['data'] ?? j;
      return NewsModel.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Create failed: ${r.statusCode} ${r.body}');
  }

  // ============================================================
  // JSON UPDATE
  // ============================================================
  Future<void> update(int id, Map<String, dynamic> payload) async {
    final r = await api.put(
      '/api/news/$id',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (r.statusCode != 200) {
      throw Exception('Update failed: ${r.statusCode} ${r.body}');
    }
  }

  // ============================================================
  // DELETE NEWS
  // ============================================================
  Future<void> delete(int id) async {
    final r = await api.delete('/api/news/$id');

    if (r.statusCode != 200) {
      throw Exception('Delete failed: ${r.statusCode} ${r.body}');
    }
  }

  // ============================================================
  // COMMENT CREATE
  // ============================================================
  Future<CommentModel> addComment(int newsId, String commentText) async {
    final payload = jsonEncode({
      'news_id': newsId,
      'comment': commentText,
    });

    final resp = await api.post(
      '/api/comments',
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final j = jsonDecode(resp.body);
      final data = j['data'] ?? j;
      return CommentModel.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Add comment failed: ${resp.statusCode} ${resp.body}');
  }

  // ============================================================
  // COMMENT UPDATE
  // ============================================================
  Future<void> editComment(int commentId, String commentText) async {
    final r = await api.put(
      '/api/comments/$commentId',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'comment': commentText}),
    );

    if (r.statusCode != 200) {
      throw Exception('Failed update comment: ${r.statusCode} ${r.body}');
    }
  }

  // ============================================================
  // COMMENT DELETE
  // ============================================================
  Future<void> deleteComment(int commentId) async {
    final r = await api.delete('/api/comments/$commentId');

    if (r.statusCode != 200) {
      throw Exception('Failed delete comment: ${r.statusCode} ${r.body}');
    }
  }

  // ============================================================
  // MULTIPART CREATE — SUPPORTS FILE & WEB BYTES
  // ============================================================
  Future<NewsModel> createMultipart({
    required String title,
    required String content,
    File? fileImage,      // Android/iOS
    Uint8List? webImage,  // Web
  }) async {
    final token = await api.getToken();

    final req = http.MultipartRequest(
      "POST",
      Uri.parse("${api.baseUrl}/api/news"),
    );

    req.headers['Authorization'] = "Bearer $token";
    req.fields['title'] = title;
    req.fields['content'] = content;

    if (fileImage != null) {
      req.files.add(await http.MultipartFile.fromPath(
        "thumbnail",
        fileImage.path,
      ));
    } else if (webImage != null) {
      req.files.add(http.MultipartFile.fromBytes(
        "thumbnail",
        webImage,
        filename: "web_image.png",
      ));
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    final j = jsonDecode(resp.body);

    return NewsModel.fromJson(j['data']);
  }

  // ============================================================
  // MULTIPART UPDATE (Laravel: POST + _method=PUT)
  // ============================================================
  Future<void> updateMultipart({
    required int id,
    required String title,
    required String content,
    File? fileImage,      // mobile
    Uint8List? webImage,  // web
  }) async {
    final token = await api.getToken();

    final req = http.MultipartRequest(
      "POST",
      Uri.parse("${api.baseUrl}/api/news/$id?_method=PUT"),
    );

    req.headers['Authorization'] = "Bearer $token";
    req.fields['title'] = title;
    req.fields['content'] = content;

    if (fileImage != null) {
      req.files.add(await http.MultipartFile.fromPath(
        "thumbnail",
        fileImage.path,
      ));
    } else if (webImage != null) {
      req.files.add(http.MultipartFile.fromBytes(
        "thumbnail",
        webImage,
        filename: "web_image.png",
      ));
    }

    final streamed = await req.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode != 200) {
      throw Exception('Update failed: ${resp.statusCode} ${resp.body}');
    }
  }

  // ============================================================
  // MY NEWS (fetch news by authenticated user)
  // ============================================================
  Future<Map<String, dynamic>> fetchMyNews({
    int page = 1,
    int perPage = 5,
  }) async {
    final path = '/api/user/news?page=$page&per_page=$perPage';
    final r = await api.get(path); 

    if (r.statusCode == 200) {
      final j = jsonDecode(r.body);
      final dataWrapper = (j is Map && j.containsKey('data')) ? j['data'] : j;

      final currentPage = dataWrapper['current_page'] is int
          ? dataWrapper['current_page'] as int
          : int.tryParse('${dataWrapper['current_page']}') ?? page;

      final lastPage = dataWrapper['last_page'] is int
          ? dataWrapper['last_page'] as int
          : int.tryParse('${dataWrapper['last_page']}') ?? page;

      final perPageResp = dataWrapper['per_page'] is int
          ? dataWrapper['per_page'] as int
          : int.tryParse('${dataWrapper['per_page']}') ?? perPage;

      final total = dataWrapper['total'] is int
          ? dataWrapper['total'] as int
          : int.tryParse('${dataWrapper['total']}') ?? 0;

      final list = (dataWrapper['data'] ?? dataWrapper['items'] ?? []) as List<dynamic>;

      return {
        'current_page': currentPage,
        'last_page': lastPage,
        'per_page': perPageResp,
        'total': total,
        'data': list,
      };
    }

    // debug membantu saat server mengembalikan error body
    throw Exception('Failed my news: ${r.statusCode} ${r.body}');
  }

}
