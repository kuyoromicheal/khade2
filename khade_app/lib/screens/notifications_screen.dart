import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final items = KhadeRepository.instance.notifications;
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: const BoxDecoration(color: AppColors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.matcha), onPressed: () => context.pop(), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                      const SizedBox(width: 10),
                      Text('Notifications', style: AppTheme.serif(22)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text('No notifications', style: AppTheme.sans(14, color: AppColors.soft)))
                    : ListView(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            _NotifTile(
                              emoji: items[i].emoji ?? '✦',
                              bg: i == 0 ? AppColors.matcha : const Color(0xFFF5F0F5),
                              highlight: i == 0,
                              title: items[i].title,
                              body: items[i].body,
                              time: i == 0 ? 'Just now' : i == 1 ? '2 hours ago' : 'Yesterday',
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

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.emoji, required this.bg, required this.title, required this.body, required this.time, this.highlight = false});
  final String emoji, title, body, time;
  final Color bg;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.matchaPale : AppColors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 18, backgroundColor: bg, child: Text(emoji, style: const TextStyle(fontSize: 16))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.sans(13, weight: FontWeight.w500)),
                Text(body, style: AppTheme.sans(12, color: AppColors.mid)),
                Text(time, style: AppTheme.sans(10, color: AppColors.soft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
