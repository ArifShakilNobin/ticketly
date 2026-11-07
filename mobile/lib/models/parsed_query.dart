import '../utils/json_read.dart';
import 'enums.dart';

/// Result of `POST /api/v1/nlp/parse`, for both typed and spoken input.
class ParsedQuery {
  const ParsedQuery({
    this.sessionId,
    this.text,
    this.transcript,
    this.intent = TicketIntent.unknown,
    this.source,
    this.destination,
    this.transportType = TransportType.all,
    this.travelDate,
    this.budgetLimit,
    this.priority = SearchPriority.balanced,
    this.confidence = 0,
    this.detectedTerms = const <String>[],
  });

  final String? sessionId;

  /// The normalised query text (filled in by the backend for audio input).
  final String? text;

  /// What the speech-to-text layer heard.
  final String? transcript;
  final TicketIntent intent;
  final String? source;
  final String? destination;
  final TransportType transportType;
  final DateTime? travelDate;
  final double? budgetLimit;
  final SearchPriority priority;
  final double confidence;
  final List<String> detectedTerms;

  factory ParsedQuery.fromJson(Map<String, dynamic>? json) {
    final data = asMap(json);
    return ParsedQuery(
      sessionId: stringOrNull(data['sessionId']),
      text: stringOrNull(data['text']),
      transcript: stringOrNull(data['transcript']),
      intent: TicketIntent.fromWire(data['intent'] as String?),
      source: stringOrNull(data['source']),
      destination: stringOrNull(data['destination']),
      transportType: TransportType.fromWire(data['transportType'] as String?),
      travelDate: dateOrNull(data['travelDate']),
      budgetLimit: doubleOrNull(data['budgetLimit']),
      priority: SearchPriority.fromWire(data['priority'] as String?),
      confidence: doubleOr(data['confidence'], 0),
      detectedTerms: stringList(data['detectedTerms']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'sessionId': sessionId,
        'text': text,
        'transcript': transcript,
        'intent': intent.wire,
        'source': source,
        'destination': destination,
        'transportType': transportType.wire,
        'travelDate': travelDate == null ? null : apiDate(travelDate!),
        'budgetLimit': budgetLimit,
        'priority': priority.wire,
        'confidence': confidence,
        'detectedTerms': detectedTerms,
      };
}
