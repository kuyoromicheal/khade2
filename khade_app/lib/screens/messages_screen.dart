import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/khade_api.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.bookingId});

  final int? bookingId;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    KhadeRepository.instance.loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.bookingId != null) {
      return _ChatView(bookingId: widget.bookingId!);
    }

    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final convos = KhadeRepository.instance.conversations;
        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.dark,
            elevation: 0,
            title: Text('Messages', style: AppTheme.serif(20)),
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
          ),
          body: convos.isEmpty
              ? Center(child: Text('No conversations yet', style: AppTheme.sans(14, color: AppColors.soft)))
              : ListView.separated(
                  itemCount: convos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, i) {
                    final c = convos[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.matchaPale,
                        child: Text(c.displayEmoji, style: const TextStyle(fontSize: 18)),
                      ),
                      title: Text(c.displayName, style: AppTheme.sans(14, weight: FontWeight.w600)),
                      subtitle: Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.sans(12, color: AppColors.soft)),
                      trailing: c.unread > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.matcha, borderRadius: BorderRadius.circular(10)),
                              child: Text('${c.unread}', style: AppTheme.sans(10, color: Colors.white)),
                            )
                          : Text(c.updatedAt, style: AppTheme.sans(10, color: AppColors.soft)),
                      onTap: () => context.push('/chat/${c.bookingId}'),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.bookingId});
  final int bookingId;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _controller = TextEditingController();
  List<MessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (KhadeRepository.instance.isLive) {
        _messages = await khadeApi.getMessages(widget.bookingId);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await khadeApi.sendMessage(bookingId: widget.bookingId, body: text);
      _messages = [..._messages, msg];
      _controller.clear();
      await KhadeRepository.instance.loadConversations();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.redDark));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = KhadeRepository.instance.bookingById(widget.bookingId);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.dark,
        elevation: 0,
        title: Text(booking?.providerName ?? 'Chat', style: AppTheme.serif(18)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          if (booking != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.matchaPale,
              child: Text('${booking.serviceName} · ${booking.bookingCode}', style: AppTheme.sans(11, color: AppColors.matchaDeep)),
            ),
          Expanded(
            child: _loading
                ? const LoadingPlaceholder()
                : _messages.isEmpty
                    ? Center(child: Text('Send a message to your provider', style: AppTheme.sans(14, color: AppColors.soft), textAlign: TextAlign.center))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          return Align(
                            alignment: m.isMine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              decoration: BoxDecoration(
                                color: m.isMine ? AppColors.matcha : AppColors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: m.isMine ? null : Border.all(color: AppColors.border),
                              ),
                              child: Text(m.body, style: AppTheme.sans(13, color: m.isMine ? Colors.white : AppColors.dark)),
                            ),
                          );
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _send,
                  icon: Icon(Icons.send, color: _sending ? AppColors.soft : AppColors.matcha),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
