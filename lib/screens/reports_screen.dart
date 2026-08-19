import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  bool _isLoading = false;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _monthlyStats = [];
  List<Map<String, dynamic>> _traderComparison = [];
  List<Map<String, dynamic>> _cropComparison = [];
  List<Map<String, dynamic>> _sourceComparison = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final fromStr = DateFormat('yyyy-MM-dd').format(_fromDate);
    final toStr = DateFormat('yyyy-MM-dd').format(_toDate);

    final stats = await DatabaseHelper.instance.getStatistics(fromStr, toStr);
    final monthly = await DatabaseHelper.instance.getMonthlyStats(fromStr, toStr);
    final traders = await DatabaseHelper.instance.getTraderComparison(fromStr, toStr);
    final crops = await DatabaseHelper.instance.getCropComparison(fromStr, toStr);
    final sources = await DatabaseHelper.instance.getSourceComparison(fromStr, toStr);

    setState(() {
      _stats = stats;
      _monthlyStats = monthly;
      _traderComparison = traders;
      _cropComparison = crops;
      _sourceComparison = sources;
      _isLoading = false;
    });
  }

  Future<void> _selectDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير والإحصائيات')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDateRangeSelector(),
                const SizedBox(height: 24),
                _buildMainStats(),
                const SizedBox(height: 24),
                if (_monthlyStats.isNotEmpty) ...[
                  _buildSectionTitle('الربح الشهري'),
                  const SizedBox(height: 12),
                  _buildMonthlyChart(),
                  const SizedBox(height: 24),
                ],
                if (_traderComparison.isNotEmpty) ...[
                  _buildSectionTitle('مقارنة التجار'),
                  const SizedBox(height: 12),
                  _buildTraderComparison(),
                  const SizedBox(height: 24),
                ],
                if (_cropComparison.isNotEmpty) ...[
                  _buildSectionTitle('مقارنة المحاصيل'),
                  const SizedBox(height: 12),
                  _buildCropComparison(),
                  const SizedBox(height: 24),
                ],
                if (_sourceComparison.isNotEmpty) ...[
                  _buildSectionTitle('مقارنة المصادر'),
                  const SizedBox(height: 12),
                  _buildSourceComparison(),
                ],
              ],
            ),
    );
  }

  Widget _buildDateRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'من',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(DateFormat('yyyy/MM/dd').format(_fromDate)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.arrow_forward),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectDate(false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'إلى',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(DateFormat('yyyy/MM/dd').format(_toDate)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStats() {
    final harvests = _stats['harvests'] as Map<String, dynamic>?;
    final invoices = _stats['invoices'] as Map<String, dynamic>?;

    final count = (harvests?['count'] as num?)?.toInt() ?? 0;
    final totalWeight = (invoices?['totalWeight'] as num?)?.toDouble() ?? 0;
    final avgWeight = (invoices?['avgWeight'] as num?)?.toDouble() ?? 0;
    final avgPrice = (invoices?['avgPricePerKg'] as num?)?.toDouble() ?? 0;
    final totalNet = (invoices?['totalNet'] as num?)?.toDouble() ?? 0;
    final totalTransport = (harvests?['totalTransport'] as num?)?.toDouble() ?? 0;
    final totalBoxCost = (harvests?['totalBoxCost'] as num?)?.toDouble() ?? 0;
    final totalProfit = totalNet - totalTransport - totalBoxCost;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard('عدد القطافات', count.toString(), Icons.agriculture, Colors.green),
        _StatCard('إجمالي الوزن', '${totalWeight.toStringAsFixed(1)} كغ', Icons.scale, Colors.blue),
        _StatCard('متوسط الوزن', '${avgWeight.toStringAsFixed(1)} كغ', Icons.trending_up, Colors.orange),
        _StatCard('متوسط السعر', '${avgPrice.toStringAsFixed(0)} ل.س/كغ', Icons.attach_money, Colors.purple),
        _StatCard('إجمالي الإيرادات', '${totalNet.toStringAsFixed(0)} ل.س', Icons.account_balance_wallet, Colors.teal),
        _StatCard('الربح الصافي', '${totalProfit.toStringAsFixed(0)} ل.س', Icons.trending_up, totalProfit >= 0 ? Colors.green : Colors.red),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    return SizedBox(
      height: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _monthlyStats.map((s) => (s['profit'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= _monthlyStats.length) return const Text('');
                      final month = _monthlyStats[index]['month'] as String;
                      return Text(month.substring(5), style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: _monthlyStats.asMap().entries.map((entry) {
                final profit = (entry.value['profit'] as num).toDouble();
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [BarChartRodData(toY: profit, color: profit >= 0 ? Colors.green : Colors.red, width: 20)],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTraderComparison() {
    return Column(
      children: _traderComparison.map((t) {
        final profit = (t['profit'] as num?)?.toDouble() ?? 0;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: profit >= 0 ? Colors.green : Colors.red,
              child: Text('${t['trader']?.toString().substring(0, 1) ?? '?'}'),
            ),
            title: Text(t['trader'] as String? ?? ''),
            subtitle: Text('${t['count']} عملية | عمولة ${(t['avgCommission'] as num?)?.toStringAsFixed(1) ?? 0}%'),
            trailing: Text(
              '${profit.toStringAsFixed(0)} ل.س',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: profit >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCropComparison() {
    return Column(
      children: _cropComparison.map((c) {
        final profit = (c['profit'] as num?)?.toDouble() ?? 0;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
            title: Text(c['crop'] as String? ?? ''),
            subtitle: Text('${c['count']} قطافة | ${(c['totalWeight'] as num?)?.toStringAsFixed(1) ?? 0} كغ'),
            trailing: Text(
              '${profit.toStringAsFixed(0)} ل.س',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: profit >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSourceComparison() {
    return Column(
      children: _sourceComparison.map((s) {
        final profit = (s['profit'] as num?)?.toDouble() ?? 0;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.warehouse, color: Colors.brown),
            title: Text(s['source'] as String? ?? ''),
            subtitle: Text('${s['count']} قطافة | متوسط ${(s['avgWeight'] as num?)?.toStringAsFixed(1) ?? 0} كغ'),
            trailing: Text(
              '${profit.toStringAsFixed(0)} ل.س',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: profit >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
