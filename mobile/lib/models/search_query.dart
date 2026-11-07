import '../utils/json_read.dart';
import 'enums.dart';

/// Everything needed to call `POST /api/v1/search`.
class SearchQuery {
  const SearchQuery({
    required this.source,
    required this.destination,
    required this.travelDate,
    required this.transportType,
    required this.priority,
    this.budgetLimit,
    this.sessionId,
  });

  final String source;
  final String destination;
  final DateTime travelDate;
  final TransportType transportType;
  final SearchPriority priority;
  final double? budgetLimit;
  final String? sessionId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'source': source,
        'destination': destination,
        'travelDate': apiDate(travelDate),
        'transportType': transportType.wire,
        'priority': priority.wire,
        if (budgetLimit != null) 'budgetLimit': budgetLimit,
        if (sessionId != null) 'sessionId': sessionId,
      };
}
