import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/connection_banner.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final all = KhadeRepository.instance.bookings;
        final bookings = _tab == 0
            ? all.where((b) => b.status == 'upcoming').toList()
            : all.where((b) => b.status != 'upcoming').toList();

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(color: AppColors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
              child: SafeArea(bottom: false, child: Text('My Bookings', style: AppTheme.serif(26))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _ViewSwitcher(labels: const ['Upcoming', 'History'], active: _tab, onChanged: (i) => setState(() => _tab = i)),
            ),
            const ConnectionBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: OutlinedButton.icon(
                onPressed: () => context.push('/group-booking'),
                icon: const Icon(Icons.groups_outlined, size: 18),
                label: const Text('Group / Owambe booking'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.matchaDeep, side: const BorderSide(color: AppColors.matcha)),
              ),
            ),
            Expanded(
              child: bookings.isEmpty
                  ? Center(child: Text('No bookings yet', style: AppTheme.sans(14, color: AppColors.soft)))
                  : ListView(
                      padding: const EdgeInsets.only(top: 8),
                      children: [
                        for (final b in bookings)
                          _BookingCard(
                            name: b.providerName,
                            date: formatBookingDate(b.scheduledAt),
                            service: '${b.providerEmoji} ${b.serviceName} · ${b.locationType == 'home' ? 'At My Location' : 'At Salon'}',
                            price: formatNaira(b.totalAmount),
                            status: b.status,
                            highlight: b.status == 'upcoming' && _tab == 0,
                            action: b.status == 'upcoming'
                                ? 'Track →'
                                : b.status == 'completed'
                                    ? 'Review'
                                    : 'Rebook',
                            onAction: () {
                              if (b.status == 'upcoming') {
                                context.push('/tracking?bookingId=${b.id}&code=${b.bookingCode}');
                              } else if (b.status == 'completed') {
                                context.push('/review?providerId=${b.providerId}&providerName=${Uri.encodeComponent(b.providerName)}&bookingId=${b.id}');
                              } else {
                                context.push('/booking?providerId=${b.providerId}');
                              }
                            },
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.name, required this.date, required this.service, required this.price, required this.status, required this.action, this.highlight = false, this.onAction});
  final String name, date, service, price, status, action;
  final bool highlight;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlight ? AppColors.matcha : AppColors.border, width: highlight ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: AppTheme.serif(16)), Text(date, style: AppTheme.sans(10, color: AppColors.soft))]),
              StatusBadge(label: status == 'upcoming' ? 'Upcoming' : status == 'completed' ? 'Completed' : 'Cancelled', type: status),
            ],
          ),
          const SizedBox(height: 10),
          Text(service, style: AppTheme.sans(12, color: AppColors.mid)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(price, style: AppTheme.sans(14, weight: FontWeight.w500)),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.matcha, side: const BorderSide(color: AppColors.matcha), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), minimumSize: Size.zero, textStyle: AppTheme.sans(11)),
                child: Text(action),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ViewSwitcher extends StatelessWidget {
  const _ViewSwitcher({required this.labels, required this.active, required this.onChanged});
  final List<String> labels;
  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(color: active == i ? AppColors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.center,
                  child: Text(labels[i], style: AppTheme.sans(12, color: active == i ? AppColors.dark : AppColors.soft, weight: active == i ? FontWeight.w500 : FontWeight.w400)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
