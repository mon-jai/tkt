import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/calendar_event_model.dart';
import '../services/ics_calendar_service.dart';

class IcsCalendarViewScreen extends StatefulWidget {
  final String? icsUrl;           // 可以為 null，表示要自動載入最新
  final String? title;            // 可以為 null，表示要自動設定標題
  final bool showListButton;      // 是否顯示列表按鈕
  final bool autoLoad;            // 是否自動載入（如果 icsUrl 為 null 則載入最新）
  final VoidCallback? onShowList; // 點擊列表按鈕的回調

  const IcsCalendarViewScreen({
    super.key,
    this.icsUrl,
    this.title,
    this.showListButton = false,
    this.autoLoad = false,
    this.onShowList,
  });

  @override
  State<IcsCalendarViewScreen> createState() => _IcsCalendarViewScreenState();
}

class _IcsCalendarViewScreenState extends State<IcsCalendarViewScreen> {
  late final IcsCalendarService _calendarService;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String _currentTitle = '行事曆';

  @override
  void initState() {
    super.initState();
    _calendarService = IcsCalendarService();
    _selectedDay = _focusedDay;
    _currentTitle = widget.title ?? '行事曆';
    _loadCalendar();
  }

  @override
  void dispose() {
    _calendarService.dispose();
    super.dispose();
  }

  Future<void> _loadCalendar() async {
    if (widget.icsUrl != null) {
      // 有指定 URL，直接載入
      if (widget.autoLoad) {
        await _calendarService.initializeAndAutoLoad(widget.icsUrl!);
      } else {
        await _calendarService.downloadAndParseIcs(widget.icsUrl!);
      }
    } else {
      // 沒有指定 URL，載入最新的行事曆
      await _calendarService.loadLatestCalendar();
      // 更新標題為最新的行事曆標題
      if (_calendarService.currentCalendarTitle.isNotEmpty) {
        setState(() {
          _currentTitle = _calendarService.currentCalendarTitle;
        });
      }
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final events = _calendarService.getEventsForDay(day);
    debugPrint('_getEventsForDay: ${day.toString()} - 找到 ${events.length} 個事件');
    debugPrint('總事件數量: ${_calendarService.events.length}');
    if (_calendarService.events.isNotEmpty) {
      debugPrint('第一個事件: ${_calendarService.events.first.title} - ${_calendarService.events.first.date}');
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider.value(
      value: _calendarService,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            _currentTitle,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              letterSpacing: 1.0,
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
          actions: [
            if (widget.showListButton) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: widget.onShowList,
                  icon: const Icon(Icons.list_rounded),
                  tooltip: '行事曆列表',
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: IconButton(
                  onPressed: () async {
                    final service = Provider.of<IcsCalendarService>(context, listen: false);
                    if (widget.icsUrl != null) {
                      await service.forceRedownload(widget.icsUrl!);
                    } else {
                      // 重新載入最新行事曆
                      await _loadCalendar();
                    }
                  },
                  icon: const Icon(Icons.cloud_download_rounded),
                  tooltip: '重新下載',
                ),
              ),
            ] else ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.calendar_view_month),
                  tooltip: '選擇學年度',
                  onSelected: (String value) async {
                    final service = Provider.of<IcsCalendarService>(context, listen: false);
                    await service.loadCalendarByYear(value);
                    setState(() {
                      _currentTitle = value;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    final service = Provider.of<IcsCalendarService>(context, listen: false);
                    final availableCalendars = service.getAvailableCalendars();
                    
                    return availableCalendars.map((String yearTitle) {
                      return PopupMenuItem<String>(
                        value: yearTitle,
                        child: Row(
                          children: [
                            const Icon(Icons.school, size: 18),
                            const SizedBox(width: 8),
                            Text(yearTitle.replaceAll('行事曆', '')),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ],
          ],
        ),
        body: Consumer<IcsCalendarService>(
          builder: (context, service, child) {
            if (service.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: service.downloadProgress > 0 ? service.downloadProgress : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      service.downloadProgress > 0
                          ? '下載中... ${(service.downloadProgress * 100).toInt()}%'
                          : '解析 ICS 檔案中...',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (service.error != null) {
              return Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '載入失敗',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.error!,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _loadCalendar(),
                        child: const Text('重新載入'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                // 統計信息
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '總共 ${service.events.length} 個事件',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.today,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '今日: ${_getEventsForDay(_selectedDay ?? DateTime.now()).length} 個',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 日曆
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: TableCalendar<CalendarEvent>(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      if (!isSameDay(_selectedDay, selectedDay)) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      }
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      markerDecoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      formatButtonShowsNext: false,
                      formatButtonDecoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      formatButtonTextStyle: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),

                // 事件列表
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDay != null
                                    ? '${_selectedDay!.month}月${_selectedDay!.day}日的事件'
                                    : '選擇日期查看事件',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildEventsList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    if (_selectedDay == null) {
      return const Center(
        child: Text('請選擇日期'),
      );
    }

    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 48,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '這一天沒有事件',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: event.color ?? Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.type != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: event.color?.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: event.color?.withOpacity(0.3) ?? Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      event.type!,
                      style: TextStyle(
                        fontSize: 11,
                        color: event.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (event.description != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      event.description!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (event.isMultiDay)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.date.month}/${event.date.day} - ${event.endDate!.month}/${event.endDate!.day}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
