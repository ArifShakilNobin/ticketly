import '../utils/format.dart';
import '../utils/json_read.dart';

/// A cashback or promo offer from `GET /api/v1/offers`.
class Offer {
  const Offer({
    required this.id,
    required this.title,
    this.provider,
    this.cashbackType,
    this.cashbackPercent,
    this.cashbackAmount,
    this.maxCashback,
    this.minFare,
    this.paymentMethods = const <String>[],
    this.validFrom,
    this.validTo,
    this.active = true,
  });

  final String id;
  final String title;
  final String? provider;
  final String? cashbackType;
  final double? cashbackPercent;
  final double? cashbackAmount;
  final double? maxCashback;
  final double? minFare;
  final List<String> paymentMethods;
  final DateTime? validFrom;
  final DateTime? validTo;
  final bool active;

  factory Offer.fromJson(Map<String, dynamic>? json) {
    final data = asMap(json);
    return Offer(
      id: stringOr(data['id'], ''),
      title: stringOr(data['title'], ''),
      provider: stringOrNull(data['provider']),
      cashbackType: stringOrNull(data['cashbackType']),
      cashbackPercent: doubleOrNull(data['cashbackPercent']),
      cashbackAmount: doubleOrNull(data['cashbackAmount']),
      maxCashback: doubleOrNull(data['maxCashback']),
      minFare: doubleOrNull(data['minFare']),
      paymentMethods: stringList(data['paymentMethods']),
      validFrom: dateTimeOrNull(data['validFrom']),
      validTo: dateTimeOrNull(data['validTo']),
      active: boolOr(data['active'], true),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'provider': provider,
        'cashbackType': cashbackType,
        'cashbackPercent': cashbackPercent,
        'cashbackAmount': cashbackAmount,
        'maxCashback': maxCashback,
        'minFare': minFare,
        'paymentMethods': paymentMethods,
        if (validFrom != null) 'validFrom': validFrom!.toIso8601String(),
        if (validTo != null) 'validTo': validTo!.toIso8601String(),
        'active': active,
      };

  /// Human readable cashback value, e.g. `১০% ক্যাশব্যাক` or `৳৫০ ক্যাশব্যাক`.
  String get cashbackLabel {
    final percent = cashbackPercent;
    if (percent != null && percent > 0) {
      final cap = maxCashback;
      if (cap != null && cap > 0) {
        return '${formatNumber(percent)}% ক্যাশব্যাক · সর্বোচ্চ ${formatBdt(cap)}';
      }
      return '${formatNumber(percent)}% ক্যাশব্যাক';
    }
    final amount = cashbackAmount;
    if (amount != null && amount > 0) return '${formatBdt(amount)} ক্যাশব্যাক';
    return title;
  }
}
