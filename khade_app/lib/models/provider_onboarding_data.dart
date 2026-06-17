class ProviderOnboardingData {
  const ProviderOnboardingData({
    this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.brandName,
    this.website,
    this.primaryCategory,
    this.additionalCategories = const [],
    this.crewSize,
    this.providerSubtype = 'solo_pro',
    this.workStyles = const [],
    this.travelRadius = 10,
    this.travelFeeType = 'free',
    this.travelFeeNote,
    this.latitude = 9.0765,
    this.longitude = 7.3986,
    this.address,
    this.area,
    this.additionalAreas = const [],
    this.skippedGoogle = false,
  });

  final int? userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? brandName;
  final String? website;
  final String? primaryCategory;
  final List<String> additionalCategories;
  final String? crewSize;
  final String providerSubtype;
  final List<String> workStyles;
  final int travelRadius;
  final String travelFeeType;
  final String? travelFeeNote;
  final double latitude;
  final double longitude;
  final String? address;
  final String? area;
  final List<String> additionalAreas;
  final bool skippedGoogle;

  String get displayFirstName => firstName ?? 'Pro';

  bool get isVirtualOnly =>
      workStyles.isNotEmpty &&
      !workStyles.contains('in_studio') &&
      !workStyles.contains('mobile');

  ProviderOnboardingData copyWith({
    int? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? brandName,
    String? website,
    String? primaryCategory,
    List<String>? additionalCategories,
    String? crewSize,
    String? providerSubtype,
    List<String>? workStyles,
    int? travelRadius,
    String? travelFeeType,
    String? travelFeeNote,
    double? latitude,
    double? longitude,
    String? address,
    String? area,
    List<String>? additionalAreas,
    bool? skippedGoogle,
  }) {
    return ProviderOnboardingData(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      brandName: brandName ?? this.brandName,
      website: website ?? this.website,
      primaryCategory: primaryCategory ?? this.primaryCategory,
      additionalCategories: additionalCategories ?? this.additionalCategories,
      crewSize: crewSize ?? this.crewSize,
      providerSubtype: providerSubtype ?? this.providerSubtype,
      workStyles: workStyles ?? this.workStyles,
      travelRadius: travelRadius ?? this.travelRadius,
      travelFeeType: travelFeeType ?? this.travelFeeType,
      travelFeeNote: travelFeeNote ?? this.travelFeeNote,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      area: area ?? this.area,
      additionalAreas: additionalAreas ?? this.additionalAreas,
      skippedGoogle: skippedGoogle ?? this.skippedGoogle,
    );
  }
}
