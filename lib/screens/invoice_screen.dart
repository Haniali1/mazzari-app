import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/harvest_model.dart';
import '../models/invoice_model.dart';
import '../models/invoice_line_model.dart';

class InvoiceScreen extends StatefulWidget {
  final String? harvestId;
  const InvoiceScreen({super.key, this.harvestId});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  
  Harvest? _selectedHarvest;
  List<Harvest> _openHarvests = [];
  
  DateTime _invoiceDate = DateTime.now();
  final _traderController = TextEditingController();
  final _commissionController = TextEditingController(text: '7');
  
  List<InvoiceLineForm> _lines = [InvoiceLineForm()];
  
  double get _totalBeforeCommission {
    return _lines.fold(0, (sum, line) => sum + line.lineTotal);
  }
  
  double get _commissionRate => double.tryParse(_commissionController.text) ?? 7;
  double get _commissionAmount => _totalBeforeCommission * (_commissionRate / 100);
  double get _netAmount => _totalBeforeCommission - _commissionAmount;
  
  double get _totalCosts {
    if (_selectedHarvest == null) return 0;
    return _selectedHarvest!.transportCost + _selectedHarvest!.boxTotalCost;
  }
  
  double get _profit => _netAmount - _totalCosts;

  @override
  void initState() {
    super.initState();
    _loadOpenHarvests();
  }

  Future<void> _loadOpenHarvests() async {
    final harvests = await DatabaseHelper.instance.getOpenHarvests();
    setState(() {
      _openHarvests = harvests;
      if (widget.harvestId != null) {
        _selectedHarvest = harvests.firstWhere(
          (h) => h.id == widget.harvestId,
          orElse: () => harvests.first,
        );
        if (_selectedHarvest != null) {
          _traderController.text = _selectedHarvest!.trader ?? '';
        }
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }

  void _addLine() {
    setState(() => _lines.add(InvoiceLineForm()));
  }

  void _removeLine(int index) {
    if (_lines.length > 1) {
      setState(() => _lines.removeAt(index));
    }
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHarvest == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر قطافة أولاً'), backgroundColor: Colors.red),
      );
      return;
    }

    final invoiceId = 'F-${DateFormat('yyyyMMdd').format(_invoiceDate)}-${DateTime.now().millisecondsSinceEpoch % 1000}';
    
    final invoice = Invoice(
      id: invoiceId,
      harvestId: _selectedHarvest!.id,
      invoiceDate: DateFormat('yyyy-MM-dd').format(_invoiceDate),
      trader: _traderController.text,
      commissionRate: _commissionRate,
      totalBeforeCommission: _totalBeforeCommission,
      commissionAmount: _commissionAmount,
      netAmount: _netAmount,
    );

    final invoiceLines = _lines.asMap().entries.map((entry) {
      final index = entry.key;
      final line = entry.value;
      return InvoiceLine(
        invoiceId: invoiceId,
        lineNumber: index + 1,
        crop: line.cropController.text,
        boxCount: int.parse(line.boxCountController.text),
        weight: double.parse(line.weightController.text),
        pricePerKg: double.parse(line.priceController.text),
        lineTotal: line.lineTotal,
      );
    }).toList();

    await DatabaseHelper.instance.insertInvoice(invoice, invoiceLines);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الفاتورة بنجاح'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الفاتورة')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('ربط القطافة'),
            const SizedBox(height: 12),
            _buildHarvestSelector(),
            const SizedBox(height: 24),
            _buildSectionTitle('معلومات الفاتورة'),
            const SizedBox(height: 12),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _traderController,
              label: 'اسم التاجر',
              validator: (v) => v?.isEmpty ?? true ? 'أدخل اسم التاجر' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _commissionController,
              label: 'نسبة العمولة (%)',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('سطور الفاتورة'),
            const SizedBox(height: 12),
            ..._lines.asMap().entries.map((entry) {
              return _buildLineForm(entry.key, entry.value);
            }),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addLine,
              icon: const Icon(Icons.add),
              label: const Text('إضافة سطر'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 24),
            _buildSummary(),
            const SizedBox(height: 24),
            _buildProfitCalculation(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'حفظ الفاتورة وإغلاق القطافة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
           
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
    );
  }

  Widget _buildHarvestSelector() {
    if (_openHarvests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 12),
            Text('لا توجد قطافات مفتوحة', style: TextStyle(color: Colors.orange)),
          ],
        ),
      );
    }

    return DropdownButtonFormField<Harvest>(
      value: _selectedHarvest,
      decoration: InputDecoration(
        labelText: 'اختر القطافة',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _openHarvests.map((harvest) {
        final date = DateTime.parse(harvest.harvestDate);
        return DropdownMenuItem(
          value: harvest,
          child: Text('${harvest.id} - ${harvest.crop} (${date.day}/${date.month})'),
        );
      }).toList(),
      onChanged: (harvest) {
        setState(() {
          _selectedHarvest = harvest;
          if (harvest?.trader != null) {
            _traderController.text = harvest!.trader!;
          }
        });
      },
      validator: (v) => v == null ? 'اختر قطافة' : null,
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'تاريخ الفاتورة',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('yyyy/MM/dd').format(_invoiceDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildLineForm(int index, InvoiceLineForm line) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('سطر ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_lines.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeLine(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: line.cropController,
              decoration: InputDecoration(
                labelText: 'نوع البضاعة',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v?.isEmpty ?? true ? 'أدخل النوع' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.boxCountController,
                    decoration: InputDecoration(
                      labelText: 'عدد الفلين',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'أدخل العدد' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: line.weightController,
                    decoration: InputDecoration(
                      labelText: 'الوزن (كيلو)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'أدخل الوزن' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: line.priceController,
              decoration: InputDecoration(
                labelText: 'سعر الكيلو (ل.س)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'أدخل السعر' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'المجموع: ${line.lineTotal.toStringAsFixed(0)} ل.س',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _SummaryRow('إجمالي المبالغ:', _totalBeforeCommission),
          const SizedBox(height: 8),
          _SummaryRow('العمولة ($_commissionRate%):', _commissionAmount, isNegative: true),
          const Divider(),
          _SummaryRow('المبلغ الصافي:', _netAmount, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildProfitCalculation() {
    if (_selectedHarvest == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _profit >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _profit >= 0 ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'حساب الربح',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _profit >= 0 ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          _SummaryRow('المبلغ الصافي:', _netAmount),
          const SizedBox(height: 8),
          _SummaryRow('تكلفة الفلين:', _selectedHarvest!.boxTotalCost, isNegative: true),
          const SizedBox(height: 8),
          _SummaryRow('أجرة النقل:', _selectedHarvest!.transportCost, isNegative: true),
          const Divider(),
          _SummaryRow(
            'الربح الصافي:',
            _profit,
            isTotal: true,
            color: _profit >= 0 ? Colors.green : Colors.red,
          ),
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
    return Row(
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
    );
  }
}

class InvoiceLineForm {
  final cropController = TextEditingController();
  final boxCountController = TextEditingController();
  final weightController = TextEditingController();
  final priceController = TextEditingController();

  double get lineTotal {
    final weight = double.tryParse(weightController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    return weight * price;
  }
}
