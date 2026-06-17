import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/travel_fee.dart';
import '../widgets/api_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/khade_image.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    this.providerId = 1,
    this.serviceId,
    this.quantity = 1,
    this.bookingType = 'solo',
  });

  final int providerId;
  final int? serviceId;
  final int quantity;
  final String bookingType;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedService = 0;
  bool _atHome = true;
  bool get _atHomeEffective {
    final p = KhadeRepository.instance.providerById(widget.providerId);
    if (p == null) return _atHome;
    if (p.providerType == 'mobile') return true;
    if (p.providerType == 'salon') return false;
    return _atHome;
  }
  int _selectedDate = 1;
  int _selectedTime = 2;
  final _noteController = TextEditingController();

  int get _guestCount => widget.quantity.clamp(1, 50);
  bool get _isGroup => widget.bookingType == 'group';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  final _dates = [('Mon', '16'), ('Tue', '17'), ('Wed', '18'), ('Thu', '19'), ('Fri', '20'), ('Sat', '21')];
  final _times = ['8:00 AM', '9:00 AM', '10:30 AM', '12:00 PM', '1:30 PM', '3:00 PM', '4:30 PM', '6:00 PM', '7:30 PM'];
  final _unavailable = {0, 4, 7};

  String get _scheduledAt {
    const base = '2025-06-17';
    const hours = [8, 9, 10, 12, 13, 15, 16, 18, 19];
    const mins = [0, 0, 30, 0, 30, 0, 30, 0, 30];
    final h = hours[_selectedTime];
    final m = mins[_selectedTime];
    return '$base T${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:00';
  }

  int _travelFee(ProviderModel provider) {
    if (!_atHomeEffective || !provider.isMobileProvider) return 0;
    final repo = KhadeRepository.instance;
    final fee = calculateTravelFee(
      provider: provider,
      customerLat: repo.userLat,
      customerLng: repo.userLng,
    );
    return fee < 0 ? 0 : fee;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: KhadeRepository.instance,
      builder: (context, _) {
        final provider = KhadeRepository.instance.providerById(widget.providerId);
        if (provider == null) {
          return Scaffold(backgroundColor: AppColors.cream, body: const Center(child: Text('Provider not found')));
        }

        final services = provider.services.isNotEmpty
            ? provider.services
            : [const ServiceModel(id: 1, name: 'Full Glam Makeup', duration: '90 mins', price: 12000)];

        if (widget.serviceId != null) {
          final idx = services.indexWhere((s) => s.id == widget.serviceId);
          if (idx >= 0) _selectedService = idx;
        }
        if (_selectedService >= services.length) _selectedService = 0;
        final service = services[_selectedService];

        final subtotal = service.price * _guestCount;
        final travel = _travelFee(provider);
        final serviceFee = ((subtotal + travel) * 0.1).round();
        final grandTotal = subtotal + travel + serviceFee;

        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: const BoxDecoration(color: AppColors.white, border: Border(bottom: BorderSide(color: AppColors.border))),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextButton.icon(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back, size: 18), label: const Text('Back'), style: TextButton.styleFrom(foregroundColor: AppColors.matcha, padding: EdgeInsets.zero)),
                      Text(provider.name, style: AppTheme.serif(26)),
                      Row(
                        children: [
                          ...List.generate(5, (_) => const Icon(Icons.star, size: 12, color: AppColors.gold)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('${provider.rating.toStringAsFixed(1)} · ${provider.reviewCount} reviews · ${provider.area}, Abuja', style: AppTheme.sans(11, color: AppColors.soft)),
                          ),
                          IconButton(
                            icon: Icon(
                              KhadeRepository.instance.isProviderSaved(provider.id) ? Icons.favorite : Icons.favorite_border,
                              color: AppColors.red,
                            ),
                            onPressed: () => KhadeRepository.instance.toggleSaveProvider(provider.id),
                          ),
                        ],
                      ),
                      if (_isGroup)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Group booking · $_guestCount guests', style: AppTheme.sans(11, color: AppColors.matcha, weight: FontWeight.w600)),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 160,
                width: double.infinity,
                child: KhadeImage(
                  url: provider.imageUrl,
                  fallbackUrl: provider.imageUrl,
                  gradient: [colorFromHex(provider.gradientStart), colorFromHex(provider.gradientEnd)],
                  emojiSize: 56,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    if (widget.serviceId == null) _section('Choose Service', _serviceOptions(services)),
                    _section('Where?', _locationToggle(provider)),
                    _section('Pick a Date', _dateTimePicker()),
                    _section('Add a Note (optional)', TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any special requests for your provider?',
                        hintStyle: AppTheme.sans(12, color: const Color(0xFFBBBBBB)),
                        filled: true,
                        fillColor: AppColors.cream,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      _priceLine(service.name, subtotal),
                      if (travel > 0) _priceLine('Travel fee', travel),
                      _priceLine('Service fee (10%)', serviceFee),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: AppTheme.sans(13, weight: FontWeight.w600)),
                          Text(formatNaira(grandTotal), style: AppTheme.serif(22, color: AppColors.matchaDeep)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Proceed to Payment →',
                        onPressed: () {
                          final noteParts = <String>[];
                          if (_isGroup) noteParts.add('Group booking · $_guestCount guests');
                          final userNote = _noteController.text.trim();
                          if (userNote.isNotEmpty) noteParts.add(userNote);
                          final fullNote = noteParts.join('\n');
                          context.push(
                            '/payment?providerId=${provider.id}&serviceId=${service.id}&scheduledAt=$_scheduledAt&locationType=${_atHomeEffective ? 'home' : 'salon'}&serviceName=${Uri.encodeComponent(service.name)}&providerName=${Uri.encodeComponent(provider.name)}&price=$subtotal&travelFee=$travel&serviceFee=$serviceFee&total=$grandTotal&appointmentType=${widget.bookingType}&guestCount=$_guestCount&note=${Uri.encodeComponent(fullNote)}',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _priceLine(String label, int amount) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTheme.sans(12, color: AppColors.soft)),
            Text(formatNaira(amount), style: AppTheme.sans(12, color: AppColors.mid)),
          ],
        ),
      );

  Widget _section(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(), style: AppTheme.sans(11, color: AppColors.soft).copyWith(letterSpacing: 1.5)),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _serviceOptions(List<ServiceModel> services) {
    return Column(
      children: [
        for (var i = 0; i < services.length; i++)
          GestureDetector(
            onTap: () => setState(() => _selectedService = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: i < services.length - 1 ? AppColors.border : Colors.transparent))),
              child: Row(
                children: [
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _selectedService == i ? AppColors.matcha : AppColors.border, width: 2)),
                    child: _selectedService == i ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.matcha))) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(services[i].name, style: AppTheme.sans(13)), Text(services[i].duration, style: AppTheme.sans(11, color: AppColors.soft))])),
                  Text(formatNaira(services[i].price), style: AppTheme.sans(13, color: AppColors.matcha, weight: FontWeight.w500)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _locationToggle(ProviderModel provider) {
    final mobileOnly = provider.providerType == 'mobile';
    final salonOnly = provider.providerType == 'salon';
    final atHome = _atHomeEffective;

    return Column(
      children: [
        if (!mobileOnly && !salonOnly)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              _locBtn('🏠 My Location', atHome, () => setState(() => _atHome = true)),
              _locBtn('🏪 Their Salon', !atHome, () => setState(() => _atHome = false)),
            ]),
          ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  atHome
                      ? '📍 ${KhadeRepository.instance.userAddress}'
                      : '📍 ${provider.area}, Abuja · ${provider.distanceLabel} · ${provider.etaLabel}',
                  style: AppTheme.sans(12, color: AppColors.mid),
                ),
              ),
              if (atHome && provider.isMobileProvider)
                TextButton(
                  onPressed: () => context.push('/location-picker'),
                  child: Text('Adjust pin', style: AppTheme.sans(11, color: AppColors.matcha)),
                ),
            ],
          ),
        ),
        if (atHome && provider.isMobileProvider)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(provider.travelInfo, style: AppTheme.sans(11, color: AppColors.soft)),
          ),
      ],
    );
  }

  Widget _locBtn(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: active ? AppColors.matcha : Colors.transparent, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(label, style: AppTheme.sans(12, color: active ? AppColors.white : AppColors.soft)),
        ),
      ),
    );
  }

  Widget _dateTimePicker() {
    return Column(
      children: [
        SizedBox(
          height: 70,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = _selectedDate == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedDate = i),
                child: Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(color: sel ? AppColors.matcha : AppColors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? AppColors.matcha : AppColors.border)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_dates[i].$1, style: AppTheme.sans(10, color: sel ? Colors.white70 : AppColors.soft)),
                    Text(_dates[i].$2, style: AppTheme.sans(16, color: sel ? AppColors.white : AppColors.dark, weight: FontWeight.w500)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.2),
          itemCount: _times.length,
          itemBuilder: (_, i) {
            final unavailable = _unavailable.contains(i);
            final sel = _selectedTime == i;
            return GestureDetector(
              onTap: unavailable ? null : () => setState(() => _selectedTime = i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(color: unavailable ? AppColors.cream : sel ? AppColors.matcha : AppColors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: sel ? AppColors.matcha : AppColors.border)),
                child: Text(_times[i], style: AppTheme.sans(12, color: unavailable ? const Color(0xFFCCCCCC) : sel ? AppColors.white : AppColors.mid)),
              ),
            );
          },
        ),
      ],
    );
  }
}
