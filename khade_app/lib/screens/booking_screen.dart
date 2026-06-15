import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/models.dart';
import '../services/khade_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/api_widgets.dart';
import '../widgets/common_widgets.dart';
import '../widgets/khade_image.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, this.providerId = 1});
  final int providerId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _selectedService = 0;
  bool _atHome = true;
  int _selectedDate = 1;
  int _selectedTime = 2;

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

        if (_selectedService >= services.length) _selectedService = 0;
        final service = services[_selectedService];

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
                      TextButton(
                        onPressed: () => context.push('/review?providerId=${provider.id}&providerName=${Uri.encodeComponent(provider.name)}'),
                        child: Text('See reviews & leave yours →', style: AppTheme.sans(11, color: AppColors.matcha)),
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
                    _section('Customer Reviews', _reviewsSection(provider)),
                    _section('Choose Service', _serviceOptions(services)),
                    _section('Where?', _locationToggle()),
                    _section('Pick a Date', _dateTimePicker()),
                    _section('Add a Note (optional)', Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.cream, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(10)),
                      child: Text('Any special requests for your provider?', style: AppTheme.sans(12, color: const Color(0xFFBBBBBB))),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total · ${service.name}', style: AppTheme.sans(12, color: AppColors.soft)),
                          Text(formatNaira(service.price), style: AppTheme.serif(20)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Proceed to Payment →',
                        onPressed: () => context.push(
                          '/payment?providerId=${provider.id}&serviceId=${service.id}&scheduledAt=$_scheduledAt&locationType=${_atHome ? 'home' : 'salon'}&serviceName=${Uri.encodeComponent(service.name)}&providerName=${Uri.encodeComponent(provider.name)}&price=${service.price}',
                        ),
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

  Widget _reviewsSection(ProviderModel provider) {
    final reviews = KhadeRepository.instance.reviewsForProvider(provider.id);
    if (reviews.isEmpty) {
      return Text('No reviews yet — be the first to share your experience!', style: AppTheme.sans(12, color: AppColors.soft));
    }
    return Column(
      children: [
        for (final r in reviews.take(5))
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ...List.generate(r.rating, (_) => const Icon(Icons.star, size: 12, color: AppColors.gold)),
                    const Spacer(),
                    Text(r.authorName, style: AppTheme.sans(10, color: AppColors.soft)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(r.comment, style: AppTheme.sans(12, color: AppColors.mid)),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => context.push('/review?providerId=${provider.id}&providerName=${Uri.encodeComponent(provider.name)}'),
            child: Text(reviews.length > 5 ? 'See all ${reviews.length} reviews →' : 'Leave your review →', style: AppTheme.sans(11, color: AppColors.matcha)),
          ),
        ),
      ],
    );
  }

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

  Widget _locationToggle() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
          child: Row(children: [
            _locBtn('🏠 My Location', _atHome, () => setState(() => _atHome = true)),
            _locBtn('🏪 Their Salon', !_atHome, () => setState(() => _atHome = false)),
          ]),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: Text('📍 Plot 5, Abubakar Tafawa Balewa Way, Maitama, Abuja', style: AppTheme.sans(12, color: AppColors.mid)),
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
