import 'dart:io';

import 'package:dio/dio.dart';


//用於修改 HTTP 請求的標頭（headers），設置和管理 Referer 標頭
class RequestInterceptors extends Interceptor {
  String referer = "https://i.ntust.edu.tw/student";

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.headers.containsKey(HttpHeaders.refererHeader)) {
      options.headers[HttpHeaders.refererHeader] = referer;
    }
    referer = options.uri.toString();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
