import '../utils/media_url.dart';
import '../utils/geo_utils.dart';

class ProviderModel {
  const ProviderModel({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.area,
    required this.priceFrom,
    this.badge,
    this.verified = false,
    this.featured = false,
    this.gradientStart = '#e8f0ea',
    this.gradientEnd = '#d4e6d8',
    this.imageUrl,
    this.avatarUrl,
    this.latitude,
    this.longitude,
    this.phone,
    this.services = const [],
    this.bio = '',
    this.photos = const [],
    this.openingHours,
    this.instantConfirm = true,
    this.doesHomeVisits = true,
    this.hasSalon = false,
    this.acceptsGroups = true,
    this.isCertified = false,
    this.hasTeam = false,
    this.locationArea,
    this.team = const [],
    this.branches = const [],
    this.providerType = 'mobile',
    this.travelRadiusKm = 10,
    this.travelFeePerKm = 0,
    this.minTravelFee = 0,
    this.baseArea,
    this.providerSubtype = 'solo_pro',
    this.workLocations = const [],
    this.coverageAreas = const [],
  });

  final int id;
  final String name;
  final String category;
  final String emoji;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String area;
  final int priceFrom;
  final String? badge;
  final bool verified;
  final bool featured;
  final String gradientStart;
  final String gradientEnd;
  final String? imageUrl;
  final String? avatarUrl;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final List<ServiceModel> services;
  final String bio;
  final List<String> photos;
  final Map<String, dynamic>? openingHours;
  final bool instantConfirm;
  final bool doesHomeVisits;
  final bool hasSalon;
  final bool acceptsGroups;
  final bool isCertified;
  final bool hasTeam;
  final String? locationArea;
  final List<ProviderTeamMember> team;
  final List<ProviderBranch> branches;
  final String providerType; // salon | mobile | both
  final int travelRadiusKm;
  final double travelFeePerKm;
  final int minTravelFee;
  final String? baseArea;
  final String providerSubtype;
  final List<String> workLocations;
  final List<String> coverageAreas;

  bool get isSoloPro => providerSubtype == 'solo_pro';

  String get subtypeBadge => switch (providerSubtype) {
        'salon' || 'studio' => '🏪 Salon',
        'mobile' => '🚗 Comes to You',
        'solo_pro' => '⚡ Solo Pro',
        _ => providerType == 'salon' ? '🏪 Salon' : '🚗 Mobile',
      };

  String get coverageLabel => coverageAreas.isNotEmpty ? coverageAreas.take(3).join(', ') : area;

  String get workLocationsLabel {
    const labels = {
      'client_home': 'client home',
      'own_home': 'own home',
      'rented_studio': 'rented studio',
      'hotel': 'hotels',
      'events': 'events',
    };
    if (workLocations.isEmpty) return isSoloPro ? 'flexible locations' : '';
    return workLocations.map((w) => labels[w] ?? w).join(', ');
  }

  bool get isMobileProvider => providerType == 'mobile' || providerType == 'both' || isSoloPro;
  bool get isSalonProvider => providerType == 'salon' || providerType == 'both';

  String get locationBadge => isMobileProvider && !isSalonProvider
      ? '🚗 Comes to you'
      : isMobileProvider
          ? '🚗 Mobile · ${baseArea ?? area}'
          : '📍 ${area}';

  String get travelInfo {
    if (!isMobileProvider) return '';
    final base = baseArea ?? area;
    final fee = travelFeePerKm > 0
        ? '₦${travelFeePerKm.toStringAsFixed(0)}/km (min ₦$minTravelFee)'
        : 'Free travel';
    return 'Travels up to ${travelRadiusKm}km from $base · $fee';
  }

