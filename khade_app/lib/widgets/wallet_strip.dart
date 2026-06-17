import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'api_widgets.dart';

class WalletStrip extends StatelessWidget {
  const WalletStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final balance = KhadeRepository.instance.user?.walletBalance ?? 0;
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.matchaPale,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.matcha, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Khade Wallet', style: AppTheme.sans(10, color: AppColors.soft)),
                    Text(formatNaira(balance), style: AppTheme.serif(18, color: AppColors.matchaDeep)),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => context.push('/wallet'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.dark,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text('Top Up', style: AppTheme.sans(11, weight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }
}
