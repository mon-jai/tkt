import 'package:tkt/connector/core/connector.dart';
import 'package:tkt/connector/core/connector_parameter.dart';
import 'package:tkt/debug/log/log.dart';

enum CourseConnectorStatus { loginSuccess, loginFail, unknownError }
enum NtustConnectorStatus { loginSuccess, loginFail, unknownError }

class CheckLogin {
  static Future<CourseConnectorStatus> course_login() async {
    String _loginUrl = "https://courseselection.ntust.edu.tw/ChooseList/D01/D01";
    String result;
    try {
      ConnectorParameter parameter;
      parameter = ConnectorParameter(_loginUrl);
      result = await Connector.getRedirects(parameter);
      Log.d(result);
      if (!result.contains("功課表")) {
        return CourseConnectorStatus.loginFail;
      }
      return CourseConnectorStatus.loginSuccess;
    } catch (e, stack) {
      Log.eWithStack(e.toString(), stack);
      return CourseConnectorStatus.loginFail;
    }
  }

  static Future<NtustConnectorStatus> ntust_login() async {
    String _loginUrl = "https://stuinfosys.ntust.edu.tw/StuScoreQueryServ/StuScoreQuery";
    String result;
    try {
      ConnectorParameter parameter;
      parameter = ConnectorParameter(_loginUrl);
      result = await Connector.getRedirects(parameter);
      if (!result.contains("成績查詢系統")) {
        return NtustConnectorStatus.loginFail;
      }
      return NtustConnectorStatus.loginSuccess;
    } catch (e, stack) {
      Log.eWithStack(e.toString(), stack);
      return NtustConnectorStatus.loginFail;
    }
  }

  
}