  factory ProviderModel.fromJson(Map<String, dynamic> j) {
    final photosRaw = j['photos'];
    List<String> photos = const [];
    if (photosRaw is List) {
      photos = photosRaw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (photos.isEmpty && j['imageUrl'] != null) photos = [j['imageUrl'] as String];

    return ProviderModel(
        id: j['id'] as int,
        name: j['name'] as String,
        category: j['category'] as String,
        emoji: j['emoji'] as String,
        rating: (j['rating'] as num).toDouble(),
        reviewCount: j['reviewCount'] as int,
        distanceKm: (j['distanceKm'] as num).toDouble(),
        area: j['area'] as String,
        priceFrom: j['priceFrom'] as int,
        badge: j['badge'] as String?,
        verified: j['verified'] as bool? ?? false,
        featured: j['featured'] as bool? ?? false,
        gradientStart: j['gradientStart'] as String? ?? '#e8f0ea',
        gradientEnd: j['gradientEnd'] as String? ?? '#d4e6d8',
        imageUrl: j['imageUrl'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        latitude: (j['latitude'] as num?)?.toDouble(),
        longitude: (j['longitude'] as num?)?.toDouble(),
        phone: j['phone'] as String?,
        services: (j['services'] as List<dynamic>?)
                ?.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        bio: j['bio'] as String? ?? '',
        photos: photos,
        openingHours: j['openingHours'] as Map<String, dynamic>?,
        instantConfirm: j['instantConfirm'] as bool? ?? true,
        doesHomeVisits: j['doesHomeVisits'] as bool? ?? true,
        hasSalon: j['hasSalon'] as bool? ?? false,
        acceptsGroups: j['acceptsGroups'] as bool? ?? true,
        isCertified: j['isCertified'] as bool? ?? false,
        hasTeam: j['hasTeam'] as bool? ?? false,
        locationArea: j['locationArea'] as String?,
        team: (j['team'] as List<dynamic>?)
                ?.map((e) => ProviderTeamMember.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        branches: (j['branches'] as List<dynamic>?)
                ?.map((e) => ProviderBranch.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        providerType: j['providerType'] as String? ?? 'mobile',
        travelRadiusKm: (j['travelRadiusKm'] as num?)?.toInt() ?? 10,
        travelFeePerKm: (j['travelFeePerKm'] as num?)?.toDouble() ?? 0,
        minTravelFee: (j['minTravelFee'] as num?)?.toInt() ?? 0,
        baseArea: j['baseArea'] as String?,
        providerSubtype: j['providerSubtype'] as String? ?? 'solo_pro',
        workLocations: (j['workLocations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        coverageAreas: (j['coverageAreas'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      );
  }

  String get priceLabel => 'From ₦${_formatNaira(priceFrom)}';
  String get distanceLabel => '${distanceKm}km';
  String get etaLabel => '${etaFromDistanceKm(distanceKm)} min';

  static String _formatNaira(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class ServiceModel {
  const ServiceModel({required this.id, required this.name, required this.duration, required this.price});

  final int id;
  final String name;
  final String duration;
  final int price;

  factory ServiceModel.fromJson(Map<String, dynamic> j) => ServiceModel(
        id: j['id'] as int,
        name: j['name'] as String,
        duration: j['duration'] as String,
        price: j['price'] as int,
      );
}

class ProviderTeamMember {
  const ProviderTeamMember({required this.id, required this.name, required this.role, this.rating = 5, this.avatarUrl});

  final int id;
  final String name;
  final String role;
  final double rating;
  final String? avatarUrl;

  factory ProviderTeamMember.fromJson(Map<String, dynamic> j) => ProviderTeamMember(
        id: j['id'] as int,
        name: j['name'] as String,
        role: j['role'] as String? ?? 'Specialist',
        rating: (j['rating'] as num?)?.toDouble() ?? 5,
        avatarUrl: j['avatarUrl'] as String?,
      );
}

class ProviderBranch {
  const ProviderBranch({required this.id, required this.branchName, required this.address, this.lat, this.lng, this.isPrimary = false});

  final int id;
  final String branchName;
  final String address;
  final double? lat;
  final double? lng;
  final bool isPrimary;

  factory ProviderBranch.fromJson(Map<String, dynamic> j) => ProviderBranch(
        id: j['id'] as int,
        branchName: j['branchName'] as String? ?? 'Branch',
        address: j['address'] as String? ?? '',
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        isPrimary: j['isPrimary'] as bool? ?? false,
      );
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.bookingCode,
    required this.status,
    required this.locationType,
    required this.scheduledAt,
    required this.totalAmount,
    required this.providerId,
    required this.providerName,
    required this.providerEmoji,
    required this.serviceName,
    this.address,
    this.userId,
    this.customerName,
    this.customerPhone,
  });

  final int id;
  final String bookingCode;
  final String status;
  final String locationType;
  final String? address;
  final String scheduledAt;
  final int totalAmount;
  final int providerId;
  final String providerName;
  final String providerEmoji;
  final String serviceName;
  final int? userId;
  final String? customerName;
  final String? customerPhone;

  factory BookingModel.fromJson(Map<String, dynamic> j) {
    final provider = j['provider'] as Map<String, dynamic>?;
    final customer = j['customer'] as Map<String, dynamic>?;
    final service = j['service'] as Map<String, dynamic>?;
    return BookingModel(
      id: j['id'] as int,
      bookingCode: j['bookingCode'] as String,
      status: j['status'] as String,
      locationType: j['locationType'] as String,
      address: j['address'] as String?,
      scheduledAt: j['scheduledAt'] as String,
      totalAmount: j['totalAmount'] as int,
      providerId: provider?['id'] as int? ?? j['providerId'] as int? ?? 0,
      providerName: provider?['name'] as String? ?? j['providerName'] as String? ?? 'Provider',
      providerEmoji: provider?['emoji'] as String? ?? '💄',
      serviceName: service?['name'] as String? ?? j['serviceName'] as String? ?? 'Service',
      userId: customer?['id'] as int? ?? j['userId'] as int?,
      customerName: customer?['name'] as String? ?? j['customerName'] as String?,
      customerPhone: customer?['phone'] as String? ?? j['customerPhone'] as String?,
    );
  }
}

class FeedPostModel {
  const FeedPostModel({
    required this.id,
    required this.imageEmoji,
    required this.badge,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.providerName,
    required this.providerEmoji,
    required this.category,
    required this.rating,
    required this.area,
    required this.providerId,
    this.imageUrl,
    this.videoUrl,
    this.mediaType = 'image',
    this.providerAvatarUrl,
    this.providerImageUrl,
  });

  final int id;
  final String imageEmoji;
  final String? badge;
  final String caption;
  final int likes;
  final int comments;
  final String providerName;
  final String providerEmoji;
  final String category;
  final double rating;
  final String area;
  final int providerId;
  final String? imageUrl;
  final String? videoUrl;
  final String mediaType;
  final String? providerAvatarUrl;
  final String? providerImageUrl;

  bool get isVideo => mediaType == 'video' && videoUrl != null && videoUrl!.isNotEmpty;

  factory FeedPostModel.fromJson(Map<String, dynamic> j) {
    final p = j['provider'] as Map<String, dynamic>;
    return FeedPostModel(
      id: j['id'] as int,
      imageEmoji: j['imageEmoji'] as String,
      imageUrl: j['imageUrl'] as String?,
      videoUrl: resolveMediaUrl(j['videoUrl'] as String?),
      mediaType: j['mediaType'] as String? ?? 'image',
      badge: j['badge'] as String?,
      caption: j['caption'] as String,
      likes: j['likes'] as int,
      comments: j['comments'] as int,
      providerName: p['name'] as String,
      providerEmoji: p['emoji'] as String,
      category: p['category'] as String,
      rating: (p['rating'] as num).toDouble(),
      area: p['area'] as String,
      providerId: p['id'] as int,
      providerAvatarUrl: p['avatarUrl'] as String?,
      providerImageUrl: p['imageUrl'] as String?,
    );
  }
}

class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.slug,
    required this.label,
    required this.emoji,
    this.filter,
    this.imageUrl,
    this.iconName,
  });

  final int id;
  final String slug;
  final String label;
  final String emoji;
  final String? filter;
  final String? imageUrl;
  final String? iconName;

  factory CategoryModel.fromJson(Map<String, dynamic> j) => CategoryModel(
        id: j['id'] as int,
        slug: j['slug'] as String,
        label: j['label'] as String,
        emoji: j['emoji'] as String,
        filter: j['filter'] as String?,
        imageUrl: j['imageUrl'] as String?,
      );
}

class WalletTransactionModel {
  const WalletTransactionModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.reference,
    required this.createdAt,
  });

  final int id;
  final String type;
  final int amount;
  final String description;
  final String reference;
  final String createdAt;

  factory WalletTransactionModel.fromJson(Map<String, dynamic> j) => WalletTransactionModel(
        id: j['id'] as int,
        type: j['type'] as String,
        amount: j['amount'] as int,
        description: j['description'] as String,
        reference: j['reference'] as String,
        createdAt: j['createdAt'] as String,
      );

  bool get isCredit => type == 'credit' || type == 'cashback' || type == 'refund';
}

class ReviewModel {
  const ReviewModel({
    required this.id,
    required this.providerId,
    required this.rating,
    required this.comment,
    required this.authorName,
    required this.createdAt,
    this.providerName,
  });

  final int id;
  final int providerId;
  final int rating;
  final String comment;
  final String authorName;
  final String createdAt;
  final String? providerName;

  factory ReviewModel.fromJson(Map<String, dynamic> j) => ReviewModel(
        id: j['id'] as int,
        providerId: j['providerId'] as int,
        rating: j['rating'] as int,
        comment: j['comment'] as String,
        authorName: j['authorName'] as String,
        createdAt: j['createdAt'] as String,
        providerName: j['providerName'] as String?,
      );
}

class PaystackInitResult {
  const PaystackInitResult({required this.reference, required this.amount, required this.authorizationUrl});
  final String reference;
  final int amount;
  final String authorizationUrl;

  factory PaystackInitResult.fromJson(Map<String, dynamic> j) => PaystackInitResult(
        reference: j['reference'] as String,
        amount: j['amount'] as int,
        authorizationUrl: j['authorizationUrl'] as String,
      );
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.city,
    required this.tier,
    required this.walletBalance,
    required this.bookingsCount,
    required this.savedProviders,
    required this.memberSince,
    this.email,
    this.role = 'customer',
    this.providerId,
  });

