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

  factory ProviderModel.fromJson(Map<String, dynamic> j) => ProviderModel(
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
      );

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

  factory BookingModel.fromJson(Map<String, dynamic> j) => BookingModel(
        id: j['id'] as int,
        bookingCode: j['bookingCode'] as String,
        status: j['status'] as String,
        locationType: j['locationType'] as String,
        address: j['address'] as String?,
        scheduledAt: j['scheduledAt'] as String,
        totalAmount: j['totalAmount'] as int,
        providerId: (j['provider'] as Map<String, dynamic>)['id'] as int,
        providerName: (j['provider'] as Map<String, dynamic>)['name'] as String,
        providerEmoji: (j['provider'] as Map<String, dynamic>)['emoji'] as String,
        serviceName: (j['service'] as Map<String, dynamic>)['name'] as String,
      );
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
  });

  final int id;
  final String slug;
  final String label;
  final String emoji;
  final String? filter;
  final String? imageUrl;

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

  bool get isCredit => type == 'credit';
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

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  final int id;
  final int bookingId;
  final int senderId;
  final String senderName;
  final String body;
  final String createdAt;

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) => ChatMessageModel(
        id: j['id'] as int,
        bookingId: j['bookingId'] as int,
        senderId: j['senderId'] as int,
        senderName: j['senderName'] as String,
        body: j['body'] as String,
        createdAt: j['createdAt'] as String,
      );
}

class SyncSnapshot {
  const SyncSnapshot({
    required this.serverTime,
    required this.walletBalance,
    required this.unreadNotifications,
    required this.notifications,
    required this.walletTransactions,
    required this.feedPosts,
  });

  final String serverTime;
  final int walletBalance;
  final int unreadNotifications;
  final List<NotificationModel> notifications;
  final List<WalletTransactionModel> walletTransactions;
  final List<FeedPostModel> feedPosts;

  factory SyncSnapshot.fromJson(Map<String, dynamic> j) => SyncSnapshot(
        serverTime: j['serverTime'] as String,
        walletBalance: j['walletBalance'] as int? ?? 0,
        unreadNotifications: j['unreadNotifications'] as int? ?? 0,
        notifications: (j['notifications'] as List? ?? [])
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        walletTransactions: (j['walletTransactions'] as List? ?? [])
            .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        feedPosts: (j['feedPosts'] as List? ?? [])
            .map((e) => FeedPostModel.fromJson(e as Map<String, dynamic>))
            .toList(),
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
  });

  final int minPrice;
  final int maxPrice;
  final double maxDistance;
  final String? area;
  final String sortBy;
  final bool verifiedOnly;

  ProviderFilters copyWith({int? minPrice, int? maxPrice, double? maxDistance, String? area, String? sortBy, bool? verifiedOnly}) =>
      ProviderFilters(
        minPrice: minPrice ?? this.minPrice,
        maxPrice: maxPrice ?? this.maxPrice,
        maxDistance: maxDistance ?? this.maxDistance,
        area: area ?? this.area,
        sortBy: sortBy ?? this.sortBy,
        verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      );

  bool get isDefault =>
      minPrice == 0 && maxPrice == 50000 && maxDistance == 15 && area == null && sortBy == 'featured' && !verifiedOnly;
}
