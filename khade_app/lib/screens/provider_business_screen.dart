import 'package:flutter/material.dart';
import '../services/khade_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';

class ProviderBusinessScreen extends StatefulWidget {
  const ProviderBusinessScreen({super.key});

  @override
  State<ProviderBusinessScreen> createState() => _ProviderBusinessScreenState();
}

class _ProviderBusinessScreenState extends State<ProviderBusinessScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        khadeApi.getCrmClients(),
        khadeApi.getProviderStaff(),
        khadeApi.getProviderInventory(),
        khadeApi.getCapitalLoans(),
      ]);
      if (!mounted) return;
      setState(() {
        _clients = results[0];
        _staff = results[1];
        _inventory = results[2];
        _loans = results[3];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _addClient() async {
    final name = await _prompt('Client name');
    if (name == null || name.isEmpty) return;
    await khadeApi.addCrmClient(name: name, phone: '08000000000');
    await _load();
  }

  Future<void> _addStaff() async {
    final name = await _prompt('Staff name');
    if (name == null || name.isEmpty) return;
    await khadeApi.addProviderStaff(name: name, role: 'Stylist');
    await _load();
  }

  Future<void> _addStock() async {
    final name = await _prompt('Product name');
    if (name == null || name.isEmpty) return;
    await khadeApi.addInventoryItem(name: name, quantity: 10);
    await _load();
  }

  Future<void> _sendCampaign() async {
    final title = await _prompt('Campaign title', initial: 'Weekend promo');
    if (title == null) return;
    final r = await khadeApi.sendCampaign(title: title, message: 'Book with Khade this weekend — 10% off!');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent to ${r['recipients']} clients'), backgroundColor: AppColors.matcha),
      );
    }
    await _load();
  }

  Future<void> _applyCapital() async {
    final amount = await _prompt('Loan amount (₦)', initial: '500000');
    if (amount == null) return;
    await khadeApi.applyCapitalLoan(amount: int.tryParse(amount) ?? 500000);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khade Capital application submitted'), backgroundColor: AppColors.matcha),
      );
    }
  }

  Future<String?> _prompt(String label, {String? initial}) async {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label, style: AppTheme.serif(18)),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Business tools', style: AppTheme.serif(20)),
        backgroundColor: AppColors.matchaDeep,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'CRM'),
            Tab(text: 'Staff'),
            Tab(text: 'Stock'),
            Tab(text: 'Campaigns'),
            Tab(text: 'Capital'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.matcha))
          : TabBarView(
              controller: _tabs,
              children: [
                _listTab('Clients', _clients, (c) => c['name']?.toString() ?? 'Client', onAdd: _addClient),
                _listTab('Team', _staff, (s) => '${s['name']} · ${s['role']}', onAdd: _addStaff),
                _listTab('Inventory', _inventory, (i) => '${i['name']} · qty ${i['quantity']}', onAdd: _addStock),
                _campaignsTab(),
                _capitalTab(),
              ],
            ),
    );
  }

  Widget _listTab(String empty, List<Map<String, dynamic>> rows, String Function(Map<String, dynamic>) label, {required VoidCallback onAdd}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: Text('Add $empty')),
        ),
        if (rows.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('No $empty yet', style: AppTheme.sans(14, color: AppColors.soft))))
        else
          for (final row in rows)
            Card(
              child: ListTile(title: Text(label(row), style: AppTheme.sans(13, weight: FontWeight.w500))),
            ),
      ],
    );
  }

  Widget _campaignsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('SMS & in-app campaigns to your CRM clients', style: AppTheme.sans(13, color: AppColors.mid)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _sendCampaign,
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Send weekend promo'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.matcha, minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }

  Widget _capitalTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Khade Capital — equipment & stock loans repaid via booking commission.', style: AppTheme.sans(13, color: AppColors.mid)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _applyCapital,
          icon: const Icon(Icons.account_balance_outlined),
          label: const Text('Apply for ₦500,000'),
          style: FilledButton.styleFrom(backgroundColor: AppColors.matchaDeep, minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 20),
        if (_loans.isEmpty)
          Text('No applications yet', style: AppTheme.sans(13, color: AppColors.soft))
        else
          for (final loan in _loans)
            Card(
              child: ListTile(
                title: Text(formatNaira(loan['amount'] as int? ?? 0), style: AppTheme.sans(14, weight: FontWeight.w500)),
                subtitle: Text('${loan['status']} · ${loan['purpose'] ?? ''}', style: AppTheme.sans(11, color: AppColors.soft)),
              ),
            ),
      ],
    );
  }
}
