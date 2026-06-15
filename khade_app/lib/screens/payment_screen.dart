import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/common_widgets.dart';
import 'paystack_checkout_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    this.providerId = 1,
    this.serviceId = 1,
    this.scheduledAt = '2025-06-17T10:30:00',
    this.locationType = 'home',
    this.serviceName = 'Full Glam Makeup',
    this.providerName = 'Zara Beauty Studio',
    this.price = 12000,
    this.note,
  });

  final int providerId;
  final int serviceId;
  final String scheduledAt;
  final String locationType;
  final String serviceName;
  final String providerName;
  final int price;
  final String? note;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selected = 0;
  bool _paying = false;

  int get _fee => (widget.price * 0.1).round();
  int get _total => widget.price + _fee;

  String get _paymentMethod => switch (_selected) {
        0 => 'paystack',
        1 => 'cash',
        2 => 'transfer',
        _ => 'wallet',
      };

  Future<void> _pay() async {
    setState(() => _paying = true);
    final repo = KhadeRepository.instance;

    try {
      if (_selected == 0) {
        final init = await repo.initializePaystack(_total);
        if (!mounted || init == null) {
          if (mounted && repo.lastError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(repo.lastError!), backgroundColor: AppColors.redDark),
            );
          }
          return;
        }
        final ref = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (_) => PaystackCheckoutScreen(
              authorizationUrl: init.authorizationUrl,
              reference: init.reference,
              amountLabel: formatNaira(_total),
            ),
          ),
        );
        if (!mounted || ref == null) return;
        final verified = await repo.verifyPaystack(ref);
        if (!verified || !mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment not verified'), backgroundColor: AppColors.redDark),
          );
          return;
        }
      } else if (_selected == 2) {
        final ok = await _showBankTransferDialog();
        if (!ok || !mounted) return;
      } else if (_selected == 3) {
        final balance = repo.user?.walletBalance ?? 0;
        if (balance < _total) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Insufficient balance. You have ${formatNaira(balance)}'), backgroundColor: AppColors.redDark),
          );
          return;
        }
      }

      final homeAddress = widget.locationType == 'home' ? repo.userAddress : null;

      final result = await repo.completePaymentAndBook(
        providerId: widget.providerId,
        serviceId: widget.serviceId,
        scheduledAt: widget.scheduledAt,
        locationType: widget.locationType,
        address: homeAddress,
        totalAmount: _total,
        paymentMethod: _paymentMethod,
        note: widget.note,
      );

      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(repo.lastError ?? 'Payment failed'), backgroundColor: AppColors.redDark),
        );
        return;
      }
      context.push(
        '/confirm?code=${result.bookingCode}&total=${result.totalAmount}&service=${Uri.encodeComponent(widget.serviceName)}&provider=${Uri.encodeComponent(widget.providerName)}&date=${Uri.encodeComponent(formatBookingDate(widget.scheduledAt))}',
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<bool> _showBankTransferDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Bank Transfer', style: AppTheme.serif(18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transfer ${formatNaira(_total)} to:', style: AppTheme.sans(12)),
                const SizedBox(height: 8),
                Text('Khade Beauty Ltd', style: AppTheme.sans(13, weight: FontWeight.w500)),
                Text('GTBank · 0123456789', style: AppTheme.sans(12, color: AppColors.mid)),
                const SizedBox(height: 8),
                Text('Use ref: KHADE${DateTime.now().millisecondsSinceEpoch % 10000}', style: AppTheme.sans(11, color: AppColors.matcha)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("I've Paid")),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final walletBal = KhadeRepository.instance.user?.walletBalance ?? 0;
        final methods = [
          ('💳', 'Paystack', 'Card, Transfer, USSD & more'),
          ('💵', 'Pay on Arrival', 'Cash or POS at location'),
          ('🏦', 'Bank Transfer', 'Direct bank payment'),
          ('👛', 'Khade Wallet', 'Balance: ${formatNaira(walletBal)}'),
        ];

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              BackHeader(title: 'Payment', onBack: () => context.pop()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.matchaPale, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.matcha.withValues(alpha: 0.2))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ORDER SUMMARY', style: AppTheme.sans(10, color: AppColors.soft).copyWith(letterSpacing: 1)),
                          const SizedBox(height: 8),
                          _row(widget.serviceName, formatNaira(widget.price)),
                          _row('${widget.providerName} · ${formatBookingDate(widget.scheduledAt)}', '', soft: true),
                          _row('Service fee (10%)', formatNaira(_fee), soft: true),
                          const Divider(color: AppColors.matcha, height: 20),
                          _row('Total', formatNaira(_total), bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('CHOOSE PAYMENT METHOD', style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    for (var i = 0; i < methods.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => _selected = i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _selected == i ? AppColors.matchaPale : AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _selected == i ? AppColors.matcha : AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Text(methods[i].$1, style: const TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(methods[i].$2, style: AppTheme.sans(13, weight: FontWeight.w500)),
                                    Text(methods[i].$3, style: AppTheme.sans(11, color: AppColors.soft)),
                                  ],
                                ),
                              ),
                              if (_selected == i) const Icon(Icons.check_circle, color: AppColors.matcha),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _paying ? 'Processing...' : 'Pay ${formatNaira(_total)} →',
                      onPressed: _paying ? () {} : _pay,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String left, String right, {bool bold = false, bool soft = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(left, style: AppTheme.sans(soft ? 12 : 13, color: soft ? AppColors.soft : AppColors.dark))),
          if (right.isNotEmpty) Text(right, style: bold ? AppTheme.serif(20) : AppTheme.sans(soft ? 12 : 13, color: soft ? AppColors.soft : AppColors.dark)),
        ],
      ),
    );
  }
}
