import '../utils/json_read.dart';
import 'fare_item.dart';
import 'price_breakdown.dart';

/// A fare together with its optimised price and the offers applied to it.
class OptimizedFare {
  const OptimizedFare({
    required this.fare,
    required this.price,
    this.appliedOffers = const <String>[],
    this.badge,
  });

  final FareItem fare;
  final PriceBreakdown price;
  final List<String> appliedOffers;
  final String? badge;

  factory OptimizedFare.fromJson(Map<String, dynamic>? json) {
    final data = asMap(json);
    return OptimizedFare(
      fare: FareItem.fromJson(asMap(data['fare'])),
      price: PriceBreakdown.fromJson(asMap(data['price'])),
      appliedOffers: stringList(data['appliedOffers']),
      badge: stringOrNull(data['badge']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fare': fare.toJson(),
        'price': price.toJson(),
        'appliedOffers': appliedOffers,
        'badge': badge,
      };
}
