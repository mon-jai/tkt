import 'package:logger/logger.dart';

enum LogMode { logError, logDebug }

class MyLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}

class Log {
  static Logger logger = Logger(
    filter: MyLogFilter(),
    printer: PrettyPrinter(
        methodCount: 2,
        // number of method calls to be displayed
        errorMethodCount: 8,
        // number of method calls if stacktrace is provided
        lineLength: 60,
        // width of the output
        colors: true,
        // Colorful log messages
        printEmojis: false,
        // Print an emoji for each log message
        printTime: false // Should each log print contain a timestamp
        ),
    output: ConsoleOutput(), // 使用預設的控制台輸出
  );

  static void init() {
    // 無需初始化，logger 預設即可使用
  }

  static void eWithStack(dynamic data, StackTrace stackTrace) {
    // 用於顯示已用try catch的處理error
    logger.e(data.toString(), stackTrace: stackTrace);
  }

  static void error(dynamic data, StackTrace stackTrace) {
    // 用於顯示無try catch的error
    logger.e(data.toString(), stackTrace: stackTrace);
  }

  static void e(dynamic data) {
    // 用於顯示已用try catch的處理error
    logger.e(data.toString());
  }

  static void d(dynamic data) {
    // 用於debug的Log
    logger.d(data.toString());
  }
}