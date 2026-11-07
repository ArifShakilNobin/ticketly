import '../utils/json_read.dart';
import 'enums.dart';
import 'optimized_fare.dart';

/// Response of `POST /api/v1/search`.
class SearchResponse {
  const SearchResponse({
    required this.searchId,
    required this.source,
    required this.destination,
    this.travelDate,
    required this.transportType,
    this.items = const <OptimizedFare>[],
    this.cached = false,
    this.totalFound = 0,
    this.generatedAt,
  });

  final String searchId;
  final String source;
  final String destination;
  final DateTime? travelDate;
  final TransportType transportType;
  final List<OptimizedFare> items;
  final bool cached;
  final int totalFound;
  final DateTime? generatedAt;

  factory SearchResponse.fromJson(Map<String, dynamic>? json) {
    final data = asMap(json);
    final rawItems = asList(data['items']);
    final items = <OptimizedFare>[];
    for (final raw in rawItems) {
      if (raw is Map) {
        items.add(OptimizedFare.fromJson(asMap(raw)));
      }
    }
    return SearchResponse(
      searchId: stringOr(data['searchId'], ''),
      source: stringOr(data['source'], ''),
      destination: stringOr(data['destination'], ''),
      travelDate: dateOrNull(data['travelDate']),
      transportType:
          TransportType.fromWire(data['transportType'] as String?),
      items: items,
      cached: boolOr(data['cached'], false),
      totalFound: intOr(data['totalFound'], items.length),
      generatedAt: dateOrNull(data['generatedAt']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'searchId': searchId,
        'source': source,
        'destination': destination,
        'travelDate': travelDate == null ? null : apiDate(travelDate!),
        'transportType': transportType.wire,
        'items': items.map((item) => item.toJson()).toList(),
        'cached': cached,
        'totalFound': totalFound,
        if (generatedAt != null) 'generatedAt': generatedAt!.toIso8601String(),
      };
}
