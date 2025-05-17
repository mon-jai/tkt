import 'package:flutter/material.dart';
import '../models/discussion_model.dart';

class DiscussionScreen extends StatelessWidget {
  const DiscussionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 模擬討論區數據
    final discussions = [
      Discussion(
        id: '1',
        title: '請問有人知道圖書館閱覽室的使用規則嗎？',
        content: '最近想去圖書館閱覽室讀書，但不太清楚使用規則...',
        createTime: DateTime.now().subtract(const Duration(hours: 2)),
        author: '新生提問',
        category: '校園生活',
        likes: 5,
        comments: 3,
        tags: ['圖書館', '問題諮詢'],
      ),
      Discussion(
        id: '2',
        title: '推薦學校附近的美食',
        content: '分享一下最近發現的好吃餐廳...',
        createTime: DateTime.now().subtract(const Duration(hours: 5)),
        author: '美食達人',
        category: '美食分享',
        likes: 15,
        comments: 8,
        tags: ['美食', '推薦'],
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: discussions.length,
          itemBuilder: (context, index) {
            final discussion = discussions[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () {
                  // TODO: 實現查看討論詳情
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        discussion.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        discussion.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final tag in discussion.tags ?? [])
                            Chip(
                              label: Text(tag),
                              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                              labelStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            discussion.author,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(
                                Icons.thumb_up_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                discussion.likes.toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 16),
                              Icon(
                                Icons.comment_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                discussion.comments.toString(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
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
          // TODO: 實現新增討論功能
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 