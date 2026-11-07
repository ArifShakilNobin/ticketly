import '../models/offer.dart';
import '../models/parsed_query.dart';
import '../models/search_query.dart';
import '../models/search_response.dart';
import '../utils/json_read.dart';
import 'api_client.dart';

/// `/api/v1/nlp`, `/api/v1/search` and `/api/v1/offers` calls.
class SearchService {
  SearchService(this._api);

  final ApiClient _api;

  /// Parses typed or spoken input into a structured query.
  Future<ParsedQuery> parse({
    String? text,
    String? audioBase64,
    String? contentType,
    String? sessionId,
  }) async {
    final body = await _api.post(
      '/api/v1/nlp/parse',
      body: <String, dynamic>{
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
        if (audioBase64 != null && audioBase64.isNotEmpty)
          'audioBase64': audioBase64,
        if (contentType != null && contentType.isNotEmpty)
          'contentType': contentType,
        if (sessionId != null && sessionId.isNotEmpty)
          'sessionId': sessionId,
      },
    );
    return ParsedQuery.fromJson(asMap(body));
  }

  Future<SearchResponse> search(SearchQuery query) async {
    final body = await _api.post('/api/v1/search', body: query.toJson());
    return SearchResponse.fromJson(asMap(body));
  }

  Future<List<Offer>> offers() async {
    final body = await _api.get('/api/v1/offers');
    final items = <Offer>[];
    for (final raw in asList(body)) {
      if (raw is Map) items.add(Offer.fromJson(asMap(raw)));
    }
    return items;
  }
}
