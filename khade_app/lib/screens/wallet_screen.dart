import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/tier_utils.dart';
import '../widgets/api_widgets.dart';
import '../widgets/common_widgets.dart';
import 'paystack_checkout_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _topping = false;

  Future<void> _topUp(int amount) async {
    setState(() => _topping = true);
    try {
      final repo = KhadeRepository.instance;
      final init = await repo.initializePaystack(amount);
      if (!mounted) return;
      if (init == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(repo.lastError ?? 'Could not start Paystack'), backgroundColor: AppColors.redDark),
        );
        return;
      }
      final ref = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => PaystackCheckoutScreen(
            authorizationUrl: init.authorizationUrl,
            reference: init.reference,
            amountLabel: formatNaira(amount),
          ),
        ),
      );
      if (!mounted || ref == null) return;
      final verified = await repo.verifyPaystack(ref);
      if (!verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment not verified'), backgroundColor: AppColors.redDark),
        );
        return;
      }
      final success = await repo.topUpWallet(amount, paystackReference: ref);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '${formatNaira(amount)} added to wallet' : 'Top-up failed'),
            backgroundColor: success ? AppColors.matcha : AppColors.redDark,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _topping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        final user = repo.user;
        final balance = user?.walletBalance ?? 0;
        final txs = repo.walletTransactions;

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              BackHeader(title: 'Khade Wallet', onBack: () => context.pop()),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.matchaDeep, AppColors.matcha]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Balance', style: AppTheme.sans(12, color: Colors.white70)),
                          Text(formatNaira(balance), style: AppTheme.serif(36, color: AppColors.white)),
                          const SizedBox(height: 4),
                          Text(TierUtils.cashbackLabel(user?.tier), style: AppTheme.sans(11, color: Colors.white60)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(child: FilledButton.icon(
                                onPressed: _topping ? null : () => _topUp(10000),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Top Up ₦10K'),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.dark),
                              )),
                              const SizedBox(width: 10),
                              Expanded(child: FilledButton.icon(
                                onPressed: _topping ? null : () => _topUp(50000),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Top Up ₦50K'),
                                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.matchaDeep),
                              )),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('RECENT TRANSACTIONS', style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1)),
                    const SizedBox(height: 12),
                    if (txs.isEmpty)
                      Center(child: Padding(padding: const EdgeInsets.all(20), child: Text('No transactions yet', style: AppTheme.sans(14, color: AppColors.soft))))
                    else
                      for (final tx in txs)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: tx.isCredit ? AppColors.greenBg : const Color(0xFFFFEBEE),
                                child: Icon(tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward, size: 16, color: tx.isCredit ? AppColors.green : AppColors.redDark),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx.description, style: AppTheme.sans(13, weight: FontWeight.w500)),
                                    Text(tx.reference, style: AppTheme.sans(10, color: AppColors.soft)),
                                  ],
                                ),
                              ),
                              Text(
                                '${tx.isCredit ? '+' : '-'}${formatNaira(tx.amount)}',
                                style: AppTheme.sans(13, color: tx.isCredit ? AppColors.green : AppColors.redDark, weight: FontWeight.w500),
                              ),
                            ],
                          ),
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
}
