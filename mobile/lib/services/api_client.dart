import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/json_read.dart';

/// Error surfaced by the Ticketly backend.
///
/// The backend always answers with `{status, code, message, details,
/// timestamp}`; [details] maps a field name to its validation message.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.status,
    this.code,
    this.details = const <String, String>{},
  });

  /// Creates an error for a request that never reached the backend.
  const ApiException.network(String message)
      : this(message: message, status: null, code: 'network_error');

  final int? status;
  final String? code;
  final String message;
  final Map<String, String> details;

  bool get isUnauthorized => status == 401;

  bool get isNetworkError => status == null;

  /// Validation message attached to [field], if the backend sent one.
  String? detailFor(String field) => details[field];

  @override
  String toString() => message;
}

/// Fallback copy for a given HTTP status when the backend did not send a
/// `message` we could read.
String _fallbackMessage(int status) {
  switch (status) {
    case 400:
      return 'তথ্যগুলো সঠিকভাবে পাঠানো হয়নি।';
    case 401:
      return 'লগইন সেশনের মেয়াদ শেষ হয়েছে, আবার লগইন করুন।';
    case 403:
      return 'এই কাজের অনুমতি আপনার নেই।';
    case 404:
      return 'অনুরোধ করা তথ্য পাওয়া যায়নি।';
    case 409:
      return 'এই অনুরোধটি ইতিমধ্যে সম্পন্ন হয়েছে।';
    case 429:
      return 'অনেকবার চেষ্টা করা হয়েছে, একটু পরে আবার চেষ্টা করুন।';
    default:
      if (status >= 500) {
        return 'সার্ভারে সাময়িক সমস্যা হচ্ছে, পরে আবার চেষ্টা করুন।';
      }
      return 'অনুরোধটি সফল হয়নি (HTTP $status)।';
  }
}

/// Turns an error response body into an [ApiException].
ApiException _errorFromResponse(int status, Object? decoded) {
  if (decoded is Map) {
    final data = asMap(decoded);
    final details = <String, String>{};
    final rawDetails = data['details'];
    if (rawDetails is Map) {
      rawDetails.forEach((dynamic key, dynamic value) {
        if (value != null) details[key.toString()] = value.toString();
      });
    }
    return ApiException(
      status: status,
      code: stringOrNull(data['code']),
      message: stringOrNull(data['message']) ?? _fallbackMessage(status),
      details: details,
    );
  }
  return ApiException(status: status, message: _fallbackMessage(status));
}

/// Decodes a body; anything that is not valid JSON becomes `null` so the
/// individual models can apply their own defaults.
dynamic _decodeBody(String body) {
  if (body.trim().isEmpty) return null;
  try {
    return jsonDecode(body);
  } on FormatException {
    return null;
  }
}

/// Minimal HTTP wrapper that injects the bearer token, maps backend errors to
/// [ApiException] and keeps a malformed response from ever escaping as an
/// unhandled exception.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// Current bearer token; set by the auth flow after a successful sign-in.
  String? authToken;

  Future<dynamic> get(String path) => _send('GET', path, null);

  Future<dynamic> post(String path, {Object? body}) => _send('POST', path, body);

  Future<dynamic> _send(String method, String path, Object? body) async {
    final token = authToken;
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    http.Response response;
    try {
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 30));
      response = await http.Response.fromStream(streamed);
    } catch (error) {
      throw ApiException.network(
        'ইন্টারনেট সংযোগ নেই অথবা সার্ভারে পৌঁছানো যায়নি। ($error)',
      );
    }

    final decoded = _decodeBody(response.body);
    if (response.statusCode >= 400) {
      throw _errorFromResponse(response.statusCode, decoded);
    }
    return decoded;
  }

  /// Releases the underlying HTTP connection pool.
  void close() => _client.close();
}

/// A single, user facing message for any error thrown by the services.
String errorMessageOf(Object error) {
  if (error is ApiException) return error.message;
  return 'একটি অপ্রত্যাশিত সমস্যা হয়েছে, আবার চেষ্টা করুন।';
}
