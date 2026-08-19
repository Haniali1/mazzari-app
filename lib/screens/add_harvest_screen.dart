import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/harvest_model.dart';

class AddHarvestScreen extends StatefulWidget {
  const AddHarvestScreen({super.key});

  @override
  State<AddHarvestScreen> createState() => _AddHarvestScreenState();
}

class _AddHarvestScreenState extends State<AddHarvestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  DateTime _harvestDate = DateTime.now();
  String? _selectedCrop;
  String? _selectedSource;
  final _boxCountController = TextEditingController();
  int? _selectedArrangement;
  final _helperController = TextEditingController();
  String _season = '';
  final _notesController = TextEditingController();
  final _driverController = TextEditingController();
  final _transportCostController = TextEditingController(text: '0');
  final _boxUnitPriceController = TextEditingController(text: '0');
  final _traderController = TextEditingController();

  List<String> _crops = [];
  List<String> _sources = [];
  List<String> _drivers = [];
  List<String> _traders = [];

  @override
  void initState() {
    super.initState();
    _season = _calculateSeason(_harvestDate);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final cropsStr = await DatabaseHelper.instance.getSetting('crops') ?? '';
    final sourcesStr = await DatabaseHelper.instance.getSetting('sources') ?? '';
    final driversStr = await DatabaseHelper.instance.getSetting('drivers') ?? '';
    final tradersStr = await DatabaseHelper.instance.getSetting('traders') ?? '';

    setState(() {
      _crops = cropsStr.isEmpty ? [] : cropsStr.split(',');
      _sources = sourcesStr.isEmpty ? [] : sourcesStr.split(',');
      _drivers = driversStr.isEmpty ? [] : driversStr.split(',');
      _traders = tradersStr.isEmpty ? [] : tradersStr.split(',');
    });
  }

  String _calculateSeason(DateTime date) {
    final month = date.month;
    final year = date.year;
    if (month >= 4 && month <= 9) {
      return 'صيف $year';
    } else {
      return 'شتاء $year';
    }
  }

  double get _boxTotalCost {
    final count = int.tryParse(_boxCountController.text) ?? 0;
    final price = double.tryParse(_boxUnitPriceController.text) ?? 0;
    return count * price;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _harvestDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _harvestDate = picked;
        _season = _calculateSeason(picked);
      });
    }
  }

  Future<void> _saveHarvest() async {
    if (!_formKey.currentState!.validate()) return;

    final id = 'H-${DateFormat('yyyyMMdd').format(_harvestDate)}-${DateTime.now().millisecondsSinceEpoch % 1000}';
    
    final harvest = Harvest(
      id: id,
      harvestDate: DateFormat('yyyy-MM-dd').format(_harvestDate),
      crop: _selectedCrop!,
      source: _selectedSource!,
      boxCount: int.parse(_boxCountController.text),
      arrangement: _selectedArrangement,
      helper: _helperController.text.isEmpty ? null : _helperController.text,
      season: _season,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      driver: _driverController.text.isEmpty ? null : _driverController.text,
      transportCost: double.tryParse(_transportCostController.text) ?? 0,
      boxUnitPrice: double.tryParse(_boxUnitPriceController.text) ?? 0,
      boxTotalCost: _boxTotalCost,
      trader: _traderController.text.isEmpty ? null : _traderController.text,
      status: 'open',
    );

    await DatabaseHelper.instance.insertHarvest(harvest);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ القطافة بنجاح'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قطافة جديدة')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('معلومات القطاف'),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'المحصول',
              value: _selectedCrop,
              items: _crops,
              onChanged: (v) => setState(() => _selectedCrop = v),
              validator: (v) => v == null ? 'اختر المحصول' : null,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              label: 'المصدر',
              value: _selectedSource,
              items: _sources,
              onChanged: (v) => setState(() => _selectedSource = v),
              validator: (v) => v == null ? 'اختر المصدر' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _boxCountController,
              label: 'عدد الفلين',
              keyboardType: TextInputType.number,
              validator: (v) => v?.isEmpty ?? true ? 'أدخل العدد' : null,
            ),
            const SizedBox(height: 16),
            _buildArrangementSelector(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _helperController,
              label: 'المساعد في القطاف',
            ),
            const SizedBox(height: 16),
            _buildSeasonDisplay(),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _notesController,
              label: 'ملاحظات',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('معلومات النقل'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _driverController,
              label: 'اسم السائق',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _transportCostController,
              label: 'أجرة النقل (ل.س)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _boxUnitPriceController,
              label: 'سعر الفلينة الواحدة (ل.س)',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            _buildCostSummary(),
            const SizedBox(height: 24),
            _buildSectionTitle('معلومات التاجر'),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _traderController,
              label: 'اسم التاجر',
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveHarvest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'حفظ القطافة',
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

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'تاريخ القطاف',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          DateFormat('yyyy/MM/dd').format(_harvestDate),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    int? maxLines,
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
      maxLines: maxLines ?? 1,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildArrangementSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('طريقة الترتيب (اختياري)', style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 8),
        Row(
          children: [2, 3, 4].map((layers) {
            final isSelected = _selectedArrangement == layers;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text('$layers طبقات'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedArrangement = selected ? layers : null;
                  });
                },
                selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                checkmarkColor: const Color(0xFF2E7D32),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSeasonDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny, color: Colors.blue),
          const SizedBox(width: 12),
          Text(
            'الموسم: $_season',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildCostSummary() {
    final boxCount = int.tryParse(_boxCountController.text) ?? 0;
    final unitPrice = double.tryParse(_boxUnitPriceController.text) ?? 0;
    final total = boxCount * unitPrice;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('تكلفة الفلين:', style: TextStyle(color: Colors.grey[700])),
              Text('$boxCount × $unitPrice = ${total.toStringAsFixed(0)} ل.س',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
