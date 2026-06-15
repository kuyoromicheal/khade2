import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/khade_api.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.bookingId, this.title});

  final int bookingId;
  final String? title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessageModel> _messages = [];
  Timer? _poll;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _load(silent: true));
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final list = await khadeApi.getBookingMessages(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _messages = list;
        _loading = false;
      });
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    } catch (_) {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final user = AuthService.instance.authUser ?? KhadeRepository.instance.user;
    try {
      final msg = await khadeApi.sendBookingMessage(
        bookingId: widget.bookingId,
        body: text,
        userId: user?.id,
        senderName: user?.name,
      );
      setState(() => _messages = [..._messages, msg]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.redDark));
      }
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = AuthService.instance.authUser?.id ?? KhadeRepository.instance.user?.id;
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(widget.title ?? 'Booking chat', style: AppTheme.serif(18)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.matcha))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final mine = myId != null && m.senderId == myId;
                      return Align(
                        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: mine ? AppColors.matcha : AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: mine ? null : Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!mine) Text(m.senderName, style: AppTheme.sans(10, color: AppColors.soft, weight: FontWeight.w500)),
                              Text(m.body, style: AppTheme.sans(13, color: mine ? AppColors.white : AppColors.dark)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
            decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      hintStyle: AppTheme.sans(13, color: AppColors.soft),
                      filled: true,
                      fillColor: AppColors.cream,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send, size: 20),
                  style: IconButton.styleFrom(backgroundColor: AppColors.matcha),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
