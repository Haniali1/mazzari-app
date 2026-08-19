class InvoiceLine {
  final int? id;
  final String invoiceId;
  final int lineNumber;
  final String crop;
  final int boxCount;
  final double weight;
  final double pricePerKg;
  final double lineTotal;

  InvoiceLine({
    this.id,
    required this.invoiceId,
    required this.lineNumber,
    required this.crop,
    required this.boxCount,
    required this.weight,
    required this.pricePerKg,
    required this.lineTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'lineNumber': lineNumber,
      'crop': crop,
      'boxCount': boxCount,
      'weight': weight,
      'pricePerKg': pricePerKg,
      'lineTotal': lineTotal,
    };
  }

  factory InvoiceLine.fromMap(Map<String, dynamic> map) {
    return InvoiceLine(
      id: map['id'],
      invoiceId: map['invoiceId'],
      lineNumber: map['lineNumber'],
      crop: map['crop'],
      boxCount: map['boxCount'],
      weight: (map['weight'] ?? 0).toDouble(),
      pricePerKg: (map['pricePerKg'] ?? 0).toDouble(),
      lineTotal: (map['lineTotal'] ?? 0).toDouble(),
    );
  }
}
