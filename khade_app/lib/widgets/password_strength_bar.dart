import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class PasswordStrengthBar extends StatelessWidget {
  const PasswordStrengthBar({super.key, required this.password});
  final String password;

  int get _score {
    var s = 0;
    if (password.length >= 8) s++;
    if (RegExp(r'[A-Z]').hasMatch(password)) s++;
    if (RegExp(r'\d').hasMatch(password)) s++;
    return s;
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text('Min 8 chars · 1 number · 1 capital letter', style: AppTheme.sans(10, color: AppColors.soft)),
      );
    }
    final colors = [AppColors.red, AppColors.gold, AppColors.matcha];
    final labels = ['Weak', 'Fair', 'Strong'];
    final idx = (_score - 1).clamp(0, 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(3, (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: i < _score ? colors[idx] : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
        ),
        const SizedBox(height: 4),
        Text(labels[idx], style: AppTheme.sans(10, color: colors[idx])),
      ],
    );
  }
}
