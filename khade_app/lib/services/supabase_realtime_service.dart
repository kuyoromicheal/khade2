import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

typedef RealtimeVoidCallback = void Function();

/// Live updates from Supabase Realtime (notifications, messages, wallet).
class SupabaseRealtimeService {
  SupabaseRealtimeService._();
  static final SupabaseRealtimeService instance = SupabaseRealtimeService._();

  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _walletChannel;

  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey, // publishable key (Supabase anon JWT)
    );
  }

  bool get isReady => SupabaseConfig.isConfigured;

  Future<void> start({
    required int userId,
    RealtimeVoidCallback? onNotifications,
    RealtimeVoidCallback? onMessages,
    RealtimeVoidCallback? onWallet,
  }) async {
    if (!isReady) return;
    await stop();
    final client = Supabase.instance.client;

    _notificationsChannel = client
        .channel('khade-notifications-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'khade_notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (_) => onNotifications?.call(),
        )
        .subscribe();

    _messagesChannel = client
        .channel('khade-messages-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'khade_messages',
          callback: (_) => onMessages?.call(),
        )
        .subscribe();

    _walletChannel = client
        .channel('khade-wallet-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'khade_wallet_transactions',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (_) => onWallet?.call(),
        )
        .subscribe();
  }

  Future<void> stop() async {
    final client = Supabase.instance.client;
    if (_notificationsChannel != null) await client.removeChannel(_notificationsChannel!);
    if (_messagesChannel != null) await client.removeChannel(_messagesChannel!);
    if (_walletChannel != null) await client.removeChannel(_walletChannel!);
    _notificationsChannel = null;
    _messagesChannel = null;
    _walletChannel = null;
  }
}
