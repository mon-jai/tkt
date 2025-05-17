import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/announcement_provider.dart';
import 'announcement_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 在頁面加載時獲取公告
    Future.microtask(() => 
      context.read<AnnouncementProvider>().fetchAnnouncements()
    );
  }

  void _openAnnouncementDetail(BuildContext context, announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailScreen(
          announcement: announcement,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('台科大最新公告'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<AnnouncementProvider>().fetchAnnouncements();
            },
          ),
        ],
      ),
      body: Consumer<AnnouncementProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.fetchAnnouncements();
                    },
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }

          if (provider.announcements.isEmpty) {
            return const Center(child: Text('目前沒有公告'));
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchAnnouncements(),
            child: ListView.builder(
              itemCount: provider.announcements.length,
              itemBuilder: (context, index) {
                final announcement = provider.announcements[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(
                      announcement.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(announcement.date),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _openAnnouncementDetail(context, announcement),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
} 