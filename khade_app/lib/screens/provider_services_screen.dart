import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProviderServicesScreen extends StatefulWidget {
  const ProviderServicesScreen({super.key});

  @override
  State<ProviderServicesScreen> createState() => _ProviderServicesScreenState();
}

class _ProviderServicesScreenState extends State<ProviderServicesScreen> {
  final _name = TextEditingController();
  final _duration = TextEditingController(text: '60 mins');
  final _price = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _duration.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_name.text.trim().isEmpty || _price.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await khadeApi.onboardProvider(
        categorySlug: 'makeup',
        services: [
          {'name': _name.text.trim(), 'duration': _duration.text.trim(), 'price': int.tryParse(_price.text) ?? 5000},
        ],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service saved'), backgroundColor: AppColors.matcha));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Add Service', style: AppTheme.serif(20)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Customers choose from your service menu when booking.', style: AppTheme.sans(13, color: AppColors.mid)),
          const SizedBox(height: 20),
          _field('Service name', _name, hint: 'e.g. Full Glam Makeup'),
          const SizedBox(height: 12),
          _field('Duration', _duration, hint: '60 mins'),
          const SizedBox(height: 12),
          _field('Price (₦)', _price, keyboard: TextInputType.number, hint: '12000'),
          const SizedBox(height: 24),
          PrimaryButton(label: _saving ? 'Saving...' : 'Save Service', onPressed: _saving ? null : _add),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {String? hint, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.sans(11, color: AppColors.soft)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          ),
        ),
      ],
    );
  }
}
