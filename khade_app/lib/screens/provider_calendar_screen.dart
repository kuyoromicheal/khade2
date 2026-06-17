import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/khade_api.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';

const _allSlots = ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

class ProviderCalendarScreenView extends StatefulWidget {
  const ProviderCalendarScreenView({super.key});

  @override
  State<ProviderCalendarScreenView> createState() => _ProviderCalendarScreenViewState();
}

class _ProviderCalendarScreenViewState extends State<ProviderCalendarScreenView> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  DateTime _selected = DateTime.now();
  int _hoursDay = 0; // 0-6 Mon-Sun for availability editor
  bool _loading = true;
  bool _saving = false;
  bool _showHours = false;
  Map<String, dynamic> _availability = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this, initialIndex: 1);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await KhadeRepository.instance.loadProviderData();
    try {
      if (KhadeRepository.instance.isLive) {
        final me = await khadeApi.getProviderMe();
        _availability = Map<String, dynamic>.from(me['availability'] as Map? ?? {});
      } else {
        _availability = _defaultAvailability();
      }
    } catch (_) {
      _availability = _defaultAvailability();
    }
    if (mounted) setState(() => _loading = false);
  }

  Map<String, dynamic> _defaultAvailability() => {
        for (final d in ['mon', 'tue', 'wed', 'thu', 'fri']) d: ['09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00'],
        'sat': ['10:00', '11:00', '12:00', '14:00', '15:00', '16:00'],
        'sun': <String>[],
        'blocked_dates': <String>[],
      };

  String _dateStr(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _dayKey(DateTime d) {
    const keys = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    return keys[d.weekday % 7];
  }

  List<BookingModel> get _bookings {
    final pid = AuthService.instance.authUser?.providerId ?? 1;
    return KhadeRepository.instance.providerBookings.isNotEmpty
        ? KhadeRepository.instance.providerBookings
        : KhadeRepository.instance.bookingsForProvider(pid);
  }

  List<BookingModel> _on(DateTime d) {
    final key = _dateStr(d);
    return _bookings.where((b) => b.status != 'cancelled' && b.scheduledAt.startsWith(key)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  bool _blocked(DateTime d) => ((_availability['blocked_dates'] as List?)?.cast<String>() ?? []).contains(_dateStr(d));

  Future<void> _save(Map<String, dynamic> patch) async {
    setState(() => _saving = true);
    _availability = {..._availability, ...patch};
    try {
      if (KhadeRepository.instance.isLive) {
        _availability = Map<String, dynamic>.from(await khadeApi.updateProviderAvailability(patch));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved'), backgroundColor: AppColors.matcha));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppColors.redDark));
    }
    if (mounted) setState(() => _saving = false);
  }

  void _openBooking(BookingModel b) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.ivory,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(b.customerName ?? b.serviceName, style: AppTheme.serif(20)),
            Text(b.serviceName, style: AppTheme.sans(13, color: AppColors.mid)),
            const SizedBox(height: 8),
            Text(formatNaira(b.totalAmount), style: AppTheme.sans(16, color: AppColors.matcha, weight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/provider-inbox/${b.id}');
                    },
                    child: const Text('Message'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await khadeApi.updateBookingStatus(b.id, 'completed');
                      Navigator.pop(ctx);
                      _load();
                    },
                    child: const Text('Complete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(backgroundColor: AppColors.cream, body: LoadingPlaceholder());
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: Text('Calendar', style: AppTheme.serif(22)),
        backgroundColor: AppColors.ivory,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.matcha,
          unselectedLabelColor: AppColors.soft,
          indicatorColor: AppColors.matcha,
          tabs: const [Tab(text: 'Day'), Tab(text: 'Week'), Tab(text: 'Month')],
        ),
        actions: [
          IconButton(
            tooltip: 'Working hours',
            icon: Icon(_showHours ? Icons.event : Icons.schedule_outlined, color: AppColors.matcha),
            onPressed: () => setState(() => _showHours = !_showHours),
          ),
          if (_saving) const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _selected = DateTime.now()),
        backgroundColor: AppColors.matcha,
        icon: const Icon(Icons.today, color: Colors.white),
        label: Text('Today', style: AppTheme.sans(12, color: Colors.white, weight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          _weekStrip(),
          if (_showHours) _hoursPanel(),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _dayTimeline(_selected),
                _weekList(),
                _monthGrid(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekStrip() {
    final start = _selected.subtract(Duration(days: _selected.weekday - 1));
    return Container(
      color: AppColors.ivory,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _selected = _selected.subtract(const Duration(days: 7)))),
          Expanded(
            child: Row(
              children: List.generate(7, (i) {
                final d = start.add(Duration(days: i));
                final active = _dateStr(d) == _dateStr(_selected);
                final count = _on(d).length;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selected = d),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? AppColors.matcha : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: active ? AppColors.matcha : AppColors.borderLight),
                      ),
                      child: Column(
                        children: [
                          Text(_weekdays[i], style: AppTheme.sans(9, color: active ? Colors.white70 : AppColors.soft)),
                          Text('${d.day}', style: AppTheme.sans(15, color: active ? Colors.white : AppColors.dark, weight: FontWeight.w600)),
                          if (count > 0) Container(margin: const EdgeInsets.only(top: 4), width: 5, height: 5, decoration: BoxDecoration(color: active ? AppColors.gold : AppColors.matcha, shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _selected = _selected.add(const Duration(days: 7)))),
        ],
      ),
    );
  }

  Widget _hoursPanel() {
    final dk = _dayKeys[_hoursDay];
    final slots = List<String>.from((_availability[dk] as List?)?.cast<String>() ?? []);
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('OPEN HOURS', style: AppTheme.labelCaps('')),
              const Spacer(),
              TextButton(
                onPressed: () {
                  final mon = List<String>.from((_availability['mon'] as List?)?.cast<String>() ?? []);
                  _save({for (final d in ['mon', 'tue', 'wed', 'thu', 'fri']) d: mon});
                },
                child: Text('Copy Mon→Fri', style: AppTheme.sans(10, color: AppColors.matcha)),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (i) {
                final active = _hoursDay == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(_weekdays[i]),
                    selected: active,
                    onSelected: (_) => setState(() => _hoursDay = i),
                    selectedColor: AppColors.matcha,
                    labelStyle: AppTheme.sans(11, color: active ? Colors.white : AppColors.mid),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _allSlots.map((s) {
              final on = slots.contains(s);
              return FilterChip(
                label: Text(s, style: AppTheme.sans(10)),
                selected: on,
                onSelected: (_) {
                  if (on) {
                    slots.remove(s);
                  } else {
                    slots.add(s);
                    slots.sort();
                  }
                  _save({dk: slots});
                },
                selectedColor: AppColors.matchaPale,
                checkmarkColor: AppColors.matcha,
              );
            }).toList(),
          ),
          TextButton(
            onPressed: () {
              final blocked = List<String>.from((_availability['blocked_dates'] as List?)?.cast<String>() ?? []);
              final key = _dateStr(_selected);
              if (blocked.contains(key)) {
                blocked.remove(key);
              } else {
                blocked.add(key);
              }
              _save({'blocked_dates': blocked});
            },
            child: Text(_blocked(_selected) ? 'Unblock ${_dateStr(_selected)}' : 'Block ${_dateStr(_selected)}', style: AppTheme.sans(11, color: _blocked(_selected) ? AppColors.matcha : AppColors.red)),
          ),
        ],
      ),
    );
  }

  Widget _dayTimeline(DateTime d) {
    final appts = _on(d);
    if (_blocked(d)) {
      return Center(child: Text('Day blocked — no bookings', style: AppTheme.sans(14, color: AppColors.soft)));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        Text(_dateStr(d), style: AppTheme.sans(12, color: AppColors.soft)),
        const SizedBox(height: 8),
        for (final hour in _allSlots)
          _hourRow(hour, appts.where((b) => _hourOf(b.scheduledAt) == hour).toList()),
        if (appts.isEmpty)
          Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('No appointments', style: AppTheme.sans(13, color: AppColors.soft)))),
      ],
    );
  }

  String _hourOf(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '09:00';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _hourRow(String hour, List<BookingModel> items) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Text(hour, style: AppTheme.sans(11, color: AppColors.soft)),
          ),
          Container(width: 2, color: AppColors.borderLight),
          const SizedBox(width: 10),
          Expanded(
            child: items.isEmpty
                ? const SizedBox(height: 28)
                : Column(
                    children: items.map((b) => _apptCard(b)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _apptCard(BookingModel b) {
    return GestureDetector(
      onTap: () => _openBooking(b),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.matchaPale,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.matcha.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(width: 4, height: 36, decoration: BoxDecoration(color: AppColors.matcha, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.customerName ?? b.serviceName, style: AppTheme.sans(13, weight: FontWeight.w600)),
                  Text(b.serviceName, style: AppTheme.sans(11, color: AppColors.mid)),
                ],
              ),
            ),
            Text(formatNaira(b.totalAmount), style: AppTheme.sans(12, color: AppColors.matchaDeep, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _weekList() {
    final start = _selected.subtract(Duration(days: _selected.weekday - 1));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: 7,
      itemBuilder: (_, i) {
        final d = start.add(Duration(days: i));
        final appts = _on(d);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Text('${_weekdays[i]} ${d.day}', style: AppTheme.sans(12, weight: FontWeight.w600, color: AppColors.matchaDeep)),
            ),
            if (appts.isEmpty)
              Text('Free', style: AppTheme.sans(11, color: AppColors.soft))
            else
              for (final b in appts) _apptCard(b),
          ],
        );
      },
    );
  }

  Widget _monthGrid() {
    final first = DateTime(_selected.year, _selected.month, 1);
    final days = DateTime(_selected.year, _selected.month + 1, 0).day;
    final pad = first.weekday - 1;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 6, crossAxisSpacing: 6),
      itemCount: pad + days,
      itemBuilder: (_, i) {
        if (i < pad) return const SizedBox.shrink();
        final day = i - pad + 1;
        final d = DateTime(_selected.year, _selected.month, day);
        final active = _dateStr(d) == _dateStr(_selected);
        final n = _on(d).length;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selected = d;
              _tabs.animateTo(0);
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: active ? AppColors.matcha : (_blocked(d) ? AppColors.redBg : AppColors.surface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: active ? AppColors.matcha : AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$day', style: AppTheme.sans(12, color: active ? Colors.white : AppColors.dark)),
                if (n > 0) Text('$n', style: AppTheme.sans(9, color: active ? AppColors.goldLight : AppColors.matcha)),
              ],
            ),
          ),
        );
      },
    );
  }
}
