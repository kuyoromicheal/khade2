import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class CancelScreen extends StatefulWidget {
  const CancelScreen({super.key, this.bookingId = 1, this.providerName = 'Provider'});

  final int bookingId;
  final String providerName;

  @override
  State<CancelScreen> createState() => _CancelScreenState();
}

class _CancelScreenState extends State<CancelScreen> {
  int _reason = 1;
  bool _cancelling = false;
  final _reasons = ['Schedule conflict', 'Found a better price', 'Emergency / personal reason', 'Other'];

  Future<void> _confirmCancel() async {
    setState(() => _cancelling = true);
    final ok = await KhadeRepository.instance.cancelBooking(widget.bookingId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled'), backgroundColor: AppColors.matcha),
      );
      context.go('/appointments');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(KhadeRepository.instance.lastError ?? 'Cancel failed'), backgroundColor: AppColors.redDark),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(color: AppColors.redBg, shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_outlined, size: 32, color: AppColors.redDark),
              ),
              const SizedBox(height: 20),
              Text('Cancel Booking?', style: AppTheme.serif(24), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Are you sure you want to cancel your appointment with ',
                  style: AppTheme.sans(13, color: AppColors.soft).copyWith(height: 1.6),
                  children: [
                    TextSpan(text: widget.providerName, style: AppTheme.sans(13, color: AppColors.dark, weight: FontWeight.w600)),
                    const TextSpan(text: '? A 10% cancellation fee may apply.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('REASON FOR CANCELLATION', style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1)),
              ),
              const SizedBox(height: 10),
              for (var i = 0; i < _reasons.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _reason = i),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: _reason == i ? AppColors.matchaPale : AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _reason == i ? AppColors.matcha : AppColors.border),
                    ),
                    child: Text(_reasons[i], style: AppTheme.sans(13)),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _cancelling ? null : _confirmCancel,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.redDark,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_cancelling ? 'Cancelling...' : 'Confirm Cancellation'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Keep Appointment', style: AppTheme.sans(14, color: AppColors.mid)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