  final int id;
  final String name;
  final String city;
  final String tier;
  final int walletBalance;
  final int bookingsCount;
  final int savedProviders;
  final int memberSince;
  final String? email;
  final String role;
  final int? providerId;

  bool get isProvider => role == 'provider';
  bool get isAdmin => role == 'admin';
  bool get isGuest => role == 'guest';

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as int,
        name: j['name'] as String,
        city: j['city'] as String,
        tier: j['tier'] as String,
        walletBalance: j['walletBalance'] as int,
        bookingsCount: j['bookingsCount'] as int,
        savedProviders: j['savedProviders'] as int,
        memberSince: j['memberSince'] as int,
        email: j['email'] as String?,
        role: j['role'] as String? ?? 'customer',
        providerId: j['providerId'] as int?,
      );
}

class AuthResult {
  const AuthResult({required this.token, required this.user, this.welcomeBonus});
  final String token;
  final UserModel user;
  final int? welcomeBonus;

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        token: j['token'] as String,
        user: UserModel.fromJson(j['user'] as Map<String, dynamic>),
        welcomeBonus: j['welcomeBonus'] as int?,
      );
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.emoji,
    required this.createdAt,
    this.read = false,
  });

  final int id;
  final String title;
  final String body;
  final String? emoji;
  final String createdAt;
  final bool read;

  factory NotificationModel.fromJson(Map<String, dynamic> j) => NotificationModel(
        id: j['id'] as int,
        title: j['title'] as String,
        body: j['body'] as String,
        emoji: j['emoji'] as String?,
        createdAt: j['createdAt'] as String,
        read: j['read'] == true || j['read'] == 1,
      );

  NotificationModel markRead() => NotificationModel(
        id: id,
        title: title,
        body: body,
        emoji: emoji,
        createdAt: createdAt,
        read: true,
      );
}

