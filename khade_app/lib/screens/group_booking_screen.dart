import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/khade_api.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';

class GroupBookingScreen extends StatefulWidget {
  const GroupBookingScreen({super.key, this.providerId});

  final int? providerId;

  @override
  State<GroupBookingScreen> createState() => _GroupBookingScreenState();
}

class _GroupBookingScreenState extends State<GroupBookingScreen> {
  final _titleController = TextEditingController(text: 'Owambe glam squad');
  final _guestController = TextEditingController(text: '8');
  final _addressController = TextEditingController(text: 'Asokoro, Abuja');
  final _noteController = TextEditingController();
  int _providerId = 1;
  int _serviceId = 1;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.providerId != null) _providerId = widget.providerId!;
    final repo = KhadeRepository.instance;
    final p = repo.providerById(_providerId);
    if (p != null && p.services.isNotEmpty) _serviceId = p.services.first.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _guestController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final result = await khadeApi.createGroupBooking(
        title: _titleController.text.trim(),
        guestCount: int.tryParse(_guestController.text) ?? 1,
        address: _addressController.text.trim(),
        providerId: _providerId,
        serviceId: _serviceId,
        scheduledAt: '2025-06-20T14:00:00',
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      await KhadeRepository.instance.refresh();
      if (!mounted) return;
      context.go('/confirm?code=${Uri.encodeComponent(result['bookingCode'] as String)}&total=${result['totalAmount']}&service=${Uri.encodeComponent(_titleController.text)}&provider=${Uri.encodeComponent('Group booking')}&date=${Uri.encodeComponent('Sat Jun 20 · 2:00 PM')}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.redDark));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final providers = KhadeRepository.instance.providers;
        ProviderModel? selected;
        for (final p in providers) {
          if (p.id == _providerId) {
            selected = p;
            break;
          }
        }
        final services = selected?.services.isNotEmpty == true
            ? selected!.services
            : [const ServiceModel(id: 1, name: 'Bridal glam', duration: '120 mins', price: 45000)];

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            title: Text('Group / Owambe', style: AppTheme.serif(20)),
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.dark,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Book glam for your whole squad — weddings, birthdays & owambe.', style: AppTheme.sans(13, color: AppColors.mid)),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Event name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _guestController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Number of guests', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Venue address', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _providerId,
                decoration: const InputDecoration(labelText: 'Lead provider', border: OutlineInputBorder()),
                items: providers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _providerId = v;
                    final p = KhadeRepository.instance.providerById(v);
                    if (p != null && p.services.isNotEmpty) _serviceId = p.services.first.id;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _serviceId,
                decoration: const InputDecoration(labelText: 'Service package', border: OutlineInputBorder()),
                items: services.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} · ${formatNaira(s.price)}'))).toList(),
                onChanged: (v) => setState(() => _serviceId = v ?? _serviceId),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(backgroundColor: AppColors.matcha, minimumSize: const Size.fromHeight(48)),
                child: _submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create group booking'),
              ),
            ],
          ),
        );
      },
    );
  }
}
