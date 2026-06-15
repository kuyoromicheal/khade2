import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../models/models.dart';
import '../utils/geo_utils.dart';
import 'khade_api.dart';

/// Central store: embedded backend seed data + live API sync.
class KhadeRepository extends ChangeNotifier {
  KhadeRepository._();
  static final KhadeRepository instance = KhadeRepository._();

  UserModel? user;
  List<CategoryModel> categories = [];
  List<ProviderModel> providers = [];
  List<FeedPostModel> feed = [];
  List<BookingModel> bookings = [];
  List<NotificationModel> notifications = [];
  List<WalletTransactionModel> walletTransactions = [];
  List<ReviewModel> reviews = [];
  final Set<int> savedProviderIds = {};
  final Set<int> savedPostIds = {};
  final Set<int> likedPostIds = {};
  final Map<int, List<FeedCommentModel>> _commentsByPost = {};
  final Map<int, List<ServiceModel>> _servicesByProvider = {};

  double userLat = defaultLat;
  double userLng = defaultLng;

  bool isLoading = true;
  bool isLive = false;
  String? lastError;
  String apiUrl = ApiConfig.baseUrl;
  Map<String, dynamic> adminStats = {};

  List<BookingModel> bookingsForProvider(int providerId) =>
      bookings.where((b) => b.providerId == providerId).toList();

  List<FeedPostModel> feedForProvider(int providerId) =>
      feed.where((p) => p.providerId == providerId).toList();

  List<ProviderModel> get savedProviders =>
      providers.where((p) => savedProviderIds.contains(p.id)).toList();

  BookingModel? bookingById(int id) {
    try {
      return bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  BookingModel? bookingByCode(String code) {
    try {
      return bookings.firstWhere((b) => b.bookingCode == code);
    } catch (_) {
      return null;
    }
  }

  List<ReviewModel> reviewsForProvider(int providerId) =>
      reviews.where((r) => r.providerId == providerId).toList();

  void toggleSaveProvider(int id) {
    final wasSaved = savedProviderIds.contains(id);
    if (wasSaved) {
      savedProviderIds.remove(id);
    } else {
      savedProviderIds.add(id);
    }
    if (user != null) {
      user = UserModel(
        id: user!.id, name: user!.name, city: user!.city, tier: user!.tier,
        walletBalance: user!.walletBalance, bookingsCount: user!.bookingsCount,
        savedProviders: savedProviderIds.length, memberSince: user!.memberSince,
      );
    }
    notifyListeners();
    if (isLive) {
      khadeApi.toggleSavedProvider(id).catchError((_) {
        if (wasSaved) {
          savedProviderIds.add(id);
        } else {
          savedProviderIds.remove(id);
        }
        notifyListeners();
        return false;
      });
    }
  }

  Future<bool> submitReview({required int providerId, required int rating, required String comment}) async {
    try {
      if (isLive) {
        final r = await khadeApi.submitReview(providerId: providerId, rating: rating, comment: comment);
        reviews.insert(0, r);
        await _syncFromApi();
      } else {
        reviews.insert(0, ReviewModel(
          id: reviews.length + 1,
          providerId: providerId,
          rating: rating,
          comment: comment,
          authorName: user?.name ?? 'Guest',
          createdAt: DateTime.now().toIso8601String(),
        ));
        notifyListeners();
      }
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool isProviderSaved(int id) => savedProviderIds.contains(id);

  List<FeedCommentModel> commentsForPost(int postId) => _commentsByPost[postId] ?? [];

  Future<void> updateUserLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition();
      userLat = pos.latitude;
      userLng = pos.longitude;
      notifyListeners();
    } catch (_) {}
  }

  double distanceToProvider(ProviderModel p) {
    if (p.latitude == null || p.longitude == null) return p.distanceKm;
    return double.parse(haversineKm(userLat, userLng, p.latitude!, p.longitude!).toStringAsFixed(1));
  }

  List<ProviderModel> filterProviders({
    String? categoryLabel,
    String query = '',
    ProviderFilters filters = const ProviderFilters(),
  }) {
    var list = byCategory(categoryLabel);
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q) || p.category.toLowerCase().contains(q) || p.area.toLowerCase().contains(q)).toList();
    }
    if (filters.area != null && filters.area!.isNotEmpty) {
      final a = filters.area!.toLowerCase();
      list = list.where((p) => p.area.toLowerCase().contains(a)).toList();
    }
    list = list.where((p) => p.priceFrom >= filters.minPrice && p.priceFrom <= filters.maxPrice).toList();
    if (filters.verifiedOnly) list = list.where((p) => p.verified).toList();

