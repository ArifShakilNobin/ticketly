import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_response.dart';
import '../models/notification.dart';
import '../models/offer.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/notification_service.dart';
import '../services/search_service.dart';
import '../services/voice_service.dart';

/// Where the passenger is in the sign-in flow.
enum SessionStatus {
  /// The stored token has not been checked yet.
  unknown,
  authenticated,
  unauthenticated,
}

/// Application-wide state: the session, the offers strip and the unread
/// notification count.
class AppState extends ChangeNotifier {
  AppState({
    required this.api,
    required this.authService,
    required this.searchService,
    required this.bookingService,
    required this.notificationService,
  });

  static const String _tokenKey = 'auth_token';
  static const String _readNotificationsKey = 'read_notification_ids';

  final ApiClient api;
  final AuthService authService;
  final SearchService searchService;
  final BookingService bookingService;
  final NotificationService notificationService;

  VoiceService? _voice;
  SharedPreferences? _prefs;
  bool _bootstrapping = false;

  SessionStatus status = SessionStatus.unknown;
  User? user;
  String? token;

  List<Offer> offers = const <Offer>[];
  bool offersLoading = false;
  String? offersError;

  List<AppNotification> notifications = const <AppNotification>[];
  bool notificationsLoading = false;
  String? notificationsError;

  final Set<String> _readNotificationIds = <String>{};

  /// Lazily created so the platform recorder only starts when it is used.
  VoiceService get voiceService => _voice ??= VoiceService();

  /// How many notifications the passenger has not seen yet.
  int get unreadCount => notifications
      .where((item) => !item.isRead && !_readNotificationIds.contains(item.id))
      .length;

  /// Restores a cached session. Safe to call more than once; a failed run can
  /// be retried because the status stays `unknown`.
  Future<void> bootstrap() async {
    if (status != SessionStatus.unknown || _bootstrapping) return;
    _bootstrapping = true;
    try {
      await _restoreSession();
    } finally {
      _bootstrapping = false;
    }
  }

  Future<void> _restoreSession() async {
    final prefs = await _ensurePrefs();
    _readNotificationIds.addAll(
      prefs.getStringList(_readNotificationsKey) ?? const <String>[],
    );

    final stored = prefs.getString(_tokenKey);
    if (stored == null || stored.isEmpty) {
      status = SessionStatus.unauthenticated;
      notifyListeners();
      return;
    }

    token = stored;
    api.authToken = stored;
    try {
      user = await authService.me();
      status = SessionStatus.authenticated;
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        await _clearSession(prefs);
        status = SessionStatus.unauthenticated;
      } else {
        // The server could not be reached: keep the token so the app stays
        // usable as soon as the connection comes back.
        status = SessionStatus.authenticated;
      }
    } catch (_) {
      status = SessionStatus.authenticated;
    }
    notifyListeners();

    if (status == SessionStatus.authenticated) {
      unawaited(refreshOffers());
      unawaited(refreshNotifications());
    }
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final response = await authService.login(
      identifier: identifier,
      password: password,
    );
    await _adopt(response);
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final response = await authService.register(
      name: name,
      phone: phone,
      email: email,
      password: password,
    );
    await _adopt(response);
  }

  Future<void> logout() async {
    final prefs = await _ensurePrefs();
    await _clearSession(prefs);
    offers = const <Offer>[];
    notifications = const <AppNotification>[];
    _readNotificationIds.clear();
    status = SessionStatus.unauthenticated;
    notifyListeners();
  }

  /// Refreshes `GET /api/v1/offers`.
  Future<void> refreshOffers() async {
    offersLoading = true;
    offersError = null;
    notifyListeners();
    try {
      final items = await searchService.offers();
      offers = items.where((offer) => offer.active).toList();
    } on ApiException catch (error) {
      offersError = error.message;
    } catch (_) {
      offersError = 'অফারগুলো আনা যায়নি, পরে আবার চেষ্টা করুন।';
    } finally {
      offersLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes `GET /api/v1/notifications`.
  Future<void> refreshNotifications() async {
    notificationsLoading = true;
    notificationsError = null;
    notifyListeners();
    try {
      notifications = await notificationService.list();
    } on ApiException catch (error) {
      notificationsError = error.message;
    } catch (_) {
      notificationsError = 'নোটিফিকেশন আনা যায়নি, পরে আবার চেষ্টা করুন।';
    } finally {
      notificationsLoading = false;
      notifyListeners();
    }
  }

  /// Marks every notification currently loaded as read, locally.
  Future<void> markNotificationsRead() async {
    var changed = false;
    for (final item in notifications) {
      if (_readNotificationIds.add(item.id)) changed = true;
    }
    if (!changed) return;
    final prefs = await _ensurePrefs();
    await prefs.setStringList(
      _readNotificationsKey,
      _readNotificationIds.toList(),
    );
    notifyListeners();
  }

  Future<void> _adopt(AuthResponse response) async {
    final prefs = await _ensurePrefs();
    token = response.token;
    api.authToken = response.token;
    user = response.user;
    status = SessionStatus.authenticated;
    await prefs.setString(_tokenKey, response.token);
    notifyListeners();
    unawaited(refreshOffers());
    unawaited(refreshNotifications());
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    token = null;
    api.authToken = null;
    user = null;
    await prefs.remove(_tokenKey);
  }

  Future<SharedPreferences> _ensurePrefs() async {
    final cached = _prefs;
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs;
  }

  @override
  void dispose() {
    _voice?.dispose();
    api.close();
    super.dispose();
  }
}
