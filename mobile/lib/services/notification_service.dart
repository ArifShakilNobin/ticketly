import '../models/notification.dart';
import '../utils/json_read.dart';
import 'api_client.dart';

/// `/api/v1/notifications` calls.
class NotificationService {
  NotificationService(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> list() async {
    final body = await _api.get('/api/v1/notifications');
    final items = <AppNotification>[];
    for (final raw in asList(body)) {
      if (raw is Map) items.add(AppNotification.fromJson(asMap(raw)));
    }
    return items;
  }
}
