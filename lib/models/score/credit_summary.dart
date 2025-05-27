class CreditSummary {
  final int earnedCredits;
  final int earnedDistanceCredits;
  final int totalEarnedCredits;
  final int inProgressCredits;
  final int inProgressDistanceCredits;
  final int totalInProgressCredits;
  final int totalCredits;
  final int totalDistanceCredits;
  final int grandTotalCredits;

  CreditSummary({
    required this.earnedCredits,
    required this.earnedDistanceCredits,
    required this.totalEarnedCredits,
    required this.inProgressCredits,
    required this.inProgressDistanceCredits,
    required this.totalInProgressCredits,
    required this.totalCredits,
    required this.totalDistanceCredits,
    required this.grandTotalCredits,
  });

  factory CreditSummary.fromHtml(Map<String, dynamic> data) {
    return CreditSummary(
      earnedCredits: int.tryParse(data['earnedCredits']?.toString().trim() ?? '0') ?? 0,
      earnedDistanceCredits: int.tryParse(data['earnedDistanceCredits']?.toString().trim() ?? '0') ?? 0,
      totalEarnedCredits: int.tryParse(data['totalEarnedCredits']?.toString().trim() ?? '0') ?? 0,
      inProgressCredits: int.tryParse(data['inProgressCredits']?.toString().trim() ?? '0') ?? 0,
      inProgressDistanceCredits: int.tryParse(data['inProgressDistanceCredits']?.toString().trim() ?? '0') ?? 0,
      totalInProgressCredits: int.tryParse(data['totalInProgressCredits']?.toString().trim() ?? '0') ?? 0,
      totalCredits: int.tryParse(data['totalCredits']?.toString().trim() ?? '0') ?? 0,
      totalDistanceCredits: int.tryParse(data['totalDistanceCredits']?.toString().trim() ?? '0') ?? 0,
      grandTotalCredits: int.tryParse(data['grandTotalCredits']?.toString().trim() ?? '0') ?? 0,
    );
  }

  factory CreditSummary.fromJson(Map<String, dynamic> json) {
    return CreditSummary(
      earnedCredits: json['earnedCredits'] ?? 0,
      earnedDistanceCredits: json['earnedDistanceCredits'] ?? 0,
      totalEarnedCredits: json['totalEarnedCredits'] ?? 0,
      inProgressCredits: json['inProgressCredits'] ?? 0,
      inProgressDistanceCredits: json['inProgressDistanceCredits'] ?? 0,
      totalInProgressCredits: json['totalInProgressCredits'] ?? 0,
      totalCredits: json['totalCredits'] ?? 0,
      totalDistanceCredits: json['totalDistanceCredits'] ?? 0,
      grandTotalCredits: json['grandTotalCredits'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'earnedCredits': earnedCredits,
      'earnedDistanceCredits': earnedDistanceCredits,
      'totalEarnedCredits': totalEarnedCredits,
      'inProgressCredits': inProgressCredits,
      'inProgressDistanceCredits': inProgressDistanceCredits,
      'totalInProgressCredits': totalInProgressCredits,
      'totalCredits': totalCredits,
      'totalDistanceCredits': totalDistanceCredits,
      'grandTotalCredits': grandTotalCredits,
    };
  }
}