class CreateBookingResult {
  const CreateBookingResult({
    required this.id,
    required this.bookingCode,
    required this.totalAmount,
    required this.serviceFee,
  });

  final int id;
  final String bookingCode;
  final int totalAmount;
  final int serviceFee;

  factory CreateBookingResult.fromJson(Map<String, dynamic> j) => CreateBookingResult(
        id: j['id'] as int,
        bookingCode: j['bookingCode'] as String,
        totalAmount: j['totalAmount'] as int,
        serviceFee: j['serviceFee'] as int,
      );
}

class FeedCommentModel {
  const FeedCommentModel({required this.id, required this.postId, required this.authorName, required this.text, required this.createdAt});

  final int id;
  final int postId;
  final String authorName;
  final String text;
  final String createdAt;

  factory FeedCommentModel.fromJson(Map<String, dynamic> j) => FeedCommentModel(
        id: j['id'] as int,
        postId: j['postId'] as int,
        authorName: j['authorName'] as String,
        text: j['text'] as String,
        createdAt: j['createdAt'] as String,
      );
}

class TrackingSnapshot {
  const TrackingSnapshot({
    required this.providerLat,
    required this.providerLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.distanceKm,
    required this.etaMinutes,
    required this.progressStep,
    this.providerName,
    this.providerAvatarUrl,
    this.providerPhone,
    this.bookingCode,
    this.address,
  });

  final double providerLat;
  final double providerLng;
  final double destinationLat;
  final double destinationLng;
  final double distanceKm;
  final int etaMinutes;
  final int progressStep;
  final String? providerName;
  final String? providerAvatarUrl;
  final String? providerPhone;
  final String? bookingCode;
  final String? address;

