import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final repo = KhadeRepository.instance;
      await repo.refreshNotifications();
      await repo.markAllNotificationsRead();
    });
  }

  Future<void> _onRefresh() async {
    await KhadeRepository.instance.refreshNotifications();
  }

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
                    ? RefreshIndicator(
                        color: AppColors.matcha,
                        onRefresh: _onRefresh,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                            Center(child: Text('No notifications', style: AppTheme.sans(14, color: AppColors.soft))),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.matcha,
                        onRefresh: _onRefresh,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, i) => _NotifTile(item: items[i]),
                        ),
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
  const _NotifTile({required this.item});
  final NotificationModel item;

  @override
  Widget build(BuildContext context) {
    final unread = !item.read;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: unread ? AppColors.matchaPale : AppColors.white,
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: unread ? AppColors.matcha : const Color(0xFFF5F0F5),
            child: Text(item.emoji ?? '✦', style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTheme.sans(13, weight: unread ? FontWeight.w600 : FontWeight.w500),
                ),
                Text(item.body, style: AppTheme.sans(12, color: AppColors.mid)),
                Text(formatTimeAgo(item.createdAt), style: AppTheme.sans(10, color: AppColors.soft)),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 4),
              decoration: const BoxDecoration(color: AppColors.matcha, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
