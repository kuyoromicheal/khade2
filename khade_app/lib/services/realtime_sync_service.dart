import 'dart:async';
import 'package:flutter/foundation.dart';
import 'khade_api.dart';
import 'khade_repository.dart';
import 'auth_service.dart';

/// Polls /api/sync/snapshot every 4s — wallet, notifications & feed stay live.
class RealtimeSyncService {
  RealtimeSyncService._();
  static final RealtimeSyncService instance = RealtimeSyncService._();

  Timer? _timer;
  String? _since;
  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _since = null;
  }

  Future<void> _poll() async {
    if (!KhadeRepository.instance.isLive) return;
    try {
      final userId = AuthService.instance.authUser?.id ?? khadeApi.userId;
      final snap = await khadeApi.getSyncSnapshot(userId: userId, since: _since);
      _since = snap.serverTime;
      KhadeRepository.instance.applySyncSnapshot(snap);
    } catch (e) {
      debugPrint('Realtime sync: $e');
    }
  }
}
