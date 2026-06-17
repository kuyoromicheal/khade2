import 'package:flutter/foundation.dart';
import '../models/provider_onboarding_data.dart';
import 'auth_service.dart';
import 'khade_api.dart';
import 'khade_repository.dart';

class ProviderOnboardingController extends ChangeNotifier {
  ProviderOnboardingController._();
  static final ProviderOnboardingController instance = ProviderOnboardingController._();

  ProviderOnboardingData data = const ProviderOnboardingData();
  bool submitting = false;
  String? lastError;

  void update(ProviderOnboardingData Function(ProviderOnboardingData) fn) {
    data = fn(data);
    notifyListeners();
  }

  void reset() {
    data = const ProviderOnboardingData();
    lastError = null;
    notifyListeners();
  }

  String _visitTypes() {
    final w = data.workStyles;
    final hasStudio = w.contains('in_studio');
    final hasMobile = w.contains('mobile');
    if (hasStudio && hasMobile) return 'both';
    if (hasStudio) return 'salon';
    return 'home';
  }

  String _providerType() {
    if (data.workStyles.contains('in_studio') && !data.workStyles.contains('mobile')) return 'salon';
    if (data.workStyles.contains('mobile') && !data.workStyles.contains('in_studio')) return 'mobile';
    if (data.workStyles.contains('in_studio')) return 'both';
    return 'mobile';
  }

  String _subtypeFromCrew() {
    return switch (data.crewSize) {
      'solo' => 'solo_pro',
      'full' => 'salon',
      _ => 'studio',
    };
  }

  Future<bool> submitProfile() async {
    submitting = true;
    lastError = null;
    notifyListeners();
    try {
      final category = data.primaryCategory ?? 'makeup';
      final defaultServices = _defaultServices(category);
      await khadeApi.onboardProvider(
        categorySlug: category,
        services: defaultServices,
        visitTypes: _visitTypes(),
        providerType: _providerType(),
        providerSubtype: data.providerSubtype.isNotEmpty ? data.providerSubtype : _subtypeFromCrew(),
        brandName: data.brandName,
        website: data.website,
        additionalCategories: data.additionalCategories,
        crewSize: data.crewSize,
        workStyles: data.workStyles,
        workLocations: _workLocations(),
        coverageAreas: [if (data.area != null) data.area!, ...data.additionalAreas],
        travelRadiusKm: data.travelRadius,
        travelFeeNote: data.travelFeeType == 'paid' ? data.travelFeeNote : null,
        area: data.area ?? 'Wuse II',
        address: data.address,
        latitude: data.latitude,
        longitude: data.longitude,
        bio: data.brandName != null ? 'Welcome to ${data.brandName} on Khade' : null,
      );
      await KhadeRepository.instance.syncAfterAuth(AuthService.instance.authUser!);
      submitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString();
      submitting = false;
      notifyListeners();
      return false;
    }
  }

  List<String> _workLocations() {
    final locs = <String>[];
    if (data.workStyles.contains('mobile')) {
      locs.addAll(['client_home', 'events']);
    }
    if (data.workStyles.contains('in_studio')) {
      locs.add('rented_studio');
    }
    if (data.crewSize == 'solo') {
      locs.add('own_home');
    }
    return locs.toSet().toList();
  }

  List<Map<String, dynamic>> _defaultServices(String slug) {
    const map = {
      'makeup': {'name': 'Soft Glam', 'duration': '60 mins', 'price': 8000},
      'nails': {'name': 'Gel Manicure', 'duration': '60 mins', 'price': 8500},
      'barbing': {'name': 'Classic Cut', 'duration': '30 mins', 'price': 4000},
      'hair': {'name': 'Wash & Blow', 'duration': '45 mins', 'price': 5000},
      'spa': {'name': 'Swedish Massage', 'duration': '60 mins', 'price': 15000},
      'braids': {'name': 'Box Braids', 'duration': '180 mins', 'price': 12000},
      'skincare': {'name': 'Express Facial', 'duration': '45 mins', 'price': 10000},
      'lashes': {'name': 'Classic Lash Set', 'duration': '90 mins', 'price': 12000},
      'facials': {'name': 'Basic Facial', 'duration': '45 mins', 'price': 12000},
      'dental': {'name': 'Consultation', 'duration': '30 mins', 'price': 5000},
      'pedicure': {'name': 'Classic Pedicure', 'duration': '45 mins', 'price': 8000},
      'massage': {'name': 'Relaxation Massage', 'duration': '60 mins', 'price': 15000},
    };
    return [map[slug] ?? map['makeup']!];
  }
}
