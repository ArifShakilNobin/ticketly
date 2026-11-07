import '../utils/json_read.dart';
import 'enums.dart';

/// A single journey option as offered by a transport provider.
class FareItem {
  const FareItem({
    required this.id,
    required this.provider,
    this.providerRef,
    required this.transportType,
    required this.source,
    required this.destination,
    this.travelDate,
    this.departTime,
    this.arriveTime,
    this.durationMins = 0,
    required this.baseFare,
    this.currency = 'BDT',
    this.seatsAvailable = 0,
    this.vehicleClass,
    this.cancellationPolicy,
    this.meta = const <String, String>{},
  });

  final String id;
  final String provider;
  final String? providerRef;
  final TransportType transportType;
  final String source;
  final String destination;
  final DateTime? travelDate;

  /// Normalised `HH:mm` departure time.
  final String? departTime;

  /// Normalised `HH:mm` arrival time.
  final String? arriveTime;

  final int durationMins;
  final double baseFare;
  final String currency;
  final int seatsAvailable;
  final String? vehicleClass;
  final String? cancellationPolicy;
  final Map<String, String> meta;

  factory FareItem.fromJson(Map<String, dynamic>? json) {
    final data = asMap(json);
    return FareItem(
      id: stringOr(data['id'], ''),
      provider: stringOr(data['provider'], ''),
      providerRef: stringOrNull(data['providerRef']),
      transportType: TransportType.fromWire(data['transportType'] as String?),
      source: stringOr(data['source'], ''),
      destination: stringOr(data['destination'], ''),
      travelDate: dateOrNull(data['travelDate']),
      departTime: timeOrNull(data['departTime']),
      arriveTime: timeOrNull(data['arriveTime']),
      durationMins: intOr(data['durationMins'], 0),
      baseFare: doubleOr(data['baseFare'], 0),
      currency: stringOr(data['currency'], 'BDT'),
      seatsAvailable: intOr(data['seatsAvailable'], 0),
      vehicleClass: stringOrNull(data['vehicleClass']),
      cancellationPolicy: stringOrNull(data['cancellationPolicy']),
      meta: _stringMap(data['meta']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'provider': provider,
        'providerRef': providerRef,
        'transportType': transportType.wire,
        'source': source,
        'destination': destination,
        'travelDate': travelDate == null ? null : apiDate(travelDate!),
        'departTime': departTime,
        'arriveTime': arriveTime,
        'durationMins': durationMins,
        'baseFare': baseFare,
        'currency': currency,
        'seatsAvailable': seatsAvailable,
        'vehicleClass': vehicleClass,
        'cancellationPolicy': cancellationPolicy,
        'meta': meta,
      };

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) return <String, String>{};
    final result = <String, String>{};
    value.forEach((dynamic key, dynamic item) {
      if (item != null) result[key.toString()] = item.toString();
    });
    return result;
  }
}
