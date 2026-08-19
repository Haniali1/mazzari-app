import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/harvest_model.dart';
import 'add_harvest_screen.dart';
import 'harvest_list_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'invoice_screen.dart';
import 'harvest_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Harvest> _harvests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final harvests = await DatabaseHelper.instance.getAllHarvests();
    setState(() {
      _harvests = harvests;
      _isLoading = false;
    });
  }

  int get _openCount => _harvests.where((h) => h.status == 'open').length;
  int get _closedCount => _harvests.where((h) => h.status == 'closed').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مزارعي', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SettingsScreen())
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    _buildRecentHarvests(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AddHarvestScreen())
        ).then((_) => _loadData()),
        icon: const Icon(Icons.add),
        label: const Text('قطافة جديدة'),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _SummaryCard(
          title: 'إجمالي القطافات',
          value: _harvests.length.toString(),
          icon: Icons.agriculture,
          color: const Color(0xFF2E7D32),
        ),
        _SummaryCard(
          title: 'قطافات مفتوحة',
          value: _openCount.toString(),
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _SummaryCard(
          title: 'قطافات مغلقة',
          value: _closedCount.toString(),
          icon: Icons.check_circle,
          color: Colors.blue,
        ),
        _SummaryCard(
          title: 'هذا الشهر',
          value: _harvests.where((h) {
            final now = DateTime.now();
            final date = DateTime.parse(h.harvestDate);
            return date.month == now.month && date.year == now.year;
          }).length.toString(),
          icon: Icons.calendar_month,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'إجراءات سريعة',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.list_alt,
                label: 'القطافات',
                color: const Color(0xFF2E7D32),
                onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const HarvestListScreen())
                ).then((_) => _loadData()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.bar_chart,
                label: 'التقارير',
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const ReportsScreen())
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.receipt_long,
                label: 'فاتورة',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const InvoiceScreen())
                ).then((_) => _loadData()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentHarvests() {
    final recent = _harvests.take(5).toList();
    if (recent.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.agriculture_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'لا توجد قطافات بعد',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط على الزر السفلي لإضافة قطافة جديدة',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'آخر القطافات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HarvestListScreen())
              ),
              child: const Text('عرض الكل'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recent.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final harvest = recent[index];
            return _HarvestCard(
              harvest: harvest,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HarvestDetailScreen(harvestId: harvest.id),
                ),
              ).then((_) => _loadData()),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _HarvestCard extends StatelessWidget {
  final Harvest harvest;
  final VoidCallback onTap;

  const _HarvestCard({required this.harvest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(harvest.harvestDate);
    final dateStr = '${date.day}/${date.month}/${date.year}';
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (harvest.status) {
      case 'open':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'مفتوحة';
        break;
      case 'transported':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        statusText = 'تم النقل';
        break;
      case 'closed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'مغلقة';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'غير معروف';
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.agriculture, color: Color(0xFF2E7D32)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${harvest.crop} - ${harvest.source}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${harvest.boxCount} فلينة | $dateStr',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
        ),
      ),
    );
  }
}
