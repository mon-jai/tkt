import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/course_service.dart';
import '../models/course_model.dart';
import '../utils/course_time_util.dart';
import 'dart:convert';

class CourseScheduleScreen extends StatefulWidget {
  const CourseScheduleScreen({super.key});

  @override
  State<CourseScheduleScreen> createState() => _CourseScheduleScreenState();
}

class _CourseScheduleScreenState extends State<CourseScheduleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  final List<String> _weekdayNames = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _weekdays.length,
      vsync: this,
      initialIndex: DateTime.now().weekday - 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _exportCourses(BuildContext context) async {
    final courseService = context.read<CourseService>();
    final coursesJson = courseService.exportToJson();
    
    // 顯示導出的 JSON 數據
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('課表數據'),
        content: SingleChildScrollView(
          child: SelectableText(coursesJson),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('關閉'),
          ),
        ],
      ),
    );
  }

  Future<void> _importCourses(BuildContext context) async {
    String jsonData = '';
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('導入課表'),
        content: TextField(
          maxLines: 8,
          decoration: const InputDecoration(
            hintText: '請貼入課表 JSON 數據',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => jsonData = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              try {
                final courseService = context.read<CourseService>();
                courseService.importFromJson(jsonData);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('課表導入成功')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('導入失敗：$e')),
                );
              }
            },
            child: const Text('導入'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCourseDialog(BuildContext context, [Course? courseToEdit]) async {
    final formKey = GlobalKey<FormState>();
    String name = courseToEdit?.name ?? '';
    String teacher = courseToEdit?.teacher ?? '';
    String classroom = courseToEdit?.classroom ?? '';
    int dayOfWeek = courseToEdit?.dayOfWeek ?? DateTime.now().weekday;
    int startSlot = courseToEdit?.startSlot ?? 1;
    int endSlot = courseToEdit?.endSlot ?? 1;
    String? note = courseToEdit?.note;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(courseToEdit == null ? '新增課程' : '編輯課程'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: '課程名稱'),
                    validator: (value) => value?.isEmpty ?? true ? '請輸入課程名稱' : null,
                    initialValue: name,
                    onSaved: (value) => name = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: '教師'),
                    initialValue: teacher,
                    onSaved: (value) => teacher = value!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: '教室'),
                    initialValue: classroom,
                    onSaved: (value) => classroom = value!,
                  ),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: '星期'),
                    value: dayOfWeek,
                    items: List.generate(
                      7,
                      (index) => DropdownMenuItem(
                        value: index + 1,
                        child: Text('週${_weekdays[index]}'),
                      ),
                    ),
                    onChanged: (value) => dayOfWeek = value!,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: '開始節次'),
                          value: startSlot,
                          items: CourseTimeUtil.timeSlots.map((slot) {
                            return DropdownMenuItem(
                              value: slot.index,
                              child: Text('${slot.label} (${slot.formattedStartTime})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                startSlot = value;
                                // 如果結束時間早於開始時間，自動調整結束時間
                                if (endSlot < startSlot) {
                                  endSlot = startSlot;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(labelText: '結束節次'),
                          value: endSlot,
                          items: CourseTimeUtil.timeSlots
                              .where((slot) => slot.index >= startSlot)
                              .map((slot) {
                            return DropdownMenuItem(
                              value: slot.index,
                              child: Text('${slot.label} (${slot.formattedEndTime})'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value >= startSlot) {
                              setState(() {
                                endSlot = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: '備註（選填）'),
                    initialValue: note,
                    onSaved: (value) => note = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState!.save();
                  final courseService = context.read<CourseService>();
                  final course = Course(
                    id: courseToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    teacher: teacher,
                    classroom: classroom,
                    dayOfWeek: dayOfWeek,
                    startSlot: startSlot,
                    endSlot: endSlot,
                    note: note,
                  );

                  // 檢查時間衝突（排除自己）
                  final conflicts = courseService.checkTimeConflicts(course)
                      .where((c) => c.id != course.id)
                      .toList();
                      
                  if (conflicts.isNotEmpty) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('時間衝突'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('此課程與以下課程時間衝突：'),
                            const SizedBox(height: 8),
                            ...conflicts.map((c) => Text('• ${c.name} (${c.timeSlotString})')),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('返回修改'),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  if (courseToEdit != null) {
                    courseService.updateCourse(course);
                  } else {
                    courseService.addCourse(course);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(courseToEdit == null ? '儲存' : '更新'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now().weekday - 1; // 0-6 for TabBar index

    return Scaffold(
      appBar: AppBar(
        title: const Text('課表'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              dividerColor: Colors.transparent,
              tabAlignment: TabAlignment.center,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                ),
              ),
              tabs: List.generate(
                _weekdays.length,
                (index) => Tab(
                  height: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: index == today
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _weekdays[index],
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              index == today ? '今天' : _weekdayNames[index],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () => _importCourses(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportCourses(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddCourseDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          _weekdays.length,
          (index) => _DayScheduleView(
            dayOfWeek: index + 1,
            onEditCourse: (course) => _showAddCourseDialog(context, course),
          ),
        ),
      ),
    );
  }
}

class _DayScheduleView extends StatelessWidget {
  final int dayOfWeek;
  final Function(Course) onEditCourse;

  const _DayScheduleView({
    required this.dayOfWeek,
    required this.onEditCourse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Consumer<CourseService>(
      builder: (context, courseService, child) {
        final courses = courseService.getCoursesByDay(dayOfWeek);
        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: theme.colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  '今天沒有課程',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            final startTime = CourseTimeUtil.getTimeSlotByIndex(course.startSlot);
            final endTime = CourseTimeUtil.getTimeSlotByIndex(course.endSlot);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onEditCourse(course),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 時間顯示
                            Container(
                              width: 80,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    course.timeSlotString,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${startTime.formattedStartTime}\n${endTime.formattedEndTime}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary.withOpacity(0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 課程資訊
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 16,
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        course.teacher,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 16,
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        course.classroom,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // 操作按鈕
                            PopupMenuButton(
                              icon: Icon(
                                Icons.more_vert,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('編輯'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: theme.colorScheme.error,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('刪除'),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  onEditCourse(course);
                                } else if (value == 'delete') {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('確認刪除'),
                                      content: Text('確定要刪除「${course.name}」這門課程嗎？'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('取消'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            courseService.removeCourse(course.id);
                                            Navigator.pop(context);
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: theme.colorScheme.error,
                                          ),
                                          child: const Text('確定'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        if (course.note != null && course.note!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.notes,
                                  size: 16,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    course.note!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
} 