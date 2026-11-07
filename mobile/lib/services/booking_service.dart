import '../models/booking.dart';
import '../models/fare_item.dart';
import '../utils/json_read.dart';
import 'api_client.dart';

/// `/api/v1/bookings` calls.
class BookingService {
  BookingService(this._api);

  final ApiClient _api;

  Future<Booking> create({
    required String searchId,
    required FareItem fare,
    required String passengerName,
    required String passengerPhone,
    required int quantity,
    required String paymentMethod,
    String? mfsProvider,
    String? cardLast4,
    String? promoCode,
  }) async {
    final body = await _api.post(
      '/api/v1/bookings',
      body: <String, dynamic>{
        'searchId': searchId,
        'fare': fare.toJson(),
        'passengerName': passengerName.trim(),
        'passengerPhone': passengerPhone.trim(),
        'quantity': quantity,
        'paymentMethod': paymentMethod,
        if (mfsProvider != null && mfsProvider.isNotEmpty)
          'mfsProvider': mfsProvider,
        if (cardLast4 != null && cardLast4.trim().isNotEmpty)
          'cardLast4': cardLast4.trim(),
        if (promoCode != null && promoCode.trim().isNotEmpty)
          'promoCode': promoCode.trim(),
      },
    );
    return Booking.fromJson(asMap(body));
  }

  Future<List<Booking>> list() async {
    final body = await _api.get('/api/v1/bookings');
    final items = <Booking>[];
    for (final raw in asList(body)) {
      if (raw is Map) items.add(Booking.fromJson(asMap(raw)));
    }
    return items;
  }

  Future<Booking> get(String id) async {
    final body = await _api.get('/api/v1/bookings/$id');
    return Booking.fromJson(asMap(body));
  }

  Future<Booking> cancel(String id, {required String reason}) async {
    final body = await _api.post(
      '/api/v1/bookings/$id/cancel',
      body: <String, dynamic>{'reason': reason.trim()},
    );
    return Booking.fromJson(asMap(body));
  }
}