    final withDist = list.map((p) {
      final d = distanceToProvider(p);
      return ProviderModel(
        id: p.id, name: p.name, category: p.category, emoji: p.emoji, rating: p.rating,
        reviewCount: p.reviewCount, distanceKm: d, area: p.area, priceFrom: p.priceFrom,
        badge: p.badge, verified: p.verified, featured: p.featured,
        gradientStart: p.gradientStart, gradientEnd: p.gradientEnd,
        imageUrl: p.imageUrl, avatarUrl: p.avatarUrl, latitude: p.latitude, longitude: p.longitude,
        services: p.services,
      );
    }).where((p) => p.distanceKm <= filters.maxDistance).toList();

    withDist.sort((a, b) {
      switch (filters.sortBy) {
        case 'price_asc': return a.priceFrom.compareTo(b.priceFrom);
        case 'price_desc': return b.priceFrom.compareTo(a.priceFrom);
        case 'distance': return a.distanceKm.compareTo(b.distanceKm);
        case 'rating': return b.rating.compareTo(a.rating);
        default: return (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0);
      }
    });
    return withDist;
  }

  void toggleLikePost(int id) {
    final wasLiked = likedPostIds.contains(id);
    if (wasLiked) {
      likedPostIds.remove(id);
    } else {
      likedPostIds.add(id);
    }
    final idx = feed.indexWhere((p) => p.id == id);
    if (idx >= 0) {
      final p = feed[idx];
      feed[idx] = FeedPostModel(
        id: p.id, imageEmoji: p.imageEmoji, badge: p.badge, caption: p.caption,
        likes: p.likes + (wasLiked ? -1 : 1), comments: p.comments,
        providerName: p.providerName, providerEmoji: p.providerEmoji, category: p.category,
        rating: p.rating, area: p.area, providerId: p.providerId,
        imageUrl: p.imageUrl, videoUrl: p.videoUrl, mediaType: p.mediaType,
        providerAvatarUrl: p.providerAvatarUrl, providerImageUrl: p.providerImageUrl,
      );
    }
    notifyListeners();
    if (isLive) {
      khadeApi.likeFeedPost(id).catchError((_) {
        if (wasLiked) likedPostIds.add(id); else likedPostIds.remove(id);
        notifyListeners();
        return <String, dynamic>{};
      });
    }
  }

  Future<List<FeedCommentModel>> loadComments(int postId) async {
    try {
      if (isLive) {
        final list = await khadeApi.getFeedComments(postId);
        _commentsByPost[postId] = list;
      }
      notifyListeners();
      return _commentsByPost[postId] ?? [];
    } catch (_) {
      return _commentsByPost[postId] ?? [];
    }
  }

  Future<bool> addComment(int postId, String text) async {
    try {
      if (isLive) {
        final c = await khadeApi.addFeedComment(postId, text, authorName: user?.name);
        _commentsByPost.putIfAbsent(postId, () => []).insert(0, c);
        final idx = feed.indexWhere((p) => p.id == postId);
        if (idx >= 0) {
          final p = feed[idx];
          feed[idx] = FeedPostModel(
            id: p.id, imageEmoji: p.imageEmoji, badge: p.badge, caption: p.caption,
            likes: p.likes, comments: p.comments + 1,
            providerName: p.providerName, providerEmoji: p.providerEmoji, category: p.category,
            rating: p.rating, area: p.area, providerId: p.providerId,
            imageUrl: p.imageUrl, videoUrl: p.videoUrl, mediaType: p.mediaType,
            providerAvatarUrl: p.providerAvatarUrl, providerImageUrl: p.providerImageUrl,
          );
        }
      } else {
        _commentsByPost.putIfAbsent(postId, () => []).insert(0, FeedCommentModel(
          id: (_commentsByPost[postId]?.length ?? 0) + 1,
          postId: postId,
          authorName: user?.name ?? 'Guest',
          text: text,
          createdAt: DateTime.now().toIso8601String(),
        ));
      }
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString();
      return false;
    }
  }

  Future<TrackingSnapshot?> fetchTracking(int bookingId) async {
    try {
      if (isLive) return await khadeApi.getTracking(bookingId);
      final booking = bookingById(bookingId);
      final provider = booking != null ? providerById(booking.providerId) : providers.firstOrNull;
      final startLat = provider?.latitude ?? 9.0833;
      final startLng = provider?.longitude ?? 7.495;
      final progress = (DateTime.now().millisecond % 1000) / 1000 * 0.7 + 0.2;
      return TrackingSnapshot(
        providerLat: startLat + (defaultLat - startLat) * progress,
        providerLng: startLng + (defaultLng - startLng) * progress,
        destinationLat: defaultLat,
        destinationLng: defaultLng,
        distanceKm: 3.4 * (1 - progress),
        etaMinutes: (12 * (1 - progress)).ceil().clamp(1, 30),
        progressStep: progress < 0.3 ? 2 : progress < 0.7 ? 3 : 4,
        providerName: provider?.name ?? booking?.providerName,
        providerAvatarUrl: provider?.avatarUrl,
        address: booking?.address,
      );
    } catch (_) {
      return null;
    }
  }

  void toggleSavePost(int id) {
    if (savedPostIds.contains(id)) {
      savedPostIds.remove(id);
    } else {
      savedPostIds.add(id);
    }
    notifyListeners();
  }

  Future<bool> cancelBooking(int bookingId) async {
    try {
      if (isLive) {
        await khadeApi.cancelBooking(bookingId);
        await _syncFromApi();
      } else {
        _cancelBookingLocal(bookingId);
      }
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _cancelBookingLocal(int bookingId) {
    bookings = bookings.map((b) {
      if (b.id != bookingId) return b;
      return BookingModel(
        id: b.id, bookingCode: b.bookingCode, status: 'cancelled',
        locationType: b.locationType, address: b.address, scheduledAt: b.scheduledAt,
        totalAmount: b.totalAmount, providerId: b.providerId, providerName: b.providerName,
        providerEmoji: b.providerEmoji, serviceName: b.serviceName,
      );
    }).toList();
    notifyListeners();
  }

  List<ProviderModel> get featured => providers.where((p) => p.featured).toList();

  List<ProviderModel> byCategory(String? label) {
    if (label == null || label == 'All') return providers;
    CategoryModel? cat;
    for (final c in categories) {
      if (c.label == label) {
        cat = c;
        break;
      }
    }
    final filter = cat?.filter ?? label.toLowerCase();
    if (filter.isEmpty) return providers;
    return providers.where((p) => p.category.toLowerCase().contains(filter)).toList();
  }

  ProviderModel? providerById(int id) {
    try {
      final p = providers.firstWhere((p) => p.id == id);
      return ProviderModel(
        id: p.id,
        name: p.name,
        category: p.category,
        emoji: p.emoji,
        rating: p.rating,
        reviewCount: p.reviewCount,
        distanceKm: p.distanceKm,
        area: p.area,
        priceFrom: p.priceFrom,
        badge: p.badge,
        verified: p.verified,
        featured: p.featured,
        gradientStart: p.gradientStart,
        gradientEnd: p.gradientEnd,
        imageUrl: p.imageUrl,
        avatarUrl: p.avatarUrl,
        services: _servicesByProvider[id] ?? [],
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> initialize() async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    await _loadEmbedded();
    notifyListeners();
    await updateUserLocation();
    await _syncFromApi();
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() => _syncFromApi();

  Future<void> _loadEmbedded() async {
    try {
      final raw = await rootBundle.loadString('assets/data/bootstrap.json');
      _applyBootstrap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      lastError = 'Failed to load embedded data: $e';
    }
  }

  Future<void> _syncFromApi() async {
    apiUrl = ApiConfig.baseUrl;
    try {
      final ok = await khadeApi.healthCheck();
      if (!ok) throw Exception('Cannot reach $apiUrl');
      final bootstrap = await khadeApi.getBootstrap();
      _applyBootstrap(bootstrap);
      try {
        adminStats = await khadeApi.getAdminStats();
      } catch (_) {
        _computeAdminStats();
      }
      isLive = true;
      lastError = null;
    } catch (e) {
      isLive = false;
      lastError = e.toString();
      _computeAdminStats();
    }
    notifyListeners();
  }

  void _computeAdminStats() {
    final completed = bookings.where((b) => b.status == 'completed');
    final revenue = completed.fold<int>(0, (sum, b) => sum + b.totalAmount);
    adminStats = {
      'totalRevenue': revenue > 0 ? revenue : 8400000,
      'platformFees': revenue > 0 ? (revenue * 0.1).round() : 840000,
      'bookings': bookings.isNotEmpty ? bookings.length : 1204,
      'activeUsers': user != null ? 1 : 3847,
      'providers': providers.length,
    };
  }

  void _applyBootstrap(Map<String, dynamic> json) {
    user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    categories = (json['categories'] as List? ?? [])
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
    if (categories.isEmpty) _defaultCategories();
    providers = (json['providers'] as List).map((e) => ProviderModel.fromJson(e as Map<String, dynamic>)).toList();
    feed = (json['feed'] as List).map((e) => FeedPostModel.fromJson(e as Map<String, dynamic>)).toList();
    bookings = (json['bookings'] as List).map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
    notifications = (json['notifications'] as List).map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
    walletTransactions = (json['walletTransactions'] as List? ?? [])
        .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
    reviews = (json['reviews'] as List? ?? [])
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
    savedProviderIds
      ..clear()
      ..addAll((json['savedProviderIds'] as List? ?? []).cast<int>());

    _commentsByPost.clear();
    for (final c in json['feedComments'] as List? ?? []) {
      final m = FeedCommentModel.fromJson(c as Map<String, dynamic>);
      _commentsByPost.putIfAbsent(m.postId, () => []).add(m);
    }

    _servicesByProvider.clear();
    for (final s in json['services'] as List) {
      final m = s as Map<String, dynamic>;
      final pid = m['providerId'] as int;
      _servicesByProvider.putIfAbsent(pid, () => []);
      _servicesByProvider[pid]!.add(ServiceModel(
        id: m['id'] as int,
        name: m['name'] as String,
        duration: m['duration'] as String,
        price: m['price'] as int,
      ));
    }
    _computeAdminStats();
    if (savedProviderIds.isEmpty) {
      savedProviderIds.addAll(
        (json['savedProviderIds'] as List?)?.cast<int>() ??
            providers.take(user?.savedProviders ?? 7).map((p) => p.id),
      );
    }
  }

  void _defaultCategories() {
    categories = [
      const CategoryModel(id: 1, slug: 'all', label: 'All', emoji: '💆'),
      const CategoryModel(id: 2, slug: 'barbing', label: 'Barbing', emoji: '✂️', filter: 'barb'),
      const CategoryModel(id: 3, slug: 'nails', label: 'Nails', emoji: '💅', filter: 'nail'),
      const CategoryModel(id: 4, slug: 'makeup', label: 'Makeup', emoji: '💄', filter: 'makeup'),
      const CategoryModel(id: 5, slug: 'spa', label: 'Spa', emoji: '🧖', filter: 'spa'),
      const CategoryModel(id: 6, slug: 'hair', label: 'Hair', emoji: '💇', filter: 'hair'),
    ];
  }

  Future<CreateBookingResult?> completePaymentAndBook({
    required int providerId,
    required int serviceId,
    required String scheduledAt,
    required int totalAmount,
    required String paymentMethod,
    String locationType = 'home',
    String? address,
  }) async {
    try {
      if (paymentMethod == 'wallet') {
        final balance = user?.walletBalance ?? 0;
        if (balance < totalAmount) {
          lastError = 'Insufficient wallet balance';
          notifyListeners();
          return null;
        }
        if (isLive) {
          final newBal = await khadeApi.payWithWallet(amount: totalAmount);
          user = UserModel(
            id: user!.id, name: user!.name, city: user!.city, tier: user!.tier,
            walletBalance: newBal, bookingsCount: user!.bookingsCount,
            savedProviders: user!.savedProviders, memberSince: user!.memberSince,
          );
        } else {
          _debitWalletLocal(totalAmount, 'Booking payment');
        }
      }

      if (isLive) {
        final result = await khadeApi.createBooking(
          providerId: providerId,
          serviceId: serviceId,
          scheduledAt: scheduledAt,
          locationType: locationType,
          address: address,
          paymentMethod: paymentMethod,
        );
        await _syncFromApi();
        return result;
      }

      return _createBookingLocal(
        providerId: providerId,
        serviceId: serviceId,
        scheduledAt: scheduledAt,
        locationType: locationType,
        address: address,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<PaystackInitResult?> initializePaystack(int amount) async {
    if (!isLive) {
      lastError = 'Connect to backend API to use Paystack checkout';
      notifyListeners();
      return null;
    }
    try {
      return await khadeApi.initializePayment(amount: amount, email: user?.name != null ? 'adaeze@example.com' : 'adaeze@example.com');
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> verifyPaystack(String reference) async {
    if (!isLive) return true;
    try {
      return await khadeApi.verifyPayment(reference);
    } catch (_) {
      return false;
    }
  }

  Future<bool> topUpWallet(int amount) async {
    try {
      if (isLive) {
        final newBal = await khadeApi.topUpWallet(amount: amount);
        user = UserModel(
          id: user!.id, name: user!.name, city: user!.city, tier: user!.tier,
          walletBalance: newBal, bookingsCount: user!.bookingsCount,
          savedProviders: user!.savedProviders, memberSince: user!.memberSince,
        );
      } else {
        _creditWalletLocal(amount, 'Wallet top-up via Paystack');
      }
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _debitWalletLocal(int amount, String desc) {
    if (user == null) return;
    user = UserModel(
      id: user!.id, name: user!.name, city: user!.city, tier: user!.tier,
      walletBalance: user!.walletBalance - amount,
      bookingsCount: user!.bookingsCount, savedProviders: user!.savedProviders,
      memberSince: user!.memberSince,
    );
    walletTransactions.insert(0, WalletTransactionModel(
      id: walletTransactions.length + 1, type: 'debit', amount: amount,
      description: desc, reference: 'LOCAL_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  void _creditWalletLocal(int amount, String desc) {
    if (user == null) return;
    user = UserModel(
      id: user!.id, name: user!.name, city: user!.city, tier: user!.tier,
      walletBalance: user!.walletBalance + amount,
      bookingsCount: user!.bookingsCount, savedProviders: user!.savedProviders,
      memberSince: user!.memberSince,
    );
    walletTransactions.insert(0, WalletTransactionModel(
      id: walletTransactions.length + 1, type: 'credit', amount: amount,
      description: desc, reference: 'TOPUP_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now().toIso8601String(),
    ));
  }

  CreateBookingResult _createBookingLocal({
    required int providerId,
    required int serviceId,
    required String scheduledAt,
    required String locationType,
    String? address,
    required int totalAmount,
    required String paymentMethod,
  }) {
    final code = 'KHD-${1000 + bookings.length}';
    final provider = providerById(providerId);
    final services = _servicesByProvider[providerId] ?? [];
    final service = services.where((s) => s.id == serviceId).firstOrNull ??
        (services.isNotEmpty ? services.first : const ServiceModel(id: 1, name: 'Service', duration: '60 mins', price: 10000));
    bookings.insert(0, BookingModel(
      id: bookings.length + 1,
      bookingCode: code,
      status: 'upcoming',
      locationType: locationType,
      address: address,
      scheduledAt: scheduledAt,
      totalAmount: totalAmount,
      providerId: providerId,
      providerName: provider?.name ?? 'Provider',
      providerEmoji: provider?.emoji ?? '💄',
      serviceName: service.name,
    ));
    notifyListeners();
    final fee = (totalAmount * 0.1).round();
    return CreateBookingResult(id: bookings.length, bookingCode: code, totalAmount: totalAmount, serviceFee: fee);
  }
}
