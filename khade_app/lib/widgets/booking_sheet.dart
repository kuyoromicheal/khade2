import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'api_widgets.dart';
import 'common_widgets.dart';

/// Result from the single booking gate: Just Me vs Group (+ optional quantity).
class BookingSheetResult {
  const BookingSheetResult({
    required this.bookingType,
    required this.quantity,
  });

  final String bookingType; // solo | group
  final int quantity;
}

/// One bottom sheet — "Who is this booking for?" then optional group size.
Future<BookingSheetResult?> showBookingSheet(BuildContext context, ServiceModel service) {
  return showModalBottomSheet<BookingSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => _BookingSheetBody(service: service),
  );
}

class _BookingSheetBody extends StatefulWidget {
  const _BookingSheetBody({required this.service});
  final ServiceModel service;

  @override
  State<_BookingSheetBody> createState() => _BookingSheetBodyState();
}

class _BookingSheetBodyState extends State<_BookingSheetBody> {
  String _step = 'who'; // who | quantity
  int _quantity = 2;
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _solo() {
    Navigator.pop(context, const BookingSheetResult(bookingType: 'solo', quantity: 1));
  }

  void _groupNext() => setState(() => _step = 'quantity');

  void _confirmGroup() {
    Navigator.pop(context, BookingSheetResult(bookingType: 'group', quantity: _quantity));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: _step == 'who' ? _whoStep() : _quantityStep(),
    );
  }

  Widget _whoStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who is this booking for?', style: AppTheme.serif(22)),
        Text(widget.service.name, style: AppTheme.sans(12, color: AppColors.soft)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _optionCard(
                icon: Icons.person_outline,
                title: 'Just Me',
                subtitle: '×1 · personal',
                onTap: _solo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _optionCard(
                icon: Icons.groups_outlined,
                title: 'Group Booking',
                subtitle: '2, 3, 4… guests',
                onTap: _groupNext,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quantityStep() {
    final subtotal = widget.service.price * _quantity;
    final fee = (subtotal * 0.1).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(onPressed: () => setState(() => _step = 'who'), icon: const Icon(Icons.arrow_back)),
            Text('Group size', style: AppTheme.serif(20)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [2, 3, 4, 5].map((n) {
            return ChoiceChip(
              label: Text('$n'),
              selected: _quantity == n,
              onSelected: (_) => setState(() => _quantity = n),
              selectedColor: AppColors.matcha,
              labelStyle: TextStyle(color: _quantity == n ? Colors.white : AppColors.mid),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _customCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '5+ custom number',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null && n >= 2) setState(() => _quantity = n);
          },
        ),
        const SizedBox(height: 16),
        Text('$_quantity people · ${formatNaira(subtotal)} + ${formatNaira(fee)} fee', style: AppTheme.sans(12, color: AppColors.soft)),
        const SizedBox(height: 12),
        PrimaryButton(label: 'Continue to date & time →', onPressed: _confirmGroup),
      ],
    );
  }

  Widget _optionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppColors.matcha),
            const SizedBox(height: 8),
            Text(title, style: AppTheme.sans(13, weight: FontWeight.w600)),
            Text(subtitle, style: AppTheme.sans(10, color: AppColors.soft), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
