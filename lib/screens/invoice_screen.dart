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
           
