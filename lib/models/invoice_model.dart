class Invoice {
  final String id;
  final String harvestId;
  final String invoiceDate;
  final String trader;
  final double commissionRate;
  final double totalBeforeCommission;
  final double commissionAmount;
  final double netAmount;
  final String? photoPath;

  Invoice({
    required this.id,
    required this.harvestId,
    required this.invoiceDate,
    required this.trader,
    required this.commissionRate,
    required this.totalBeforeCommission,
    required this.commissionAmount,
    required this.netAmount,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'harvestId': harvestId,
      'invoiceDate': invoiceDate,
      'trader': trader,
      'commissionRate': commissionRate,
      'totalBeforeCommission': totalBeforeCommission,
      'commissionAmount': commissionAmount,
      'netAmount': netAmount,
      'photoPath': photoPath,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      harvestId: map['harvestId'],
      invoiceDate: map['invoiceDate'],
      trader: map['trader'],
      commissionRate: (map['commissionRate'] ?? 7).toDouble(),
      totalBeforeCommission: (map['totalBeforeCommission'] ?? 0).toDouble(),
      commissionAmount: (map['commissionAmount'] ?? 0).toDouble(),
      netAmount: (map['netAmount'] ?? 0).toDouble(),
      photoPath: map['photoPath'],
    );
  }
}
