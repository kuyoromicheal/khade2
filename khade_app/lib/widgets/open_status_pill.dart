import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/opening_hours.dart';

class OpenStatusPill extends StatefulWidget {
  const OpenStatusPill({super.key, this.openingHours});
  final Map<String, dynamic>? openingHours;

  @override
  State<OpenStatusPill> createState() => _OpenStatusPillState();
}

class _OpenStatusPillState extends State<OpenStatusPill> {
  bool _open = false;
  String _closing = '';
  Timer? _timer;

  void _check() {
    final hours = widget.openingHours;
    if (hours == null || hours.isEmpty) {
      setState(() { _open = true; _closing = ''; });
      return;
    }
    final now = DateTime.now();
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final day = days[now.weekday - 1];
    final raw = hours[day];
    if (raw is! Map || raw['open'] == null || raw['close'] == null) {
      setState(() { _open = false; _closing = ''; });
      return;
    }
    final openStr = raw['open'].toString();
    final closeStr = raw['close'].toString();
    final openParts = openStr.split(':');
    final closeParts = closeStr.split(':');
    final current = now.hour * 60 + now.minute;
    final openM = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
    final closeM = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);
    setState(() {
      _open = current >= openM && current < closeM;
      _closing = formatOpeningHoursDisplay(closeStr);
    });
  }

  @override
  void initState() {
    super.initState();
    _check();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _check());
  }

  @override
  void didUpdateWidget(covariant OpenStatusPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    _check();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _open ? AppColors.greenBg : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _open ? AppColors.green : AppColors.redDark),
          ),
          const SizedBox(width: 6),
          Text(
            _open ? (_closing.isNotEmpty ? 'Open · Closes $_closing' : 'Open Now') : 'Closed now',
            style: AppTheme.sans(11, color: _open ? AppColors.green : AppColors.redDark, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
