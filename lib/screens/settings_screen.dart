import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _cropController = TextEditingController();
  final _sourceController = TextEditingController();
  final _driverController = TextEditingController();
  final _traderNameController = TextEditingController();
  final _traderCommissionController = TextEditingController();

  List<String> _crops = [];
  List<String> _sources = [];
  List<String> _drivers = [];
  List<Map<String, dynamic>> _traders = [];

  @override
  void initState() {
    super.initState();
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
      _traders = _parseTraders(tradersStr);
    });
  }

  List<Map<String, dynamic>> _parseTraders(String str) {
    if (str.isEmpty) return [];
    return str.split(';').where((s) => s.isNotEmpty).map((t) {
      final parts = t.split(':');
      return {'name': parts[0], 'commission': double.tryParse(parts[1]) ?? 7};
    }).toList();
  }

  String _tradersToString() {
    return _traders.map((t) => '${t['name']}:${t['commission']}').join(';');
  }

  Future<void> _saveCrops() async {
    if (_cropController.text.isNotEmpty) {
      setState(() => _crops.add(_cropController.text));
      _cropController.clear();
      await DatabaseHelper.instance.setSetting('crops', _crops.join(','));
    }
  }

  Future<void> _saveSources() async {
    if (_sourceController.text.isNotEmpty) {
      setState(() => _sources.add(_sourceController.text));
      _sourceController.clear();
      await DatabaseHelper.instance.setSetting('sources', _sources.join(','));
    }
  }

  Future<void> _saveDrivers() async {
    if (_driverController.text.isNotEmpty) {
      setState(() => _drivers.add(_driverController.text));
      _driverController.clear();
      await DatabaseHelper.instance.setSetting('drivers', _drivers.join(','));
    }
  }

  Future<void> _saveTrader() async {
    if (_traderNameController.text.isNotEmpty) {
      setState(() => _traders.add({
        'name': _traderNameController.text,
        'commission': double.tryParse(_traderCommissionController.text) ?? 7,
      }));
      _traderNameController.clear();
      _traderCommissionController.text = '7';
      await DatabaseHelper.instance.setSetting('traders', _tradersToString());
    }
  }

  Future<void> _deleteItem(String type, dynamic item) async {
    switch (type) {
      case 'crop':
        setState(() => _crops.remove(item));
        await DatabaseHelper.instance.setSetting('crops', _crops.join(','));
        break;
      case 'source':
        setState(() => _sources.remove(item));
        await DatabaseHelper.instance.setSetting('sources', _sources.join(','));
        break;
      case 'driver':
        setState(() => _drivers.remove(item));
        await DatabaseHelper.instance.setSetting('drivers', _drivers.join(','));
        break;
      case 'trader':
        setState(() => _traders.remove(item));
        await DatabaseHelper.instance.setSetting('traders', _tradersToString());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('المحاصيل', _crops, 'crop', _cropController, 'محصول جديد'),
          _buildSection('مصادر المحصول', _sources, 'source', _sourceController, 'مصدر جديد'),
          _buildSection('السائقين', _drivers, 'driver', _driverController, 'سائق جديد'),
          _buildTraderSection(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, String type, TextEditingController controller, String hint) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => Chip(
                label: Text(item),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _deleteItem(type, item),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: hint,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF2E7D32), size: 32),
                  onPressed: () {
                    switch (type) {
                      case 'crop': _saveCrops(); break;
                      case 'source': _saveSources(); break;
                      case 'driver': _saveDrivers(); break;
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTraderSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('التجار', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _traders.map((t) => Chip(
                label: Text('${t['name']} (${t['commission']}%)'),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _deleteItem('trader', t),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _traderNameController,
                    decoration: InputDecoration(
                      hintText: 'اسم التاجر',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _traderCommissionController,
                    decoration: InputDecoration(
                      hintText: 'العمولة %',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF2E7D32), size: 32),
                  onPressed: _saveTrader,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
