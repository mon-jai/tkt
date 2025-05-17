import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final _service = AnnouncementService();
  String? _content;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final content = await _service.fetchAnnouncementDetail(widget.announcement.link);
      if (mounted) {
        setState(() {
          _content = content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.announcement.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadContent();
              },
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (_content == null || _content!.isEmpty) {
      return const Center(child: Text('無內容'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顯示日期
          Text(
            widget.announcement.date,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          // 顯示標題
          Text(
            widget.announcement.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(height: 32),
          // 顯示內容
          Html(
            data: _content,
            style: {
              "body": Style(
                fontSize: FontSize(16),
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              "a": Style(
                color: Theme.of(context).colorScheme.primary,
              ),
            },
            onLinkTap: (url, _, __) {
              if (url != null) {
                // 如果需要在應用內打開連結，可以在這裡處理
                // 或者使用 url_launcher 在外部瀏覽器中打開
              }
            },
          ),
        ],
      ),
    );
  }
} 