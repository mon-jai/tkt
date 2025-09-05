import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tkt/screens/course/course_screen.dart';
import '../providers/announcement_provider.dart';
import '../services/course_service.dart';
import '../services/calendar_service.dart';
import 'announcement_screen.dart';
import 'campus_map_screen.dart';
import 'calendar_screen.dart';
import 'navi/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _storedStudentId;
  
  @override
  void initState() {
    super.initState();
    // 在進入頁面時自動載入公告
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnnouncementProvider>().refresh();
    });
    _loadStoredStudentId();
  }
  
  Future<void> _loadStoredStudentId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _storedStudentId = prefs.getString('stored_student_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'NTUST',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            letterSpacing: 1.5,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<AnnouncementProvider>().refresh();
          await _loadStoredStudentId();
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildUserInfoCard(context),
            const SizedBox(height: 32),
            _buildQuickActionsGrid(context),
            const SizedBox(height: 32),
            _buildAnnouncementPreview(context),
            const SizedBox(height: 32),
            _buildCoursePreview(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '歡迎',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_storedStudentId != null && _storedStudentId!.isNotEmpty)
            Text(
              '學號：$_storedStudentId',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            )
          else
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                await _loadStoredStudentId();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '設定校園帳號',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final actions = [
      _QuickAction(
        icon: Icons.calendar_today_rounded,
        label: '行事曆',
        color: colorScheme.onSurfaceVariant,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider(
                create: (_) => CalendarService(),
                child: const CalendarScreen(),
              ),
            ),
          );
        },
      ),
      _QuickAction(
        icon: Icons.school_rounded,
        label: '課程',
        color: colorScheme.onSurfaceVariant,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CourseScheduleScreen()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.map_rounded,
        label: '校園地圖',
        color: colorScheme.onSurfaceVariant,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CampusMapScreen()),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '功能',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.0,
          children: actions.map((action) => _buildActionButton(context, action)).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, _QuickAction action) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action.icon,
                size: 28,
                color: action.color,
              ),
              const SizedBox(height: 12),
              Text(
                action.label,
                style: TextStyle(
                  color: action.color,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementPreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '公告',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AnnouncementScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6), // 圓潤按鈕
                      border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    child: Text(
                      '更多',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Consumer<AnnouncementProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                );
              }

              if (provider.error != null) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    provider.error!,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              if (provider.announcements.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '目前沒有公告',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              final previewAnnouncements = provider.announcements.take(3).toList();
              return Column(
                children: previewAnnouncements.asMap().entries.map((entry) {
                  final index = entry.key;
                  final announcement = entry.value;
                  return Container(
                    decoration: BoxDecoration(
                      border: index < previewAnnouncements.length - 1
                          ? Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1), width: 1))
                          : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        announcement.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        announcement.date,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded, // 更圓潤的箭頭
                        size: 14,
                        color: colorScheme.outline,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AnnouncementScreen(),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoursePreview(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12), // 圓潤卡片
        border: Border.all(color: colorScheme.outline.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '今日課程',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurface,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CourseScheduleScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6), // 圓潤按鈕
                      border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    child: Text(
                      '更多',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Consumer<CourseService>(
            builder: (context, courseService, child) {
              final todayCourses = courseService.getTodayCourses();
              final upcomingCourses = courseService.getUpcomingCourses();
              debugPrint('今日所有課程: ${todayCourses.length}');
              debugPrint('即將到來的課程: ${upcomingCourses.length}');
              
              if (upcomingCourses.isEmpty) {
                String message = todayCourses.isNotEmpty ? '今日課程已結束' : '今日無課程';
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                );
              }

              return Column(
                children: upcomingCourses.take(3).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final course = entry.value;
                  return Container(
                    decoration: BoxDecoration(
                      border: index < upcomingCourses.length - 1 && index < 2
                          ? Border(bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1), width: 1))
                          : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        course.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${course.teacher} - ${course.classroom}\n${course.formattedTimeRange}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded, // 更圓潤的箭頭
                        size: 14,
                        color: colorScheme.outline,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CourseScheduleScreen(),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
} 