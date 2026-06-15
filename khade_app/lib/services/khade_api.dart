import 'dart:convert';
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
    final res = await _client.post(_uri('/api/auth/login'), headers: _jsonHeaders, body: jsonEncode({'email': email, 'password': password}));
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
    String? cacNumber,
    String visitTypes = 'both',
    String area = 'Wuse II',
  }) async {
    final res = await _client.post(
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
        if (cacNumber != null) 'cacNumber': cacNumber,
        'visitTypes': visitTypes,
        'area': area,
      }),
    );
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

  Future<void> completeBooking(int bookingId) async {
    final res = await _client.patch(
      _uri('/api/provider/bookings/$bookingId/status'),
      headers: _jsonHeaders,
      body: jsonEncode({'status': 'completed'}),
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
    String area = 'Wuse II',
    String? bio,
  }) async {
    final res = await _client.post(
      _uri('/api/provider/onboard'),
      headers: _jsonHeaders,
      body: jsonEncode({'categorySlug': categorySlug, 'services': services, 'visitTypes': visitTypes, 'area': area, 'bio': bio}),
    );
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
    String paymentMethod = 'paystack',
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

  Future<int> topUpWallet({required int amount, int userId = ApiConfig.defaultUserId}) async {
    final res = await _client.post(
      _uri('/api/wallet/topup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'amount': amount}),
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

  Future<SyncSnapshot> getSyncSnapshot({int? userId, String? since}) async {
    final query = <String, String>{'userId': '${userId ?? this.userId}'};
    if (since != null) query['since'] = since;
    final res = await _client.get(_uri('/api/sync/snapshot', query), headers: _jsonHeaders);
    _check(res);
    return SyncSnapshot.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<List<ChatMessageModel>> getBookingMessages(int bookingId) async {
    final res = await _client.get(_uri('/api/bookings/$bookingId/messages'), headers: _jsonHeaders);
    _check(res);
    return (jsonDecode(res.body)['data'] as List).map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ChatMessageModel> sendBookingMessage({
    required int bookingId,
    required String body,
    int? userId,
    String? senderName,
  }) async {
    final res = await _client.post(
      _uri('/api/bookings/$bookingId/messages'),
      headers: _jsonHeaders,
      body: jsonEncode({'body': body, if (userId != null) 'userId': userId, if (senderName != null) 'senderName': senderName}),
    );
    _check(res);
    return ChatMessageModel.fromJson(jsonDecode(res.body)['data'] as Map<String, dynamic>);
  }

  Future<void> uploadProviderLocation({required double lat, required double lng}) async {
    final res = await _client.post(
      _uri('/api/provider/location'),
      headers: _jsonHeaders,
      body: jsonEncode({'lat': lat, 'lng': lng}),
    );
    _check(res);
  }

  Future<Map<String, dynamic>> createGroupBooking({
    required String title,
    required int guestCount,
    required int providerId,
    required int serviceId,
    String? address,
    String? scheduledAt,
    String? note,
    int? userId,
  }) async {
    final res = await _client.post(
      _uri('/api/groups'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'title': title,
        'guestCount': guestCount,
        'providerId': providerId,
        'serviceId': serviceId,
        if (address != null) 'address': address,
        if (scheduledAt != null) 'scheduledAt': scheduledAt,
        if (note != null) 'note': note,
        if (userId != null) 'userId': userId,
      }),
    );
    _check(res);
    return jsonDecode(res.body)['data'] as Map<String, dynamic>;
  }

  Future<void> registerFcmToken({required int userId, required String token, String platform = 'android'}) async {
    final res = await _client.post(
      _uri('/api/devices/fcm-token'),
      headers: _jsonHeaders,
      body: jsonEncode({'userId': userId, 'token': token, 'platform': platform}),
    );
    _check(res);
  }

  Future<List<Map<String, dynamic>>> getCrmClients() async {
    final res = await _client.get(_uri('/api/provider/crm/clients'), headers: _jsonHeaders);
    _check(res);
    return (jsonDecode(res.body)['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> addCrmClient({required String name, String? phone, String? notes}) async {
    final res = await _client.post(
      _uri('/api/provider/crm/clients'),
      headers: _jsonHeaders,
      body: jsonEncode({'name': name, if (phone != null) 'phone': phone, if (notes != null) 'notes': notes}),
    );
    _check(res);
  }

  Future<List<Map<String, dynamic>>> getProviderStaff() async {
    final res = await _client.get(_uri('/api/provider/staff'), headers: _jsonHeaders);
    _check(res);
    return (jsonDecode(res.body)['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> addProviderStaff({required String name, required String role, String? phone}) async {
    final res = await _client.post(
      _uri('/api/provider/staff'),
      headers: _jsonHeaders,
      body: jsonEncode({'name': name, 'role': role, if (phone != null) 'phone': phone}),
    );
    _check(res);
  }

  Future<List<Map<String, dynamic>>> getProviderInventory() async {
    final res = await _client.get(_uri('/api/provider/inventory'), headers: _jsonHeaders);
    _check(res);
    return (jsonDecode(res.body)['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> addInventoryItem({required String name, int quantity = 0, int reorderLevel = 5}) async {
    final res = await _client.post(
      _uri('/api/provider/inventory'),
      headers: _jsonHeaders,
      body: jsonEncode({'name': name, 'quantity': quantity, 'reorderLevel': reorderLevel}),
    );
    _check(res);
  }

  Future<Map<String, dynamic>> sendCampaign({required String title, required String message, String channel = 'sms'}) async {
    final res = await _client.post(
      _uri('/api/provider/campaigns'),
      headers: _jsonHeaders,
      body: jsonEncode({'title': title, 'message': message, 'channel': channel}),
    );
    _check(res);
    final body = jsonDecode(res.body);
    return {'campaign': body['data'], 'recipients': (body['meta'] as Map?)?['recipients'] ?? 0};
  }

  Future<void> applyCapitalLoan({required int amount, String? purpose}) async {
    final res = await _client.post(
      _uri('/api/provider/capital/apply'),
      headers: _jsonHeaders,
      body: jsonEncode({'amount': amount, if (purpose != null) 'purpose': purpose}),
    );
    _check(res);
  }

  Future<List<Map<String, dynamic>>> getCapitalLoans() async {
    final res = await _client.get(_uri('/api/provider/capital'), headers: _jsonHeaders);
    _check(res);
    return (jsonDecode(res.body)['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<bool> healthCheck() async {
    try {
      final res = await _client.get(_uri('/health')).timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
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
