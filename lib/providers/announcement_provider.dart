import 'package:flutter/foundation.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';

class AnnouncementProvider with ChangeNotifier {
  final AnnouncementService _service = AnnouncementService();
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMoreData => _hasMoreData;

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMoreData = true;
    _announcements = [];
    return fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    if (_isLoading || (_isLoadingMore && !_hasMoreData)) return;

    final isFirstPage = _currentPage == 1;
    if (isFirstPage) {
      _isLoading = true;
    } else {
      _isLoadingMore = true;
    }
    _error = null;
    notifyListeners();

    try {
      final newAnnouncements = await _service.fetchAnnouncements(page: _currentPage);
      
      if (isFirstPage) {
        _announcements = newAnnouncements;
      } else {
        _announcements.addAll(newAnnouncements);
      }

      // 如果獲取的公告數量為0或小於預期，表示沒有更多數據
      _hasMoreData = newAnnouncements.isNotEmpty;
      if (_hasMoreData) {
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_isLoading && !_isLoadingMore && _hasMoreData) {
      await fetchAnnouncements();
    }
  }
} 