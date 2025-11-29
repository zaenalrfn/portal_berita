import 'package:flutter/material.dart';
import '../models/news_model.dart';
import '../services/news_service.dart';

class NewsProvider extends ChangeNotifier {
  final NewsService service;
  List<NewsModel> news = [];
  bool loading = false;

  NewsProvider(this.service);

  Future<void> fetch() async {
    loading = true; notifyListeners();
    try {
      news = await service.fetchAll();
    } catch (e) {
      news = [];
    } finally {
      loading = false; notifyListeners();
    }
  }
}
