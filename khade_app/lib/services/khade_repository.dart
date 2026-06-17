import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';
import '../models/models.dart';
import '../constants/khade_categories.dart';
import '../utils/geo_utils.dart';
import 'khade_api.dart';
import 'location_service.dart';
import 'location_prefs.dart';
import 'auth_service.dart';
import 'supabase_realtime_service.dart';

/// Central store: embedded backend seed data + live API sync.
class KhadeRepository extends ChangeNotifier {
  KhadeRepository._();
  static final KhadeRepository instance = KhadeRepository._();

  UserModel? user;
  List<CategoryModel> categories = [];
  List<ProviderModel> providers = [];
  List<FeedPostModel> feed = [];
  List<BookingModel> bookings = [];
  List<BookingModel> providerBookings = [];
  List<ProviderClientModel> providerClients = [];
  Map<String, dynamic> providerAvailability = {};
  List<NotificationModel> notifications = [];
  List<WalletTransactionModel> walletTransactions = [];
  List<ReviewModel> reviews = [];
  List<ProviderModel> recentlyViewed = [];
  List<ConversationModel> conversations = [];
  int unreadMessagesCount = 0;
  final Set<int> savedProviderIds = {};
  final Set<int> savedPostIds = {};
  final Set<int> likedPostIds = {};
  final Map<int, List<FeedCommentModel>> _commentsByPost = {};
  final Map<int, List<ServiceModel>> _servicesByProvider = {};

  double userLat = defaultLat;
  double userLng = defaultLng;
  String locationLabel = 'Maitama, Abuja';
  String userAddress = 'Maitama, Abuja';
  bool hasRealLocation = false;
  bool pinAdjusted = false;
  double? locationAccuracyMeters;
  bool inServiceArea = true;
  List<SavedAddress> savedAddresses = [];

  bool isLoading = true;
  bool isLive = false;
  String databaseMode = 'offline';
  String? lastError;
  String apiUrl = ApiConfig.baseUrl;
  Map<String, dynamic> adminStats = {};
  Timer? _notificationTimer;

  int get unreadNotificationCount => notifications.where((n) => !n.read).length;

