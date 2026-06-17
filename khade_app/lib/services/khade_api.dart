import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';

class KhadeApi {
  KhadeApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  void setToken(String? token) => _token = token;

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  int get userId => ApiConfig.defaultUserId;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

  Future<AuthResult> login({required String email, required String password}) async {
    final res = await _request(() => _client.post(
          _uri('/api/auth/login'),
          headers: _jsonHeaders,
          body: jsonEncode({'email': email, 'password': password}),
        ));
    _check(res);
    return AuthResult.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    String role = 'customer',
    String city = 'Abuja',
    String? phone,
    String? businessName,
    String visitTypes = 'both',
    String area = 'Wuse II',
  }) async {
    final res = await _request(() => _client.post(
          _uri('/api/auth/register'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'email': email,
            'password': password,
            'name': name,
            'role': role,
            'city': city,
            if (phone != null) 'phone': phone,
            if (businessName != null) 'businessName': businessName,
            'visitTypes': visitTypes,
            'area': area,
          }),
        ));
    _check(res);
    return AuthResult.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<UserModel> getMe() async {
    final res = await _client.get(_uri('/api/auth/me'), headers: _jsonHeaders);
    _check(res);
    return UserModel.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<List<String>> getProviderSlots(int providerId, String date) async {
    final res = await _client.get(_uri('/api/provider/$providerId/slots', {'date': date}));
    _check(res);
    return (jsonDecode(res.body)['data']['slots'] as List<dynamic>).cast<String>();
  }

  Future<Map<String, dynamic>> getProviderEarnings() async {
    final res = await _client.get(_uri('/api/provider/earnings'), headers: _jsonHeaders);
    _check(res);
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProviderMe() async {
    final res = await _client.get(_uri('/api/provider/me'), headers: _jsonHeaders);
    _check(res);
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProviderAvailability(Map<String, dynamic> availability) async {
    final res = await _client.patch(
      _uri('/api/provider/availability'),
      headers: _jsonHeaders,
      body: jsonEncode(availability),
    );
    _check(res);
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<List<BookingModel>> getProviderBookings({String? status, String? from, String? to}) async {
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    if (from != null) query['from'] = from;
    if (to != null) query['to'] = to;
    final res = await _client.get(_uri('/api/provider/bookings', query.isEmpty ? null : query), headers: _jsonHeaders);
    _check(res);
    final list = jsonDecode(res.body)['data'] as List<dynamic>;
    return list.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ProviderClientModel>> getProviderClients() async {
    final res = await _client.get(_uri('/api/provider/clients'), headers: _jsonHeaders);
    _check(res);
    final list = jsonDecode(res.body)['data'] as List<dynamic>;
    return list.map((e) => ProviderClientModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> completeBooking(int bookingId) async =>
      updateBookingStatus(bookingId, 'completed');

  Future<void> updateBookingStatus(int bookingId, String status) async {
    final res = await _client.patch(
      _uri('/api/provider/bookings/$bookingId/status'),
      headers: _jsonHeaders,
      body: jsonEncode({'status': status}),
    );
    _check(res);
  }

  Future<void> requestPayout({required int amount, String bankName = 'Access Bank', String accountNumber = '****'}) async {
    final res = await _client.post(
      _uri('/api/provider/payouts'),
      headers: _jsonHeaders,
      body: jsonEncode({'amount': amount, 'bankName': bankName, 'accountNumber': accountNumber}),
    );
    _check(res);
  }

  Future<void> onboardProvider({
    required String categorySlug,
    required List<Map<String, dynamic>> services,
    String visitTypes = 'both',
    String providerType = 'mobile',
    String providerSubtype = 'solo_pro',
    List<String> workLocations = const [],
    List<String> coverageAreas = const [],
    int travelRadiusKm = 10,
    String area = 'Wuse II',
    String? bio,
    String? brandName,
    String? website,
    List<String> additionalCategories = const [],
    String? crewSize,
    List<String> workStyles = const [],
    String? address,
    double? latitude,
    double? longitude,
    String? travelFeeNote,
  }) async {
    final res = await _request(() => _client.post(
          _uri('/api/provider/onboard'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'categorySlug': categorySlug,
            'services': services,
            'visitTypes': visitTypes,
            'providerType': providerType,
            'providerSubtype': providerSubtype,
            'workLocations': workLocations,
            'coverageAreas': coverageAreas,
            'travelRadiusKm': travelRadiusKm,
            'area': area,
            'bio': bio,
            if (brandName != null) 'brandName': brandName,
            if (website != null) 'website': website,
            if (additionalCategories.isNotEmpty) 'additionalCategories': additionalCategories,
            if (crewSize != null) 'crewSize': crewSize,
            if (workStyles.isNotEmpty) 'workStyles': workStyles,
            if (address != null) 'address': address,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
            if (travelFeeNote != null) 'travelFeeNote': travelFeeNote,
          }),
        ));
    _check(res);
  }

  Future<Map<String, dynamic>> getAdminDashboard() async {
    final res = await _client.get(_uri('/api/admin/dashboard'), headers: _jsonHeaders);
    _check(res);
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAdminProviders() async {
    final res = await _client.get(_uri('/api/admin/providers'), headers: _jsonHeaders);
    _check(res);
    return (jsonDecode(res.body)['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAdminBookings() async {
    final res = await _client.get(_uri('/api/admin/bookings'), headers: _jsonHeaders);
    _check(res);
    return (jsonDecode(res.body)['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAdminPayouts() async {
    final res = await _client.get(_uri('/api/admin/payouts'), headers: _jsonHeaders);
    _check(res);
    return (jsonDecode(res.body)['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> updateProviderStatus(int id, String status) async {
    final res = await _client.patch(_uri('/api/admin/providers/$id/status'), headers: _jsonHeaders, body: jsonEncode({'status': status}));
    _check(res);
  }

  Future<void> approvePayout(int id, {String status = 'approved'}) async {
    final res = await _client.patch(_uri('/api/admin/payouts/$id'), headers: _jsonHeaders, body: jsonEncode({'status': status}));
    _check(res);
  }

  Future<List<ProviderModel>> getProviders({bool featured = false, String? category}) async {
    final query = <String, String>{};
    if (featured) query['featured'] = 'true';
    if (category != null && category != 'All') query['category'] = category;

    final res = await _client.get(_uri('/api/providers', query.isEmpty ? null : query));
    _check(res);
    final list = (jsonDecode(res.body)['data'] as List<dynamic>);
    return list.map((e) => ProviderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProviderModel> getProvider(int id) async {
    final res = await _client.get(_uri('/api/providers/$id'));
    _check(res);
    return ProviderModel.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<UserModel> getUser([int id = ApiConfig.defaultUserId]) async {
    final res = await _client.get(_uri('/api/users/$id'));
    _check(res);
    return UserModel.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<List<BookingModel>> getBookings({int userId = ApiConfig.defaultUserId, String? status}) async {
    final query = <String, String>{'userId': '$userId'};
    if (status != null) query['status'] = status;

    final res = await _client.get(_uri('/api/bookings', query));
    _check(res);
    final list = jsonDecode(res.body)['data'] as List<dynamic>;
    return list.map((e) => BookingModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CreateBookingResult> createBooking({
    required int providerId,
    required int serviceId,
    required String scheduledAt,
    String locationType = 'home',
    String? address,
    double? destLat,
    double? destLng,
    String paymentMethod = 'cash',
    int? totalAmount,
    int userId = ApiConfig.defaultUserId,
    String? note,
  }) async {
    final res = await _client.post(
      _uri('/api/bookings'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'userId': userId,
        'providerId': providerId,
        'serviceId': serviceId,
        'scheduledAt': scheduledAt,
        'locationType': locationType,
        'address': address,
        if (destLat != null) 'destLat': destLat,
        if (destLng != null) 'destLng': destLng,
        'paymentMethod': paymentMethod,
        if (totalAmount != null) 'totalAmount': totalAmount,
        if (note != null && note.isNotEmpty) 'note': note,
      }),
    );
    _check(res);
    return CreateBookingResult.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<PaystackInitResult> initializePayment({required int amount, String email = 'adaeze@example.com'}) async {
    final res = await _client.post(
      _uri('/api/payments/initialize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'amount': amount, 'email': email}),
    );
    _check(res);
    return PaystackInitResult.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<bool> verifyPayment(String reference) async {
    final res = await _client.post(
      _uri('/api/payments/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reference': reference}),
    );
    _check(res);
    return jsonDecode(res.body)['data']['status'] == 'success';
  }

  Future<int> payWithWallet({required int amount, int userId = ApiConfig.defaultUserId}) async {
    final res = await _client.post(
      _uri('/api/payments/wallet'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'amount': amount}),
    );
    _check(res);
    return jsonDecode(res.body)['data']['newBalance'] as int;
  }

  Future<int> topUpWallet({required int amount, int userId = ApiConfig.defaultUserId, String? paystackReference}) async {
    final res = await _client.post(
      _uri('/api/wallet/topup'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'userId': userId,
        'amount': amount,
        if (paystackReference != null) 'paystackReference': paystackReference,
      }),
    );
    _check(res);
    return jsonDecode(res.body)['data']['newBalance'] as int;
  }

  Future<List<FeedPostModel>> getFeed() async {
    final res = await _client.get(_uri('/api/feed'));
    _check(res);
    final list = jsonDecode(res.body)['data'] as List<dynamic>;
    return list.map((e) => FeedPostModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FeedPostModel> createProviderPost({
    required String caption,
    String mediaType = 'image',
    String? imageUrl,
    String? videoUrl,
  }) async {
    final res = await _client.post(
      _uri('/api/provider/posts'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'caption': caption,
        'mediaType': mediaType,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (videoUrl != null) 'videoUrl': videoUrl,
      }),
    );
    _check(res);
    final raw = jsonDecode(res.body)['data'] as Map<String, dynamic>;
    return FeedPostModel.fromJson({
      'id': raw['id'],
      'imageEmoji': raw['image_emoji'] ?? '💄',
      'badge': raw['badge'] ?? '',
      'caption': raw['caption'] ?? caption,
      'likes': raw['likes'] ?? 0,
      'comments': raw['comments'] ?? 0,
      'providerName': '',
      'providerEmoji': raw['image_emoji'] ?? '💄',
      'category': raw['badge'] ?? '',
      'rating': 0,
      'area': '',
      'providerId': raw['provider_id'] ?? 0,
      'imageUrl': raw['image_url'],
      'videoUrl': raw['video_url'],
      'mediaType': raw['media_type'] ?? mediaType,
    });
  }

  Future<List<NotificationModel>> getNotifications({int userId = ApiConfig.defaultUserId}) async {
    final res = await _client.get(_uri('/api/notifications', {'userId': '$userId'}));
    _check(res);
    final list = jsonDecode(res.body)['data'] as List<dynamic>;
    return list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markAllNotificationsRead({int userId = ApiConfig.defaultUserId}) async {
    final res = await _client.post(
      _uri('/api/notifications/mark-all-read'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    _check(res);
  }

  Future<Map<String, dynamic>> getBootstrap({int userId = ApiConfig.defaultUserId, double? lat, double? lng}) async {
    final query = <String, String>{'userId': '$userId'};
    if (lat != null && lng != null) {
      query['lat'] = lat.toString();
      query['lng'] = lng.toString();
    }
    final res = await _client.get(_uri('/api/bootstrap', query), headers: _token != null ? {'Authorization': 'Bearer $_token'} : null);
    _check(res);
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final res = await _client.get(_uri('/api/admin/stats'));
    _check(res);
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<bool> cancelBooking(int bookingId) async {
    final res = await _client.post(_uri('/api/bookings/$bookingId/cancel'));
    _check(res);
    return true;
  }

  Future<ReviewModel> submitReview({required int providerId, required int rating, required String comment, int userId = ApiConfig.defaultUserId}) async {
    final res = await _client.post(
      _uri('/api/reviews'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'providerId': providerId, 'rating': rating, 'comment': comment}),
    );
    _check(res);
    return ReviewModel.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<bool> toggleSavedProvider(int providerId, {int userId = ApiConfig.defaultUserId}) async {
    final res = await _client.post(_uri('/api/users/$userId/saved-providers/$providerId'));
    _check(res);
    return jsonDecode(res.body)['data']['saved'] as bool;
  }

  Future<Map<String, dynamic>> likeFeedPost(int postId, {int userId = ApiConfig.defaultUserId}) async {
    final res = await _client.post(
      _uri('/api/feed/$postId/like'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    _check(res);
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<List<FeedCommentModel>> getFeedComments(int postId) async {
    final res = await _client.get(_uri('/api/feed/$postId/comments'));
    _check(res);
    final list = jsonDecode(res.body)['data'] as List<dynamic>;
    return list.map((e) => FeedCommentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FeedCommentModel> addFeedComment(int postId, String text, {int userId = ApiConfig.defaultUserId, String? authorName}) async {
    final res = await _client.post(
      _uri('/api/feed/$postId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'text': text, 'authorName': authorName}),
    );
    _check(res);
    return FeedCommentModel.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<List<ReviewModel>> getReviews({int? providerId}) async {
    final res = await _client.get(_uri('/api/reviews', providerId != null ? {'providerId': '$providerId'} : null));
    _check(res);
    final list = jsonDecode(res.body)['data'] as List<dynamic>;
    return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TrackingSnapshot> getTracking(int bookingId) async {
    final res = await _client.get(_uri('/api/tracking/$bookingId'));
    _check(res);
    return TrackingSnapshot.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<ProviderModel> getProviderDetail(int id) async {
    final res = await _client.get(_uri('/api/providers/$id'));
    _check(res);
    final data = jsonDecode(res.body)['data'] as Map<String, dynamic>;
    return ProviderModel.fromJson(data);
  }

  Future<void> recordProviderView(int providerId, {int userId = ApiConfig.defaultUserId}) async {
    final res = await _client.post(
      _uri('/api/providers/$providerId/view'),
      headers: _jsonHeaders,
      body: jsonEncode({'userId': userId}),
    );
    _check(res);
  }

  Future<List<ProviderModel>> getRecentlyViewed({int userId = ApiConfig.defaultUserId, double? lat, double? lng}) async {
    final query = <String, String>{'userId': '$userId'};
    if (lat != null && lng != null) {
      query['lat'] = lat.toString();
      query['lng'] = lng.toString();
    }
    final res = await _client.get(_uri('/api/providers/recently-viewed', query), headers: _jsonHeaders);
    _check(res);
    final list = jsonDecode(res.body)['data'] as List<dynamic>;
    return list.map((e) => ProviderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<WalletTransactionModel>> getWalletTransactions({int userId = ApiConfig.defaultUserId, int limit = 50}) async {
    final res = await _client.get(_uri('/api/wallet/transactions', {'userId': '$userId', 'limit': '$limit'}), headers: _jsonHeaders);
    _check(res);
    final list = jsonDecode(res.body)['data'] as List<dynamic>;
    return list.map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ConversationModel>> getConversations() async {
    final res = await _client.get(_uri('/api/messages/conversations'), headers: _jsonHeaders);
    _check(res);
    final list = jsonDecode(res.body)['data'] as List<dynamic>;
    return list.map((e) => ConversationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MessageModel>> getMessages(int bookingId) async {
    final res = await _client.get(_uri('/api/messages/$bookingId'), headers: _jsonHeaders);
    _check(res);
    final list = jsonDecode(res.body)['data'] as List<dynamic>;
    return list.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MessageModel> sendMessage({required int bookingId, required String body}) async {
    final res = await _client.post(
      _uri('/api/messages'),
      headers: _jsonHeaders,
      body: jsonEncode({'bookingId': bookingId, 'body': body}),
    );
    _check(res);
    return MessageModel.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<bool> healthCheck() async {
    try {
      final res = await _client.get(_uri('/health')).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String> getDatabaseMode() async {
    try {
      final res = await _client.get(_uri('/health')).timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return 'offline';
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['database'] as String? ?? 'unknown';
    } catch (_) {
      return 'offline';
    }
  }

  Future<http.Response> _request(Future<http.Response> Function() call) async {
    try {
      return await call().timeout(const Duration(seconds: 45));
    } on SocketException {
      throw ApiException(
        0,
        'Cannot reach Khade API at ${ApiConfig.baseUrl}. Check your internet connection.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(0, e.message);
    } on TimeoutException {
      throw ApiException(0, 'Request timed out — the server may be waking up. Try again in a moment.');
    }
  }

  void _check(http.Response res) {
    if (res.statusCode >= 400) {
      final body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
      throw ApiException(res.statusCode, body is Map ? body['error']?.toString() ?? res.reasonPhrase : res.reasonPhrase);
    }
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String? message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

final khadeApi = KhadeApi();
