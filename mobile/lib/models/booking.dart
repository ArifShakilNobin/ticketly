import '../utils/json_read.dart';
import 'enums.dart';
import 'fare_item.dart';
import 'price_breakdown.dart';

/// A booking as returned by `/api/v1/bookings`.
class Booking {
  const Booking({
    required this.id,
    required this.pnr,
    required this.status,
    this.fare,
    this.price,
    required this.passengerName,
    required this.passengerPhone,
    this.quantity = 1,
    required this.paymentMethod,
    this.mfsProvider,
    this.transactionId,
    this.failureReason,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String pnr;
  final BookingStatus status;
  final FareItem? fare;
  final PriceBreakdown? price;
  final String passengerName;
  final String passengerPhone;
  final int quantity;
  final PaymentMethod paymentMethod;
  final String? mfsProvider;
  final String? transactionId;
  final String? failureReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Booking.fromJson(Map<String, dynamic>? json) {
    final data = asMap(json);
    final rawFare = data['fare'];
    final rawPrice = data['price'];
    return Booking(
      id: stringOr(data['id'], ''),
      pnr: stringOr(data['pnr'], ''),
      status: BookingStatus.fromWire(data['status'] as String?),
      fare: rawFare is Map ? FareItem.fromJson(asMap(rawFare)) : null,
      price: rawPrice is Map ? PriceBreakdown.fromJson(asMap(rawPrice)) : null,
      passengerName: stringOr(data['passengerName'], ''),
      passengerPhone: stringOr(data['passengerPhone'], ''),
      quantity: intOr(data['quantity'], 1),
      paymentMethod: PaymentMethod.fromWire(data['paymentMethod'] as String?),
      mfsProvider: stringOrNull(data['mfsProvider']),
      transactionId: stringOrNull(data['transactionId']),
      failureReason: stringOrNull(data['failureReason']),
      createdAt: dateTimeOrNull(data['createdAt']),
      updatedAt: dateTimeOrNull(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'pnr': pnr,
        'status': status.wire,
        'fare': fare?.toJson(),
        'price': price?.toJson(),
        'passengerName': passengerName,
        'passengerPhone': passengerPhone,
        'quantity': quantity,
        'paymentMethod': paymentMethod.wire,
        'mfsProvider': mfsProvider,
        'transactionId': transactionId,
        'failureReason': failureReason,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  bool get canBeCancelled =>
      status == BookingStatus.pending || status == BookingStatus.confirmed;

  bool get isSuccessful => status == BookingStatus.confirmed;

  /// Amount actually charged for this booking.
  double get totalPaid =>
      (price?.effectivePrice ?? price?.baseFare ?? 0) * quantity;
}
