import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';

class KhadeApi {
  KhadeApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

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
    String paymentMethod = 'paystack',
    int userId = ApiConfig.defaultUserId,
  }) async {
    final res = await _client.post(
      _uri('/api/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'providerId': providerId,
        'serviceId': serviceId,
        'scheduledAt': scheduledAt,
        'locationType': locationType,
        'address': address,
        'paymentMethod': paymentMethod,
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

  Future<Map<String, dynamic>> getBootstrap({int userId = ApiConfig.defaultUserId}) async {
    final res = await _client.get(_uri('/api/bootstrap', {'userId': '$userId'}));
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
