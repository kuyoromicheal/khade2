import 'models.dart';

/// State carried through Fresha's 5-step booking flow + Khade location step.
class BookingDraft {
  BookingDraft({required this.providerId, this.rebookMode = false});

  final int providerId;
  final bool rebookMode;

  ProviderModel? provider;
  final Set<int> selectedServiceIds = {};
  /// serviceId → staffId (0 = any available)
  final Map<int, int> staffByService = {};
  DateTime? selectedDate;
  String? selectedTimeSlot;
  bool atHome = true;
  String address = '';
  String note = '';
  int travelFee = 0;

  int get subtotal {
    final services = provider?.services ?? [];
    return services.where((s) => selectedServiceIds.contains(s.id)).fold<int>(0, (sum, s) => sum + s.price);
  }

  int get serviceFee => (subtotal * 0.1).round();
  int get total => subtotal + serviceFee + (atHome ? travelFee : 0);

  List<ServiceModel> get selectedServices =>
      (provider?.services ?? []).where((s) => selectedServiceIds.contains(s.id)).toList();

  int get totalDurationMins {
    return selectedServices.fold<int>(0, (sum, s) {
      final m = RegExp(r'(\d+)').firstMatch(s.duration);
      return sum + (int.tryParse(m?.group(1) ?? '60') ?? 60);
    });
  }

  String get scheduledAtIso {
    if (selectedDate == null || selectedTimeSlot == null) return '';
    final parts = selectedTimeSlot!.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final dt = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, h, m);
    return dt.toIso8601String().split('.').first;
  }

  void preselectRebook({required int serviceId, String? timeSlot}) {
    selectedServiceIds.add(serviceId);
    staffByService[serviceId] = 0;
    selectedTimeSlot = timeSlot;
    selectedDate = DateTime.now().add(const Duration(days: 7));
  }
}

class StaffMember {
  const StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    required this.bio,
    this.avatarEmoji = '💄',
  });

  final int id;
  final String name;
  final String role;
  final double rating;
  final String bio;
  final String avatarEmoji;

  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
        id: j['id'] as int,
        name: j['name'] as String,
        role: j['role'] as String? ?? 'Specialist',
        rating: (j['rating'] as num?)?.toDouble() ?? 4.8,
        bio: j['bio'] as String? ?? '',
        avatarEmoji: j['avatarEmoji'] as String? ?? '💄',
      );

  static StaffMember anyAvailable() => const StaffMember(
        id: 0,
        name: 'Any available',
        role: 'Best match assigned',
        rating: 4.9,
        bio: 'We\'ll assign the next available specialist for your service.',
        avatarEmoji: '✦',
      );
}
