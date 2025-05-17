class ParkingLot {
  final String site;      // API 站點代碼
  final String name;      // 停車場名稱
  final int motorSlots;   // 機車車位數量

  ParkingLot({
    required this.site,
    required this.name,
    required this.motorSlots,
  });

  factory ParkingLot.fromJson(Map<String, dynamic> json, String site, String name) {
    final siteData = json['payload'][site] as Map<String, dynamic>?;
    final motorSlots = siteData?['motor'] as int?;
    
    // 如果 motorSlots 是 null，我們也將其視為 -1（已滿）
    return ParkingLot(
      site: site,
      name: name,
      motorSlots: motorSlots ?? -1,
    );
  }

  bool get isFull => motorSlots <= 0; // 修改判斷邏輯
  String get availabilityText => isFull ? '車位已滿❌' : '$motorSlots 個空位';
}

class ParkingLotResponse {
  final bool success;
  final String message;
  final Map<String, dynamic>? payload;

  ParkingLotResponse({
    required this.success,
    required this.message,
    this.payload,
  });

  factory ParkingLotResponse.fromJson(Map<String, dynamic> json) {
    return ParkingLotResponse(
      success: json['status'] == 'ok',
      message: json['message'] ?? '',
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }

  factory ParkingLotResponse.error(String message) {
    return ParkingLotResponse(
      success: false,
      message: message,
      payload: null,
    );
  }
} 