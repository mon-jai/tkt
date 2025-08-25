//封裝 HTTP 請求的參數，方便在 Dart/Flutter 應用中進行網路請求
//charsetName與userAgen可自行做修改
const presetCharsetName = 'utf-8';

class ConnectorParameter {
  static String  presetUserAgent= "Mozilla/5.0 (iPhone; CPU iPhone OS 12_1_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/12.0 Mobile/15E148 Safari/604.1";

  String url;
  dynamic data;
  String charsetName = presetCharsetName; 
  //json header 代表模擬的瀏覽器
  String userAgent = presetUserAgent; 
  String? referer;

  ConnectorParameter(this.url, {this.data, this.referer});
}
