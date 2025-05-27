import 'package:flutter/material.dart';
import 'package:tkt/models/course/schedule_model.dart'; // Ensure this path is correct
import 'package:tkt/services/schedule_service.dart';
import 'package:tkt/debug/log/log.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool _isLoading = false;
  Schedule? _schedule; // Changed to hold the Schedule object
  String? _error; // To hold potential error messages

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null; // Clear previous errors
    });

    try {
      final result = await ScheduleService.fetchSchedule();
      if (!mounted) return;
      setState(() {
        _schedule = result; // Store the Schedule object
        _isLoading = false;
      });
    } catch (e) {
      Log.e('獲取課表失敗：$e');
      if (!mounted) return;
      setState(() {
        _error = '獲取課表失敗：$e'; // Store the error
        _isLoading = false;
        _schedule = null; // Clear schedule on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('課表查詢'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchSchedule, // Disable while loading
          ),
        ],
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_schedule == null) {
      return const Center(child: Text('無課表資料'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0), // Reduced padding for better fit
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '總學分數: ${_schedule!.totalCredits}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '課程列表',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildCoursesTable(),
          const SizedBox(height: 16),
          const Text(
            '時間表',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildScheduleTable(),
          const SizedBox(height: 16), // Add some bottom padding
        ],
      ),
    );
  }

  Widget _buildCoursesTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 15.0,
          columns: const [
            DataColumn(label: Text('課碼')),
            DataColumn(label: Text('課程名稱')),
            DataColumn(label: Text('學分數')),
            DataColumn(label: Text('必/選修')),
            DataColumn(label: Text('教師')),
            DataColumn(label: Text('備註')),
          ],
          rows: _schedule!.courses.map((course) {
            return DataRow(cells: [
              DataCell(Text(course.code)),
              DataCell(Text(course.name)),
              DataCell(Text(course.credits.toString())),
              DataCell(Text(course.isRequired ? '必修' : '選修')),
              DataCell(Text(course.teacher)),
              DataCell(Text(course.note ?? '')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildScheduleTable() {
    const weekdays = ['一', '二', '三', '四', '五', '六', '日'];

    return Card(
      child: SingleChildScrollView(
         scrollDirection: Axis.horizontal, // Allow horizontal scrolling for the table
         child: Table(
          border: TableBorder.all(color: Colors.grey.shade400),
          defaultColumnWidth: const IntrinsicColumnWidth(), // Adjusts column width to content
          children: [
            // Header Row
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[200]),
              children: [
                _buildHeaderCell('節次'),
                _buildHeaderCell('時間'),
                ...weekdays.map((day) => _buildHeaderCell(day)).toList(),
              ],
            ),
            // Data Rows
            ..._schedule!.timeSlots.map((timeSlot) {
              return TableRow(
                children: [
                  _buildTableCell('${timeSlot.period}\n${timeSlot.startTime}\n${timeSlot.endTime}', isHeader: true),
                  _buildTableCell('${timeSlot.startTime}\n～\n${timeSlot.endTime}', isHeader: true),
                  ...weekdays.map((day) {
                    final courseInfo = timeSlot.schedule[day];
                    return _buildCourseCell(courseInfo);
                  }).toList(),
                ],
              );
            }).toList(),
          ],
                 ),
      ),
    );
  }

   Widget _buildHeaderCell(String text) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
       child: Center(
         child: Text(
           text,
           style: const TextStyle(fontWeight: FontWeight.bold),
           textAlign: TextAlign.center,
         ),
       ),
     );
   }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.all(6.0), // Reduced padding
      constraints: const BoxConstraints(minWidth: 70), // Minimum width for time/period cells
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
            fontSize: 10, // Reduced font size for better fit
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCourseCell(CourseInfo? courseInfo) {
    return Container(
      padding: const EdgeInsets.all(6.0), // Reduced padding
      constraints: const BoxConstraints(minWidth: 90), // Minimum width for course cells
      child: Center(
        child: Text(
          courseInfo != null
              ? '${courseInfo.name}\n${courseInfo.classroom}'
              : '',
          style: TextStyle(
            fontSize: 10, // Reduced font size
            color: courseInfo?.color != null ? _parseColor(courseInfo!.color!) : null,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // Helper to parse color (if needed, otherwise returns null)
  Color? _parseColor(String colorString) {
    // Implement color parsing if you have specific color formats.
    // For now, returning null to use default text color.
    return null;
  }
}