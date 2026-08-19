class Harvest {
  final String id;
  final String harvestDate;
  final String crop;
  final String source;
  final int boxCount;
  final int? arrangement;
  final String? helper;
  final String season;
  final String? notes;
  final String? driver;
  final double transportCost;
  final double boxUnitPrice;
  final double boxTotalCost;
  final String? trader;
  final String status;

  Harvest({
    required this.id,
    required this.harvestDate,
    required this.crop,
    required this.source,
    required this.boxCount,
    this.arrangement,
    this.helper,
    required this.season,
    this.notes,
    this.driver,
    required this.transportCost,
    required this.boxUnitPrice,
    required this.boxTotalCost,
    this.trader,
    this.status = 'open',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'harvestDate': harvestDate,
      'crop': crop,
      'source': source,
      'boxCount': boxCount,
      'arrangement': arrangement,
      'helper': helper,
      'season': season,
      'notes': notes,
      'driver': driver,
      'transportCost': transportCost,
      'boxUnitPrice': boxUnitPrice,
      'boxTotalCost': boxTotalCost,
      'trader': trader,
      'status': status,
    };
  }

  factory Harvest.fromMap(Map<String, dynamic> map) {
    return Harvest(
      id: map['id'],
      harvestDate: map['harvestDate'],
      crop: map['crop'],
      source: map['source'],
      boxCount: map['boxCount'],
      arrangement: map['arrangement'],
      helper: map['helper'],
      season: map['season'],
      notes: map['notes'],
      driver: map['driver'],
      transportCost: (map['transportCost'] ?? 0).toDouble(),
      boxUnitPrice: (map['boxUnitPrice'] ?? 0).toDouble(),
      boxTotalCost: (map['boxTotalCost'] ?? 0).toDouble(),
      trader: map['trader'],
      status: map['status'] ?? 'open',
    );
  }

  double get totalCosts => transportCost + boxTotalCost;
}
