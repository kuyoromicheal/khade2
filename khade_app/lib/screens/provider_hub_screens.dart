import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/khade_api.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/connection_banner.dart';

class ProviderClientsScreen extends StatefulWidget {
  const ProviderClientsScreen({super.key});

  @override
  State<ProviderClientsScreen> createState() => _ProviderClientsScreenState();
}

class _ProviderClientsScreenState extends State<ProviderClientsScreen> {
  String _query = '';
  int _filter = 0; // 0 all, 1 recent, 2 top, 3 new

  @override
  void initState() {
    super.initState();
    KhadeRepository.instance.loadProviderData();
  }

  List<ProviderClientModel> _filtered(List<ProviderClientModel> clients) {
    var list = clients;
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((c) => c.name.toLowerCase().contains(q) || (c.phone ?? '').contains(q)).toList();
    }
    switch (_filter) {
      case 1:
        final cutoff = DateTime.now().subtract(const Duration(days: 14));
        list = list.where((c) {
          final d = DateTime.tryParse(c.lastBookingAt);
          return d != null && d.isAfter(cutoff);
        }).toList();
      case 2:
        list = [...list]..sort((a, b) => b.lifetimeValue.compareTo(a.lifetimeValue));
      case 3:
        list = list.where((c) => c.bookingCount <= 1).toList();
    }
    return list;
  }

  String _lastLabel(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final clients = _filtered(KhadeRepository.instance.providerClients);
        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            title: Text('Your Clients', style: AppTheme.serif(24)),
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.dark,
          ),
          body: RefreshIndicator(
            color: AppColors.matcha,
            onRefresh: KhadeRepository.instance.loadProviderData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const ConnectionBanner(),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search clients...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (i, label) in [(0, 'All'), (1, 'Recent'), (2, 'Top'), (3, 'New')])
                      ChoiceChip(
                        label: Text(label),
                        selected: _filter == i,
                        onSelected: (_) => setState(() => _filter = i),
                        selectedColor: AppColors.matchaPale,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (clients.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No clients yet — bookings will appear here',
                      style: AppTheme.sans(13, color: AppColors.soft),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final c in clients)
                    Card(
                      color: AppColors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        onTap: () => context.push('/provider-clients/${c.userId}'),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.matchaPale,
                          child: Text(c.name.characters.first, style: AppTheme.sans(12, color: AppColors.matchaDeep)),
                        ),
                        title: Text(c.name, style: AppTheme.sans(14, weight: FontWeight.w600)),
                        subtitle: Text(
                          '${c.bookingCount} booking${c.bookingCount == 1 ? '' : 's'} · Last: ${_lastLabel(c.lastBookingAt)}',
                          style: AppTheme.sans(11, color: AppColors.soft),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(formatNaira(c.lifetimeValue), style: AppTheme.sans(12, weight: FontWeight.w600, color: AppColors.matchaDeep)),
                            Text('lifetime', style: AppTheme.sans(10, color: AppColors.soft)),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProviderClientDetailScreen extends StatelessWidget {
  const ProviderClientDetailScreen({super.key, required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final repo = KhadeRepository.instance;
        final client = repo.providerClients.where((c) => c.userId == userId).firstOrNull;
        final history = repo.providerBookings
            .where((b) => b.userId == userId && b.status != 'cancelled')
            .toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        final upcoming = history.where((b) => b.status == 'upcoming').toList();
        final past = history.where((b) => b.status == 'completed').toList();

        return _ProviderScaffold(
          title: client?.name ?? 'Client',
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (client != null)
                Card(
                  color: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${client.bookingCount} bookings · ${formatNaira(client.lifetimeValue)} lifetime', style: AppTheme.sans(12, color: AppColors.mid)),
                        if (client.phone != null) ...[
                          const SizedBox(height: 6),
                          Text(client.phone!, style: AppTheme.sans(12, color: AppColors.matcha)),
                        ],
                      ],
                    ),
                  ),
                ),
              _section('My Notes', const TextField(maxLines: 4, decoration: InputDecoration(hintText: 'Preferences, allergies, formulas...'))),
              _section(
                'Upcoming',
                upcoming.isEmpty
                    ? Text('No upcoming bookings', style: AppTheme.sans(12, color: AppColors.soft))
                    : Column(children: [for (final b in upcoming) _bookingRow(b)]),
              ),
              _section(
                'Booking History',
                past.isEmpty
                    ? Text('No completed bookings', style: AppTheme.sans(12, color: AppColors.soft))
                    : Column(children: [for (final b in past.take(10)) _bookingRow(b)]),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bookingRow(BookingModel b) {
    final d = DateTime.tryParse(b.scheduledAt);
    final when = d != null ? '${d.day}/${d.month} · ${b.status}' : b.status;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(b.serviceName, style: AppTheme.sans(13, weight: FontWeight.w500)),
      subtitle: Text(when, style: AppTheme.sans(11, color: AppColors.soft)),
      trailing: Text(formatNaira(b.totalAmount), style: AppTheme.sans(12, color: AppColors.matcha)),
    );
  }
}

class ProviderInboxScreen extends StatefulWidget {
  const ProviderInboxScreen({super.key});

  @override
  State<ProviderInboxScreen> createState() => _ProviderInboxScreenState();
}

class _ProviderInboxScreenState extends State<ProviderInboxScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    KhadeRepository.instance.loadConversations();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final convos = KhadeRepository.instance.conversations.where((c) {
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return c.displayName.toLowerCase().contains(q) || c.lastMessage.toLowerCase().contains(q);
        }).toList();

        return Scaffold(
          backgroundColor: AppColors.cream,
          appBar: AppBar(
            title: Text('Inbox', style: AppTheme.serif(24)),
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.dark,
          ),
          body: RefreshIndicator(
            color: AppColors.matcha,
            onRefresh: KhadeRepository.instance.loadConversations,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const ConnectionBanner(),
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppColors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                ),
                const SizedBox(height: 12),
                if (convos.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text('No conversations yet', style: AppTheme.sans(13, color: AppColors.soft), textAlign: TextAlign.center),
                  )
                else
                  for (final c in convos)
                    Card(
                      color: AppColors.white,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
                      child: ListTile(
                        onTap: () => context.push('/provider-inbox/${c.bookingId}'),
                        leading: CircleAvatar(backgroundColor: AppColors.matchaPale, child: Text(c.displayEmoji, style: const TextStyle(fontSize: 16))),
                        title: Text(c.displayName, style: AppTheme.sans(13, weight: FontWeight.w600)),
                        subtitle: Text(c.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.sans(11, color: AppColors.soft)),
                        trailing: c.unread > 0
                            ? CircleAvatar(radius: 10, backgroundColor: AppColors.matcha, child: Text('${c.unread}', style: AppTheme.sans(10, color: Colors.white)))
                            : Text(c.updatedAt, style: AppTheme.sans(10, color: AppColors.soft)),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ProviderChatScreen extends StatefulWidget {
  const ProviderChatScreen({super.key, required this.bookingId});
  final int bookingId;

  @override
  State<ProviderChatScreen> createState() => _ProviderChatScreenState();
}

class _ProviderChatScreenState extends State<ProviderChatScreen> {
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
      if (KhadeRepository.instance.isLive) {
        final msg = await khadeApi.sendMessage(bookingId: widget.bookingId, body: text);
        _messages = [..._messages, msg];
        _controller.clear();
        await KhadeRepository.instance.loadConversations();
      } else {
        _messages = [
          ..._messages,
          MessageModel(
            id: _messages.length + 1,
            bookingId: widget.bookingId,
            senderId: AuthService.instance.authUser?.id ?? 0,
            senderName: AuthService.instance.authUser?.name ?? 'You',
            body: text,
            createdAt: DateTime.now().toIso8601String(),
            isMine: true,
          ),
        ];
        _controller.clear();
      }
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
    final title = booking?.customerName ?? booking?.providerName ?? 'Chat';

    return _ProviderScaffold(
      title: title,
      child: Column(
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
                    ? Center(child: Text('Start the conversation', style: AppTheme.sans(13, color: AppColors.soft)))
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
                              child: Text(
                                m.body,
                                style: AppTheme.sans(13, color: m.isMine ? Colors.white : AppColors.dark),
                              ),
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

class _ProviderScaffold extends StatelessWidget {
  const _ProviderScaffold({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text(title, style: AppTheme.serif(22)),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.dark,
      ),
      body: child,
    );
  }
}

Widget _section(String title, Widget child) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.white,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.sans(12, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