  factory TrackingSnapshot.fromJson(Map<String, dynamic> j) => TrackingSnapshot(
        providerLat: (j['providerLat'] as num).toDouble(),
        providerLng: (j['providerLng'] as num).toDouble(),
        destinationLat: (j['destinationLat'] as num).toDouble(),
        destinationLng: (j['destinationLng'] as num).toDouble(),
        distanceKm: (j['distanceKm'] as num).toDouble(),
        etaMinutes: j['etaMinutes'] as int,
        progressStep: j['progressStep'] as int,
        providerName: j['providerName'] as String?,
        providerAvatarUrl: j['providerAvatarUrl'] as String?,
        providerPhone: j['providerPhone'] as String?,
        bookingCode: j['bookingCode'] as String?,
        address: j['address'] as String?,
      );
}

/// Explore filter options.
class ProviderFilters {
  const ProviderFilters({
    this.minPrice = 0,
    this.maxPrice = 50000,
    this.maxDistance = 15,
    this.area,
    this.sortBy = 'featured',
    this.verifiedOnly = false,
    this.venueType = 'all',
    this.mobileOnly = false,
    this.soloProOnly = false,
  });

  final int minPrice;
  final int maxPrice;
  final double maxDistance;
  final String? area;
  final String sortBy;
  final bool verifiedOnly;
  final String venueType; // all | salon | mobile | both
  final bool mobileOnly;
  final bool soloProOnly;

  ProviderFilters copyWith({
    int? minPrice,
    int? maxPrice,
    double? maxDistance,
    String? area,
    String? sortBy,
    bool? verifiedOnly,
    String? venueType,
    bool? mobileOnly,
    bool? soloProOnly,
  }) =>
      ProviderFilters(
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        maxDistance: maxDistance ?? this.maxDistance,
        area: area ?? this.area,
        sortBy: sortBy ?? this.sortBy,
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
        venueType: venueType ?? this.venueType,
        mobileOnly: mobileOnly ?? this.mobileOnly,
        soloProOnly: soloProOnly ?? this.soloProOnly,
      );

  bool get isDefault =>
      minPrice == 0 &&
      maxPrice == 50000 &&
      maxDistance == 15 &&
      area == null &&
      sortBy == 'featured' &&
      !verifiedOnly &&
      venueType == 'all' &&
      !mobileOnly &&
      !soloProOnly;
}

class ConversationModel {
  const ConversationModel({
    required this.bookingId,
    required this.providerName,
    required this.providerEmoji,
    required this.lastMessage,
    required this.updatedAt,
    this.unread = 0,
    this.customerName,
  });

  final int bookingId;
  final String providerName;
  final String providerEmoji;
  final String lastMessage;
  final String updatedAt;
  final int unread;
  final String? customerName;

  String get displayName => customerName ?? providerName;
  String get displayEmoji => customerName != null ? '👤' : providerEmoji;

  factory ConversationModel.fromJson(Map<String, dynamic> j) => ConversationModel(
        bookingId: j['bookingId'] as int,
        providerName: j['providerName'] as String? ?? 'Provider',
        providerEmoji: j['providerEmoji'] as String? ?? '💄',
        lastMessage: j['lastMessage'] as String? ?? '',
        updatedAt: j['updatedAt'] as String? ?? '',
        unread: j['unread'] as int? ?? 0,
        customerName: j['customerName'] as String?,
      );
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
    this.isMine = false,
  });

  final int id;
  final int bookingId;
  final int senderId;
  final String senderName;
  final String body;
  final String createdAt;
  final bool isMine;

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id: j['id'] as int,
        bookingId: j['bookingId'] as int,
        senderId: j['senderId'] as int,
        senderName: j['senderName'] as String? ?? 'User',
        body: j['body'] as String,
        createdAt: j['createdAt'] as String,
        isMine: j['isMine'] as bool? ?? false,
      );
}

class ProviderClientModel {
  const ProviderClientModel({
    required this.userId,
    required this.name,
    required this.bookingCount,
    required this.lifetimeValue,
    required this.lastBookingAt,
    this.phone,
    this.email,
    this.upcomingCount = 0,
  });

  final int userId;
  final String name;
  final String? phone;
  final String? email;
  final int bookingCount;
  final int lifetimeValue;
  final String lastBookingAt;
  final int upcomingCount;

  factory ProviderClientModel.fromJson(Map<String, dynamic> j) => ProviderClientModel(
        userId: j['userId'] as int,
        name: j['name'] as String? ?? 'Client',
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        bookingCount: j['bookingCount'] as int? ?? 0,
        lifetimeValue: j['lifetimeValue'] as int? ?? 0,
        lastBookingAt: j['lastBookingAt'] as String? ?? '',
        upcomingCount: j['upcomingCount'] as int? ?? 0,
      );
}
