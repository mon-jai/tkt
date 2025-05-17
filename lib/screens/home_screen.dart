import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 模擬公告數據
    final announcements = [
      Announcement(
        id: '1',
        title: '期中考週調整事項公告',
        content: '因應期中考週，圖書館將延長開放時間至晚上11點...',
        publishDate: DateTime.now().subtract(const Duration(days: 1)),
        author: '教務處',
        category: '重要公告',
        isImportant: true,
      ),
      Announcement(
        id: '2',
        title: '校園公車時刻表更新',
        content: '自10月起，校園公車時刻表將進行調整...',
        publishDate: DateTime.now().subtract(const Duration(days: 2)),
        author: '總務處',
        category: '交通資訊',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  // TODO: 實現查看公告詳情
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (announcement.isImportant)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.priority_high, color: Colors.red),
                            ),
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        announcement.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Chip(
                            label: Text(announcement.category),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('yyyy/MM/dd').format(announcement.publishDate),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: 實現新增公告功能
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 