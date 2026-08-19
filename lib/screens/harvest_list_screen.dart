import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/harvest_model.dart';
import 'harvest_detail_screen.dart';
import 'invoice_screen.dart';

class HarvestListScreen extends StatefulWidget {
  const HarvestListScreen({super.key});

  @override
  State<HarvestListScreen> createState() => _HarvestListScreenState();
}

class _HarvestListScreenState extends State<HarvestListScreen> {
  List<Harvest> _harvests = [];
  List<Harvest> _filteredHarvests = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final harvests = await DatabaseHelper.instance.getAllHarvests();
    setState(() {
      _harvests = harvests;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    _filteredHarvests = _harvests.where((h) {
      final matchesSearch = _searchQuery.isEmpty ||
          h.crop.contains(_searchQuery) ||
          h.source.contains(_searchQuery) ||
          (h.trader?.contains(_searchQuery) ?? false);
      
      final matchesStatus = _statusFilter == 'all' || h.status == _statusFilter;
      
      return matchesSearch && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('القطافات'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'الكل',
                        isSelected: _statusFilter == 'all',
                        onSelected: () => setState(() {
                          _statusFilter = 'all';
                          _applyFilters();
                        }),
                      ),
                      _FilterChip(
                        label: 'مفتوحة',
                        isSelected: _statusFilter == 'open',
                        onSelected: () => setState(() {
                          _statusFilter = 'open';
                          _applyFilters();
                        }),
                      ),
                      _FilterChip(
                        label: 'تم النقل',
                        isSelected: _statusFilter == 'transported',
                        onSelected: () => setState(() {
                          _statusFilter = 'transported';
                          _applyFilters();
                        }),
                      ),
                      _FilterChip(
                        label: 'مغلقة',
                        isSelected: _statusFilter == 'closed',
                        onSelected: () => setState(() {
                          _statusFilter = 'closed';
                          _applyFilters();
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredHarvests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد نتائج',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredHarvests.length,
                  itemBuilder: (context, index) {
                    final harvest = _filteredHarvests[index];
                    return _HarvestListItem(
                      harvest: harvest,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HarvestDetailScreen(harvestId: harvest.id),
                        ),
                      ).then((_) => _loadData()),
                      onAddInvoice: harvest.status == 'open' || harvest.status == 'transported'
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InvoiceScreen(harvestId: harvest.id),
                              ),
                            ).then((_) => _loadData())
                          : null,
                    );
                  },
                ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
        checkmarkColor: const Color(0xFF2E7D32),
      ),
    );
  }
}

class _HarvestListItem extends StatelessWidget {
  final Harvest harvest;
  final VoidCallback onTap;
  final VoidCallback? onAddInvoice;

  const _HarvestListItem({
    required this.harvest,
    required this.onTap,
    this.onAddInvoice,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(harvest.harvestDate);
    final dateStr = DateFormat('yyyy/MM/dd').format(date);

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (harvest.status) {
      case 'open':
        statusColor = Colors.orange;
        statusText = 'مفتوحة';
        statusIcon = Icons.pending;
        break;
      case 'transported':
        statusColor = Colors.blue;
        statusText = 'تم النقل';
        statusIcon = Icons.local_shipping;
        break;
      case 'closed':
        statusColor = Colors.green;
        statusText = 'مغلقة';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'غير معروف';
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          harvest.crop,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${harvest.source} | ${harvest.boxCount} فلينة',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _InfoItem(icon: Icons.calendar_today, text: dateStr),
                  _InfoItem(icon: Icons.person, text: harvest.helper ?? 'بدون مساعد'),
                  _InfoItem(icon: Icons.wb_sunny, text: harvest.season),
                ],
              ),
              if (harvest.status != 'closed' && onAddInvoice != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAddInvoice,
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('تسجيل الفاتورة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
