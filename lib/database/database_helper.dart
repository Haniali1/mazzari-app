import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/harvest_model.dart';
import '../models/invoice_model.dart';
import '../models/invoice_line_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mazzari.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute(
      'CREATE TABLE harvests ('
      'id TEXT PRIMARY KEY,'
      'harvestDate TEXT NOT NULL,'
      'crop TEXT NOT NULL,'
      'source TEXT NOT NULL,'
      'boxCount INTEGER NOT NULL,'
      'arrangement INTEGER,'
      'helper TEXT,'
      'season TEXT NOT NULL,'
      'notes TEXT,'
      'driver TEXT,'
      'transportCost REAL NOT NULL DEFAULT 0,'
      'boxUnitPrice REAL NOT NULL DEFAULT 0,'
      'boxTotalCost REAL NOT NULL DEFAULT 0,'
      'trader TEXT,'
      'status TEXT NOT NULL DEFAULT \'open\''
      ')'
    );

    await db.execute(
      'CREATE TABLE invoices ('
      'id TEXT PRIMARY KEY,'
      'harvestId TEXT NOT NULL,'
      'invoiceDate TEXT NOT NULL,'
      'trader TEXT NOT NULL,'
      'commissionRate REAL NOT NULL DEFAULT 7,'
      'totalBeforeCommission REAL NOT NULL DEFAULT 0,'
      'commissionAmount REAL NOT NULL DEFAULT 0,'
      'netAmount REAL NOT NULL DEFAULT 0,'
      'photoPath TEXT,'
      'FOREIGN KEY (harvestId) REFERENCES harvests (id)'
      ')'
    );

    await db.execute(
      'CREATE TABLE invoice_lines ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'invoiceId TEXT NOT NULL,'
      'lineNumber INTEGER NOT NULL,'
      'crop TEXT NOT NULL,'
      'boxCount INTEGER NOT NULL,'
      'weight REAL NOT NULL,'
      'pricePerKg REAL NOT NULL,'
      'lineTotal REAL NOT NULL,'
      'FOREIGN KEY (invoiceId) REFERENCES invoices (id)'
      ')'
    );

    await db.execute(
      'CREATE TABLE settings ('
      'key TEXT PRIMARY KEY,'
      'value TEXT NOT NULL'
      ')'
    );

    await db.insert('settings', {'key': 'crops', 'value': 'بندورة,خيار,كوسا,فاصولية'});
    await db.insert('settings', {'key': 'sources', 'value': 'صالة ثنائية,صالة ثلاثية,هنكار مفرد'});
    await db.insert('settings', {'key': 'traders', 'value': ''});
    await db.insert('settings', {'key': 'drivers', 'value': ''});
  }

  Future<String> insertHarvest(Harvest harvest) async {
    final db = await database;
    await db.insert('harvests', harvest.toMap());
    return harvest.id;
  }

  Future<List<Harvest>> getAllHarvests() async {
    final db = await database;
    final result = await db.query('harvests', orderBy: 'harvestDate DESC');
    return result.map((e) => Harvest.fromMap(e)).toList();
  }

  Future<List<Harvest>> getOpenHarvests() async {
    final db = await database;
    final result = await db.query('harvests', 
      where: 'status = ?', 
      whereArgs: ['open'],
      orderBy: 'harvestDate DESC'
    );
    return result.map((e) => Harvest.fromMap(e)).toList();
  }

  Future<Harvest?> getHarvestById(String id) async {
    final db = await database;
    final result = await db.query('harvests', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Harvest.fromMap(result.first);
  }

  Future updateHarvestStatus(String id, String status) async {
    final db = await database;
    await db.update('harvests', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future deleteHarvest(String id) async {
    final db = await database;
    await db.delete('harvests', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> insertInvoice(Invoice invoice, List<InvoiceLine> lines) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('invoices', invoice.toMap());
      for (var line in lines) {
        await txn.insert('invoice_lines', line.toMap());
      }
    });
    await updateHarvestStatus(invoice.harvestId, 'closed');
    return invoice.id;
  }

  Future<Invoice?> getInvoiceByHarvestId(String harvestId) async {
    final db = await database;
    final result = await db.query('invoices', where: 'harvestId = ?', whereArgs: [harvestId]);
    if (result.isEmpty) return null;
    return Invoice.fromMap(result.first);
  }

  Future<List<InvoiceLine>> getInvoiceLines(String invoiceId) async {
    final db = await database;
    final result = await db.query('invoice_lines', 
      where: 'invoiceId = ?', 
      whereArgs: [invoiceId],
      orderBy: 'lineNumber ASC'
    );
    return result.map((e) => InvoiceLine.fromMap(e)).toList();
  }

  Future<List<Invoice>> getAllInvoices() async {
    final db = await database;
    final result = await db.query('invoices', orderBy: 'invoiceDate DESC');
    return result.map((e) => Invoice.fromMap(e)).toList();
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Future setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>> getStatistics(String fromDate, String toDate) async {
    final db = await database;
    
    final harvestResult = await db.rawQuery(
      'SELECT COUNT(*) as count, SUM(boxCount) as totalBoxes, '
      'SUM(transportCost) as totalTransport, SUM(boxTotalCost) as totalBoxCost '
      'FROM harvests WHERE harvestDate BETWEEN ? AND ? AND status = \'closed\'',
      [fromDate, toDate]
    );

    final invoiceResult = await db.rawQuery(
      'SELECT SUM(i.totalBeforeCommission) as totalRevenue, '
      'SUM(i.commissionAmount) as totalCommission, SUM(i.netAmount) as totalNet, '
      'AVG(il.weight) as avgWeight, AVG(il.pricePerKg) as avgPricePerKg, '
      'SUM(il.weight) as totalWeight '
      'FROM invoices i JOIN invoice_lines il ON i.id = il.invoiceId '
      'WHERE i.invoiceDate BETWEEN ? AND ?',
      [fromDate, toDate]
    );

    return {
      'harvests': harvestResult.first,
      'invoices': invoiceResult.first,
    };
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats(String fromDate, String toDate) async {
    final db = await database;
    return await db.rawQuery(
      'SELECT strftime(\'%Y-%m\', i.invoiceDate) as month, '
      'SUM(i.netAmount) as revenue, SUM(h.transportCost + h.boxTotalCost) as costs, '
      'SUM(i.netAmount - h.transportCost - h.boxTotalCost) as profit, COUNT(*) as count '
      'FROM invoices i JOIN harvests h ON i.harvestId = h.id '
      'WHERE i.invoiceDate BETWEEN ? AND ? GROUP BY month ORDER BY month',
      [fromDate, toDate]
    );
  }

  Future<List<Map<String, dynamic>>> getTraderComparison(String fromDate, String toDate) async {
    final db = await database;
    return await db.rawQuery(
      'SELECT i.trader, COUNT(*) as count, SUM(i.netAmount) as totalNet, '
      'AVG(i.commissionRate) as avgCommission, '
      'SUM(i.netAmount - h.transportCost - h.boxTotalCost) as profit '
      'FROM invoices i JOIN harvests h ON i.harvestId = h.id '
      'WHERE i.invoiceDate BETWEEN ? AND ? GROUP BY i.trader ORDER BY profit DESC',
      [fromDate, toDate]
    );
  }

  Future<List<Map<String, dynamic>>> getCropComparison(String fromDate, String toDate) async {
    final db = await database;
    return await db.rawQuery(
      'SELECT h.crop, COUNT(*) as count, SUM(il.weight) as totalWeight, '
      'AVG(il.pricePerKg) as avgPrice, '
      'SUM(i.netAmount - h.transportCost - h.boxTotalCost) as profit '
      'FROM harvests h JOIN invoices i ON h.id = i.harvestId '
      'JOIN invoice_lines il ON i.id = il.invoiceId '
      'WHERE h.harvestDate BETWEEN ? AND ? GROUP BY h.crop ORDER BY profit DESC',
      [fromDate, toDate]
    );
  }

  Future<List<Map<String, dynamic>>> getSourceComparison(String fromDate, String toDate) async {
    final db = await database;
    return await db.rawQuery(
      'SELECT h.source, COUNT(*) as count, AVG(il.weight) as avgWeight, '
      'SUM(i.netAmount - h.transportCost - h.boxTotalCost) as profit '
      'FROM harvests h JOIN invoices i ON h.id = i.harvestId '
      'JOIN invoice_lines il ON i.id = il.invoiceId '
      'WHERE h.harvestDate BETWEEN ? AND ? GROUP BY h.source ORDER BY profit DESC',
      [fromDate, toDate]
    );
  }
}
