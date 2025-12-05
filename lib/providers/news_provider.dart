import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';

class NewsProvider extends ChangeNotifier {
  final NewsService service;

  NewsProvider(this.service);

  // === DATA LIST ===
  List<NewsModel> news = [];
  List<NewsModel> myNews = [];

  // === PAGINATION ===
  int currentPage = 0;
  int lastPage = 1;
  int perPage = 10;

  bool loading = false;
  bool loadingMore = false;

  // PAGINATE MY NEWS
  int currentPageMy = 0;
  int lastPageMy = 1;
  int perPageMy = 5;
  bool loadingMy = false;
  bool loadingMoreMy = false;

  NewsModel _toNewsModel(dynamic e) {
    if (e is NewsModel) return e;
    if (e is Map<String, dynamic>) return NewsModel.fromJson(e);
    if (e is Map) return NewsModel.fromJson(Map<String, dynamic>.from(e));
    throw Exception('Unsupported item type: ${e.runtimeType}');
  }

  // ============================================================
  // FETCH INITIAL (page 1)
  // ============================================================
  Future<void> fetchInitial({int perPageOverride = 10}) async {
    perPage = perPageOverride;
    loading = true;
    notifyListeners();

    try {
      final res = await service.fetchPage(page: 1, perPage: perPage);

      news = res['items'];
      currentPage = res['current_page'];
      lastPage = res['last_page'];
    } catch (e) {
      debugPrint("fetchInitial error: $e");
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // LOAD MORE (pagination)
  // ============================================================
  Future<void> loadMore() async {
    if (loadingMore) return;
    if (currentPage >= lastPage) return;

    loadingMore = true;
    notifyListeners();

    try {
      final next = currentPage + 1;
      final res = await service.fetchPage(page: next, perPage: perPage);

      news.addAll(res['items']);
      currentPage = res['current_page'];
      lastPage = res['last_page'];
    } catch (e) {
      debugPrint("loadMore error: $e");
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  // ============================================================
  // REFRESH NEWS (pull to refresh)
  // ============================================================
  Future<void> refresh() async {
    await fetchInitial(perPageOverride: perPage);
  }

  bool get hasMore => currentPage < lastPage;

  // ============================================================
  // FETCH NEWS BY USER LOGIN
  // ============================================================
  Future<void> fetchMyNews({int page = 1, int perPage = 5, bool refresh = false}) async {
    // Guards
    if (page == 1 && loadingMy && !refresh) return;
    if (page > 1 && loadingMoreMy) return;

    if (page == 1) {
      loadingMy = true;
      notifyListeners();
    } else {
      loadingMoreMy = true;
      notifyListeners();
    }

    try {
      // service.fetchMyNews now returns Map paginated (see NewsService)
      final res = await service.fetchMyNews(page: page, perPage: perPage);

      final itemsRaw = (res['data'] ?? []) as List<dynamic>;
      final items = itemsRaw.map((e) => _toNewsModel(e)).toList();

      final current = res['current_page'] is int
          ? res['current_page'] as int
          : int.tryParse('${res['current_page']}') ?? page;
      final last = res['last_page'] is int
          ? res['last_page'] as int
          : int.tryParse('${res['last_page']}') ?? page;

      if (page == 1) {
        myNews = items;
      } else {
        // hindari duplikat
        final existingIds = myNews.map((m) => m.id).toSet();
        final toAdd = items.where((it) => !existingIds.contains(it.id)).toList();
        myNews.addAll(toAdd);
      }

      currentPageMy = current;
      lastPageMy = last;
      perPageMy = perPage;
      notifyListeners();
    } catch (e) {
      debugPrint("fetchMyNews error: $e");
      rethrow;
    } finally {
      if (page == 1) {
        loadingMy = false;
      } else {
        loadingMoreMy = false;
      }
      notifyListeners();
    }
  }

  bool get hasMoreMy => currentPageMy < lastPageMy;

  Future<void> loadMoreMy() async {
    if (!hasMoreMy) return;
    if (loadingMoreMy) return;
    final next = (currentPageMy <= 0) ? 2 : (currentPageMy + 1);
    await fetchMyNews(page: next, perPage: perPageMy);
  }

  // ============================================================
  // CREATE NEWS - JSON only (no image)
  // ============================================================
  Future<NewsModel> createNews(Map<String, dynamic> payload) async {
    try {
      final created = await service.create(payload);
      news.insert(0, created);
      myNews.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      debugPrint("createNews error: $e");
      rethrow;
    }
  }

  // ============================================================
  // CREATE NEWS MULTIPART (Android/iOS/File) OR (Web/Bytes)
  // ============================================================
  Future<NewsModel> createNewsMultipart({
    required String title,
    required String content,
    File? fileImage,
    Uint8List? webImage, File? imageFile,
  }) async {
    try {
      final created = await service.createMultipart(
        title: title,
        content: content,
        fileImage: fileImage,   // mobile
        webImage: webImage,     // web
      );

      news.insert(0, created);
      myNews.insert(0, created);
      notifyListeners();

      return created;
    } catch (e) {
      debugPrint("createNewsMultipart error: $e");
      rethrow;
    }
  }

  // ============================================================
  // UPDATE (JSON)
  // ============================================================
  Future<void> updateNews(int id, Map<String, dynamic> payload) async {
    try {
      await service.update(id, payload);

      final updated = await service.fetchDetail(id);

      final idx = news.indexWhere((n) => n.id == id);
      if (idx != -1) news[idx] = updated;

      final idx2 = myNews.indexWhere((n) => n.id == id);
      if (idx2 != -1) myNews[idx2] = updated;

      notifyListeners();
    } catch (e) {
      debugPrint('updateNews error: $e');
      rethrow;
    }
  }

  // ============================================================
  // UPDATE NEWS MULTIPART (Android/iOS/Web)
  // ============================================================
  Future<void> updateNewsMultipart({
    required int id,
    required String title,
    required String content,
    File? fileImage,
    Uint8List? webImage, File? imageFile,
  }) async {
    try {
      await service.updateMultipart(
        id: id,
        title: title,
        content: content,
        fileImage: fileImage,
        webImage: webImage,
      );

      await refresh(); // refresh public
    } catch (e) {
      debugPrint("updateNewsMultipart error: $e");
      rethrow;
    }
  }

  // ============================================================
  // DELETE NEWS
  // ============================================================
  Future<void> deleteNews(int id) async {
    try {
      await service.delete(id);
      news.removeWhere((n) => n.id == id);
      myNews.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint("deleteNews error: $e");
      rethrow;
    }
  }
}
