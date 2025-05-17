import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/parking_lot_model.dart';

class ParkingLotService {
  static const String apiUrl = 'https://pay.pss-group.com/online-payment/api/sites_remain';
  static const String token = 'aa4b9bca9c2aee27a6bb';

  static const List<Map<String, String>> parkingSites = [
    {'site': 'PSS_YA21106', 'name': '宿舍'},
    {'site': 'PSS_YA21105', 'name': '圖書館'},
    {'site': 'PSS_YA21104', 'name': '帆船大樓'},
    {'site': 'PSS_YA21103', 'name': '研揚大樓'},
  ];

  Future<List<ParkingLot>> getAllParkingLots() async {
    try {
      final List<ParkingLot> parkingLots = [];

      for (final site in parkingSites) {
        try {
          debugPrint('正在獲取停車場資訊：${site['name']}');
          
          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json, text/plain, */*',
              'X-ONLINE-TOKEN': token,
              'Origin': 'https://pay.pss-group.com',
              'Referer': 'https://pay.pss-group.com/',
            },
            body: jsonEncode({
              'site': site['site'],
            }),
          );

          debugPrint('API 回應狀態碼：${response.statusCode}');
          debugPrint('API 回應內容：${response.body}');

          if (response.statusCode == 200) {
            final json = jsonDecode(response.body) as Map<String, dynamic>;
            final apiResponse = ParkingLotResponse.fromJson(json);

            if (apiResponse.success) {
              final parkingLot = ParkingLot.fromJson(
                json,
                site['site']!,
                site['name']!,
              );
              debugPrint('成功解析停車場資訊：${parkingLot.name}, 車位數：${parkingLot.motorSlots}');
              parkingLots.add(parkingLot);
            } else {
              debugPrint('API 回應不成功：${apiResponse.message}');
            }
          } else {
            debugPrint('HTTP 請求失敗：${response.statusCode}');
          }
        } catch (e) {
          debugPrint('處理單個停車場時發生錯誤：$e');
          // 繼續處理下一個停車場，而不是完全失敗
          continue;
        }
      }

      if (parkingLots.isEmpty) {
        throw Exception('無法獲取任何停車場資訊');
      }

      return parkingLots;
    } catch (e) {
      debugPrint('獲取停車場資訊時發生錯誤：$e');
      throw Exception('無法獲取停車場資訊：$e');
    }
  }
} 