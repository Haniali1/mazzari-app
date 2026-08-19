import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/harvest_model.dart';
import '../models/invoice_model.dart';
import '../models/invoice_line_model.dart';
import 'invoice_screen.dart';

class HarvestDetailScreen extends StatefulWidget {
  final String harvestId;
  const HarvestDetailScreen({super.key, required this.harvestId});

  @override
  State<HarvestDetailScreen> createState() => _HarvestDetailScreenState();
}

class _HarvestDetailScreenState extends State<HarvestDetailScreen> {
  Harvest? _harvest;
  Invoice? _invoice;
  List<InvoiceLine> _lines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final harvest = await DatabaseHelper.instance.getHarvestById(widget.harvestId);
    final invoice = await DatabaseHelper.instance.getInvoiceByHarvestId(widget.harvestId);
    List<InvoiceLine> lines = [];
    if (invoice != null) {
      lines = await DatabaseHelper.instance.getInvoiceLines(invoice.id);
    }
    setState(() {
      _harvest = harvest;
      _invoice = invoice;
      _lines = lines;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_harvest == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تفاصيل القطافة')),
        body: const Center(child: Text('القطافة غير موجودة')),
      );
    }

    final date = DateTime.parse(_harvest!.harvestDate);
    final dateStr = DateFormat('yyyy/MM/dd').format(date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل القطافة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusHeader(),
          const SizedBox(height: 16),
          _buildInfoCard('معلومات القطاف', [
            _InfoRow('المعرف', _harvest!.id),
            _InfoRow('التاريخ', dateStr),
            _InfoRow('المحصول', _harvest!.crop),
            _InfoRow('المصدر', _harvest!.source),
            _InfoRow('عدد الفلين', '${_harvest!.boxCount}'),
            if (_harvest!.arrangement != null)
              _InfoRow('الترتيب', '${_harvest!.arrangement} طبقات'),
            _InfoRow('المساعد', _harvest!.helper ?? 'بدون'),
            _InfoRow('الموسم', _harvest!.season),
            if (_harvest!.notes != null)
              _InfoRow('ملاحظات', _harvest!.notes!),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('معلومات النقل', [
            _InfoRow('السائق', _harvest!.driver ?? 'غير محدد'),
            _InfoRow('أجرة النقل', '${_harvest!.transportCost.toStringAsFixed(0)} ل.س'),
            _InfoRow('سعر الفلينة', '${_harvest!.boxUnitPrice.toStringAsFixed(0)} ل.س'),
            _InfoRow('تكلفة الفلين', '${_harvest!.boxTotalCost.toStringAsFixed(0)} ل.س'),
          ]),
          const SizedBox(height: 16),
          if (_invoice != null) ...[
            _buildInfoCard('الفاتورة', [
              _InfoRow('رقم الفاتورة', _invoice!.id),
              _InfoRow('تاريخ الفاتورة', _invoice!.invoiceDate),
              _InfoRow('التاجر', _invoice!.trader),
              _InfoRow('العمولة', '${_invoice!.commissionRate}%'),
            ]),
            const SizedBox(height: 16),
            _buildInvoiceLines(),
            const SizedBox(height: 16),
            _buildFinancialSummary(),
          ] else ...[
            _buildNoInvoiceCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_harvest!.status) {
      case 'open':
        statusColor = Colors.orange;
        statusText = 'قطافة مفتوحة - لم يتم النقل بعد';
        statusIcon = Icons.pending;
        break;
      case 'transported':
        statusColor = Colors.blue;
        statusText = 'تم النقل - في انتظار الفاتورة';
        statusIcon = Icons.local_shipping;
        break;
      case 'closed':
        statusColor = Colors.green;
        statusText = 'قطافة مغلقة - تم استلام الفاتورة';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'غير معروف';
        statusIcon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceLines() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'سطور الفاتورة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('النوع')),
                  DataColumn(label: Text('الفلين')),
                  DataColumn(label: Text('الوزن')),
                  DataColumn(label: Text('سعر الكيلو')),
                  DataColumn(label: Text('المجموع')),
                ],
                rows: _lines.map((line) => DataRow(cells: [
                  DataCell(Text('${line.lineNumber}')),
                  DataCell(Text(line.crop)),
                  DataCell(Text('${line.boxCount}')),
                  DataCell(Text('${line.weight.toStringAsFixed(1)} كغ')),
                  DataCell(Text('${line.pricePerKg.toStringAsFixed(0)} ل.س')),
                  DataCell(Text('${line.lineTotal.toStringAsFixed(0)} ل.س')),
                ])).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final totalCosts = _harvest!.transportCost + _harvest!.boxTotalCost;
    final profit = _invoice!.netAmount - totalCosts;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: profit >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: profit >= 0 ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'الحساب النهائي',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: profit >= 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          _SummaryRow('المبلغ الصافي:', _invoice!.netAmount),
          _SummaryRow('تكلفة الفلين:', _harvest!.boxTotalCost, isNegative: true),
          _SummaryRow('أجرة النقل:', _harvest!.transportCost, isNegative: true),
          const Divider(thickness: 2),
          _SummaryRow(
            'الربح الصافي:',
            profit,
            isTotal: true,
            color: profit >= 0 ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildNoInvoiceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          const Text(
            'لم يتم تسجيل الفاتورة بعد',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InvoiceScreen(harvestId: widget.harvestId),
              ),
            ).then((_) => _loadData()),
            icon: const Icon(Icons.add),
            label: const Text('تسجيل الفاتورة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذه القطافة؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteHarvest(widget.harvestId);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isNegative;
  final bool isTotal;
  final Color? color;

  const _SummaryRow(
    this.label,
    this.value, {
    this.isNegative = false,
    this.isTotal = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}${value.toStringAsFixed(0)} ل.س',
            style: TextStyle(
              fontSize: isTotal ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: color ?? (isNegative ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }
}