  Future<void> loadConversations() async {
    try {
      if (isLive && AuthService.instance.isLoggedIn) {
        final list = await khadeApi.getConversations();
        conversations = list;
        unreadMessagesCount = list.fold(0, (sum, c) => sum + c.unread);
      } else {
        conversations = bookings
            .where((b) => b.status != 'cancelled')
            .map((b) => ConversationModel(
                  bookingId: b.id,
                  providerName: b.providerName,
                  providerEmoji: b.providerEmoji,
                  customerName: b.customerName,
                  lastMessage: '${b.serviceName} · ${b.status}',
                  updatedAt: b.scheduledAt.split('T').first,
                  unread: 0,
                ))
            .toList();
        unreadMessagesCount = 0;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadProviderData() async {
    final auth = AuthService.instance.authUser;
    if (auth?.isProvider != true) return;
    final pid = auth!.providerId;
    try {
      if (isLive) {
        providerBookings = await khadeApi.getProviderBookings();
        providerClients = await khadeApi.getProviderClients();
        final me = await khadeApi.getProviderMe();
        providerAvailability = Map<String, dynamic>.from(me['availability'] as Map? ?? {});
        if (pid != null) {
          bookings = [
            ...bookings.where((b) => b.providerId != pid),
            ...providerBookings,
          ];
        }
      } else if (pid != null) {
        providerBookings = bookingsForProvider(pid);
        providerClients = _deriveClients(providerBookings);
      }
      notifyListeners();
    } catch (_) {}
  }

  List<ProviderClientModel> _deriveClients(List<BookingModel> appts) {
    final byUser = <int, ProviderClientModel>{};
    for (final b in appts.where((x) => x.status != 'cancelled')) {
      final uid = b.userId ?? 0;
      final existing = byUser[uid];
      if (existing == null) {
        byUser[uid] = ProviderClientModel(
          userId: uid,
          name: b.customerName ?? 'Client',
          phone: b.customerPhone,
          bookingCount: 1,
          lifetimeValue: b.status == 'completed' ? b.totalAmount : 0,
          lastBookingAt: b.scheduledAt,
          upcomingCount: b.status == 'upcoming' ? 1 : 0,
        );
      } else {
        byUser[uid] = ProviderClientModel(
          userId: uid,
          name: existing.name,
          phone: existing.phone ?? b.customerPhone,
          bookingCount: existing.bookingCount + 1,
          lifetimeValue: existing.lifetimeValue + (b.status == 'completed' ? b.totalAmount : 0),
          lastBookingAt: b.scheduledAt.compareTo(existing.lastBookingAt) > 0 ? b.scheduledAt : existing.lastBookingAt,
          upcomingCount: existing.upcomingCount + (b.status == 'upcoming' ? 1 : 0),
        );
      }
    }
    final list = byUser.values.toList()
      ..sort((a, b) => b.lastBookingAt.compareTo(a.lastBookingAt));
    return list;
  }

  List<BookingModel> bookingsForProvider(int providerId) =>
      (providerBookings.isNotEmpty && AuthService.instance.authUser?.providerId == providerId)
          ? providerBookings
          : bookings.where((b) => b.providerId == providerId).toList();

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

  Future<void> refreshNotifications() async {
    if (isLive) {
      try {
        notifications = await khadeApi.getNotifications();
        notifyListeners();
      } catch (_) {}
      return;
    }
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    if (isLive) {
      try {
        await khadeApi.markAllNotificationsRead();
        notifications = notifications.map((n) => n.markRead()).toList();
      } catch (_) {
        notifications = notifications.map((n) => n.markRead()).toList();
      }
    } else {
      notifications = notifications.map((n) => n.markRead()).toList();
    }
    notifyListeners();
  }

  void _prependNotification({required String title, required String body, String emoji = '✦'}) {
    notifications.insert(
      0,
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        emoji: emoji,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
    notifyListeners();
  }

  void _startNotificationPolling() {
    _notificationTimer?.cancel();
    if (!isLive) return;
    if (SupabaseRealtimeService.instance.isReady) return;
    _notificationTimer = Timer.periodic(const Duration(seconds: 10), (_) => refreshNotifications());
  }

  Future<void> _startRealtime() async {
    if (!isLive || !SupabaseRealtimeService.instance.isReady) {
      _startNotificationPolling();
      return;
    }
    _stopNotificationPolling();
    await SupabaseRealtimeService.instance.start(
      userId: _activeUserId,
      onNotifications: refreshNotifications,
      onMessages: loadConversations,
      onWallet: _onWalletRealtime,
    );
  }

  Future<void> _onWalletRealtime() async {
    await refreshWalletTransactions();
    if (!AuthService.instance.isLoggedIn) return;
    try {
      final u = await khadeApi.getMe();
      user = u;
      AuthService.instance.updateUser(u);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _stopRealtime() async {
    await SupabaseRealtimeService.instance.stop();
  }

  void _stopNotificationPolling() {
    _notificationTimer?.cancel();
    _notificationTimer = null;
  }

  Future<void> disposeRealtime() async {
    _stopNotificationPolling();
    await _stopRealtime();
  }

  bool isProviderSaved(int id) => savedProviderIds.contains(id);

  List<FeedCommentModel> commentsForPost(int postId) => _commentsByPost[postId] ?? [];

  Future<void> updateUserLocation() async {
    final loc = await resolveUserLocation();
    if (loc != null) {
      await applyDeliveryPoint(loc.toDeliveryPoint(), fromGps: true, persist: true);
    }
  }

  Future<void> applyDeliveryPoint(DeliveryPoint point, {bool fromGps = false, bool persist = true}) async {
    userLat = point.latitude;
    userLng = point.longitude;
    locationLabel = point.label;
    userAddress = point.address;
    locationAccuracyMeters = point.accuracyMeters;
    pinAdjusted = point.pinAdjusted;
    hasRealLocation = fromGps || point.pinAdjusted;
    inServiceArea = point.inServiceArea;
    _recalculateProviderDistances();
    if (persist) await LocationPrefs.saveDeliveryPoint(point);
    notifyListeners();
  }

  Future<void> loadSavedLocation() async {
    savedAddresses = await LocationPrefs.loadSavedAddresses();
    final saved = await LocationPrefs.loadDeliveryPoint();
    if (saved != null) {
      await applyDeliveryPoint(saved, persist: false);
      return;
    }
    await updateUserLocation();
  }

  Future<void> saveCurrentAsHome() async {
    final home = SavedAddress(
      id: 'home',
      name: 'Home',
      emoji: '🏠',
      latitude: userLat,
      longitude: userLng,
      label: locationLabel,
      address: userAddress,
    );
    await LocationPrefs.upsertSavedAddress(home);
    savedAddresses = await LocationPrefs.loadSavedAddresses();
    notifyListeners();
  }

  ProviderModel _withDistance(ProviderModel p) {
    final d = distanceToProvider(p);
    return ProviderModel(
      id: p.id, name: p.name, category: p.category, emoji: p.emoji, rating: p.rating,
      reviewCount: p.reviewCount, distanceKm: d, area: p.area, priceFrom: p.priceFrom,
      badge: p.badge, verified: p.verified, featured: p.featured,
      gradientStart: p.gradientStart, gradientEnd: p.gradientEnd,
      imageUrl: p.imageUrl, avatarUrl: p.avatarUrl, latitude: p.latitude, longitude: p.longitude,
      phone: p.phone, services: p.services,
    );
  }

  void _recalculateProviderDistances() {
    providers = providers.map(_withDistance).toList();
  }

  /// Featured providers sorted by real distance from you.
  List<ProviderModel> get featuredNearYou {
    final list = providers.where((p) => p.featured).toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return list;
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
    if (filters.soloProOnly) {
      list = list.where((p) => p.providerSubtype == 'solo_pro').toList();
    } else if (filters.mobileOnly || filters.venueType == 'mobile') {
      list = list.where((p) => p.providerType == 'mobile' || p.providerType == 'both').toList();
    } else if (filters.venueType == 'salon') {
      list = list.where((p) => p.providerType == 'salon' || p.providerType == 'both').toList();
    } else if (filters.venueType == 'both') {
      list = list.where((p) => p.providerType == 'both').toList();
    }

    final withDist = list.map(_withDistance).toList().where((p) => p.distanceKm <= filters.maxDistance).toList();

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

  List<FeedPostModel> get photoFeed => feed.where((p) => !p.isVideo).toList();

  List<FeedPostModel> get videoFeed => feed.where((p) => p.isVideo).toList();

  List<FeedPostModel> feedForYou({Set<String>? interestedCategories}) {
    final followed = savedProviderIds;
    final cats = interestedCategories ?? recentlyViewed.map((p) => p.category).toSet();
    final posts = photoFeed.map((p) {
      var score = 0.0;
      if (followed.contains(p.providerId)) score += 100;
      if (cats.contains(p.category)) score += 50;
      score += (p.likes / 10).clamp(0, 20);
      return (post: p, score: score);
    }).toList();
    posts.sort((a, b) => b.score.compareTo(a.score));
    return posts.map((e) => e.post).toList();
  }

  List<FeedPostModel> feedFollowing() =>
      photoFeed.where((p) => savedProviderIds.contains(p.providerId)).toList();

  List<FeedPostModel> feedTrending() {
    final sorted = [...photoFeed];
    sorted.sort((a, b) => (b.likes + b.comments * 2).compareTo(a.likes + a.comments * 2));
    return sorted;
  }

  List<ProviderModel> storyProviders() {
    final ids = photoFeed.map((p) => p.providerId).toSet();
    return providers.where((p) => ids.contains(p.id) && savedProviderIds.contains(p.id)).take(12).toList();
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
        providerLat: startLat + (userLat - startLat) * progress,
        providerLng: startLng + (userLng - startLng) * progress,
        destinationLat: userLat,
        destinationLng: userLng,
        distanceKm: 3.4 * (1 - progress),
        etaMinutes: (12 * (1 - progress)).ceil().clamp(1, 30),
        progressStep: progress < 0.3 ? 2 : progress < 0.7 ? 3 : 4,
        providerName: provider?.name ?? booking?.providerName,
        providerAvatarUrl: provider?.avatarUrl,
        providerPhone: provider?.phone,
        bookingCode: booking?.bookingCode,
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
        await refreshNotifications();
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
    final b = bookingById(bookingId);
    if (b != null) {
      _prependNotification(
        title: 'Booking Cancelled',
        body: '${b.bookingCode} with ${b.providerName} was cancelled',
        emoji: '✕',
      );
    }
    notifyListeners();
  }

  List<ProviderModel> get featured => featuredNearYou;

  /// Fixed v3 category list — All first.
  List<CategoryModel> get displayCategories => KhadeCategories.home;

  int categoryIndexForSlug(String? slug, {String? label}) {
    final cats = displayCategories;
    if (slug != null && slug.isNotEmpty) {
      final i = cats.indexWhere((c) => c.slug == slug);
      if (i >= 0) return i;
    }
    if (label != null && label.isNotEmpty) {
      final i = cats.indexWhere((c) => c.label == label);
      if (i >= 0) return i;
    }
    return 0;
  }

  List<ProviderModel> byCategory(String? label) {
    if (label == null || label == 'All') return providers;
    CategoryModel? cat;
    for (final c in displayCategories) {
      if (c.label == label) {
        cat = c;
        break;
      }
    }
    final filter = cat?.filter ?? label.toLowerCase();
    if (filter.isEmpty) return providers;
    return providers.where((p) =>
      p.category.toLowerCase().contains(filter) ||
      p.name.toLowerCase().contains(filter),
    ).toList();
  }

  String get _userArea => locationLabel.split(',').first.trim();

  List<ProviderModel> recommendedProviders({String? categoryLabel}) {
    var list = byCategory(categoryLabel).where((p) => p.featured || p.rating >= 4.5).toList();
    if (list.isEmpty) list = byCategory(categoryLabel);
    final area = _userArea.toLowerCase();
    list.sort((a, b) {
      final aArea = a.area.toLowerCase().contains(area) ? 1 : 0;
      final bArea = b.area.toLowerCase().contains(area) ? 1 : 0;
      if (bArea != aArea) return bArea.compareTo(aArea);
      return b.rating.compareTo(a.rating);
    });
    return list.map(_withDistance).toList();
  }

  List<ProviderModel> nearbyProviders({String? categoryLabel, int limit = 8}) {
    final area = _userArea.toLowerCase();
    var list = byCategory(categoryLabel);
    list = list.where((p) =>
      p.area.toLowerCase().contains(area) || p.distanceKm <= 5,
    ).toList();
    list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return list.take(limit).map(_withDistance).toList();
  }

  Future<void> loadRecentlyViewed() async {
    if (!isLive) return;
    try {
      recentlyViewed = await khadeApi.getRecentlyViewed(
        userId: _activeUserId,
        lat: userLat,
        lng: userLng,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<ProviderModel?> fetchProviderDetail(int id) async {
    if (isLive) {
      try {
        final detail = await khadeApi.getProviderDetail(id);
        await recordProviderView(id);
        return detail;
      } catch (_) {}
    }
    return providerById(id);
  }

  Future<void> recordProviderView(int providerId) async {
    if (isLive) {
      try {
        await khadeApi.recordProviderView(providerId, userId: _activeUserId);
      } catch (_) {}
    }
    final p = providerById(providerId);
    if (p != null) {
      recentlyViewed.removeWhere((x) => x.id == providerId);
      recentlyViewed.insert(0, p);
      if (recentlyViewed.length > 10) recentlyViewed.removeLast();
      notifyListeners();
    }
  }

  Future<void> refreshWalletTransactions() async {
    if (!isLive) return;
    try {
      walletTransactions = await khadeApi.getWalletTransactions(userId: _activeUserId);
      notifyListeners();
    } catch (_) {}
  }

  ProviderModel? providerById(int id) {
    try {
      final p = providers.firstWhere((p) => p.id == id);
      return _withDistance(ProviderModel(
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
        latitude: p.latitude,
        longitude: p.longitude,
        phone: p.phone,
        services: _servicesByProvider[id] ?? [],
      ));
    } catch (_) {
      return null;
    }
  }

  int get _activeUserId => AuthService.instance.authUser?.id ?? ApiConfig.defaultUserId;

  Future<void> syncAfterAuth(UserModel authUser) async {
    user = authUser;
    notifyListeners();
    await _syncFromApi();
  }

  Future<void> initialize() async {
    isLoading = true;
    lastError = null;
    notifyListeners();
    await AuthService.instance.loadSession();
    if (AuthService.instance.authUser != null) {
      user = AuthService.instance.authUser;
    }
    await _loadEmbedded();
    await loadSavedLocation();
    notifyListeners();
    await _syncFromApi();
    isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await updateUserLocation();
    await _syncFromApi();
    if (AuthService.instance.authUser?.isProvider == true) {
      await loadProviderData();
    }
    await loadConversations();
  }

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
      databaseMode = await khadeApi.getDatabaseMode();
      final bootstrap = await khadeApi.getBootstrap(userId: _activeUserId, lat: userLat, lng: userLng);
      _applyBootstrap(bootstrap);
      if (AuthService.instance.authUser != null) {
        user = AuthService.instance.authUser;
      }
      if (hasRealLocation) _recalculateProviderDistances();
      try {
        if (user?.isAdmin == true && AuthService.instance.isLoggedIn) {
          adminStats = await khadeApi.getAdminDashboard();
        } else {
          adminStats = await khadeApi.getAdminStats();
        }
      } catch (_) {
        _computeAdminStats();
      }
      isLive = true;
      lastError = null;
      await _startRealtime();
      await refreshNotifications();
      if (AuthService.instance.authUser?.isProvider == true) {
        await loadProviderData();
      }
      await loadConversations();
    } catch (e) {
      isLive = false;
      lastError = e.toString();
      databaseMode = 'offline';
      await disposeRealtime();
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
    _recalculateProviderDistances();
  }

  void _defaultCategories() {
    categories = KhadeCategories.home;
  }

  Future<CreateBookingResult?> completePaymentAndBook({
    required int providerId,
    required int serviceId,
    required String scheduledAt,
    required int totalAmount,
    required String paymentMethod,
    String locationType = 'home',
    String? address,
    String? note,
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
          address: address ?? (locationType == 'home' ? userAddress : null),
          destLat: locationType == 'home' ? userLat : null,
          destLng: locationType == 'home' ? userLng : null,
          paymentMethod: paymentMethod,
          totalAmount: totalAmount,
          note: note,
        );
        await _syncFromApi();
        await refreshNotifications();
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

  Future<bool> topUpWallet(int amount, {String? paystackReference}) async {
    try {
      if (isLive) {
        final newBal = await khadeApi.topUpWallet(amount: amount, paystackReference: paystackReference);
        user = UserModel(
          id: user!.id, name: user!.name, city: user!.city, tier: user!.tier,
          walletBalance: newBal, bookingsCount: user!.bookingsCount,
          savedProviders: user!.savedProviders, memberSince: user!.memberSince,
        );
        await refreshWalletTransactions();
        await refreshNotifications();
      } else {
        _creditWalletLocal(amount, 'Wallet top-up via Paystack');
        _prependNotification(
          title: 'Wallet Topped Up',
          body: '₦${amount.toString()} added to your wallet',
          emoji: '💳',
        );
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
    _prependNotification(
      title: 'Booking Confirmed',
      body: '$code with ${provider?.name ?? 'Provider'} is confirmed',
      emoji: '✓',
    );
    notifyListeners();
    final fee = (totalAmount * 0.1).round();
    return CreateBookingResult(id: bookings.length, bookingCode: code, totalAmount: totalAmount, serviceFee: fee);
  }
}
