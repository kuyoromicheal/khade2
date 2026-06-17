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
    this.travelFee = 0,
    this.serviceFee = 0,
    this.total = 0,
    this.note,
  });

  final int providerId;
  final int serviceId;
  final String scheduledAt;
  final String locationType;
  final String serviceName;
  final String providerName;
  final int price;
  final int travelFee;
  final int serviceFee;
  final int total;
  final String? note;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'cash'; // cash | wallet
  bool _paying = false;

  int get _subtotal => widget.price;
  int get _travel => widget.travelFee;
  int get _fee => widget.serviceFee > 0 ? widget.serviceFee : ((_subtotal + _travel) * 0.1).round();
  int get _total => widget.total > 0 ? widget.total : _subtotal + _travel + _fee.round();

  Future<void> _topUpShortfall(int shortfall) async {
    final repo = KhadeRepository.instance;
    final init = await repo.initializePaystack(shortfall);
    if (!mounted || init == null) {
      if (mounted && repo.lastError != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(repo.lastError!), backgroundColor: AppColors.redDark));
      }
      return;
    }
    final ref = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => PaystackCheckoutScreen(
          authorizationUrl: init.authorizationUrl,
          reference: init.reference,
          amountLabel: formatNaira(shortfall),
        ),
      ),
    );
    if (!mounted || ref == null) return;
    final verified = await repo.verifyPaystack(ref);
    if (!verified) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Top-up not verified'), backgroundColor: AppColors.redDark));
      }
      return;
    }
    await repo.topUpWallet(shortfall, paystackReference: ref);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${formatNaira(shortfall)} added to wallet'), backgroundColor: AppColors.matcha));
      setState(() => _method = 'wallet');
    }
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    final repo = KhadeRepository.instance;

    try {
      if (_method == 'wallet') {
        final balance = repo.user?.walletBalance ?? 0;
        if (balance < _total) {
          await _topUpShortfall(_total - balance);
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
        paymentMethod: _method,
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final walletBal = KhadeRepository.instance.user?.walletBalance ?? 0;
        final canPayWallet = walletBal >= _total;
        final shortfall = _total - walletBal;

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
                          _row(widget.serviceName, formatNaira(_subtotal)),
                          if (_travel > 0) _row('Travel fee', formatNaira(_travel), soft: true),
                          _row('Service fee (10%)', formatNaira(_fee), soft: true),
                          _row('${widget.providerName} · ${formatBookingDate(widget.scheduledAt)}', '', soft: true),
                          const Divider(color: AppColors.matcha, height: 20),
                          _row('Total', formatNaira(_total), bold: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('HOW WOULD YOU LIKE TO PAY?', style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    _methodCard(
                      emoji: '💵',
                      title: 'Cash on Arrival',
                      subtitle: 'Pay your provider directly when they arrive or you arrive',
                      selected: _method == 'cash',
                      onTap: () => setState(() => _method = 'cash'),
                    ),
                    if (walletBal > 0 || _method == 'wallet') ...[
                      const SizedBox(height: 10),
                      _methodCard(
                        emoji: '👛',
                        title: 'Khade Wallet',
                        subtitle: canPayWallet
                            ? 'Pay instantly from your balance · ${formatNaira(walletBal)}'
                            : 'Insufficient balance · Top up ${formatNaira(shortfall)} more',
                        selected: _method == 'wallet',
                        enabled: canPayWallet,
                        trailing: canPayWallet ? formatNaira(walletBal) : null,
                        onTap: canPayWallet ? () => setState(() => _method = 'wallet') : null,
                        extra: !canPayWallet
                            ? TextButton(
                                onPressed: () => _topUpShortfall(shortfall),
                                child: Text('Top up ${formatNaira(shortfall)} →', style: AppTheme.sans(11, color: AppColors.matcha)),
                              )
                            : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: _paying
                          ? 'Processing...'
                          : _method == 'cash'
                              ? 'Confirm Booking →'
                              : 'Pay ${formatNaira(_total)} from Wallet →',
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

  Widget _methodCard({
    required String emoji,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback? onTap,
    bool enabled = true,
    String? trailing,
    Widget? extra,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.matchaPale : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.matcha : AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTheme.sans(13, weight: FontWeight.w600)),
                        Text(subtitle, style: AppTheme.sans(11, color: AppColors.soft)),
                      ],
                    ),
                  ),
                  if (trailing != null) Text(trailing, style: AppTheme.sans(12, color: AppColors.matcha, weight: FontWeight.w600)),
                  if (selected) const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.check_circle, color: AppColors.matcha)),
                ],
              ),
              if (extra != null) extra,
            ],
          ),
        ),
      ),
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
