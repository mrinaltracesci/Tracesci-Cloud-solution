import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../../core/utils/json_utils.dart';
import '../models/alert_item.dart';

class AlertRepository {
  final ApiClient client;

  const AlertRepository(this.client);

  Future<(Paged<AlertItem>, AlertFeed)> feed({
    int page = 1,
    int limit = 20,
    String? scope,
    String? status,
  }) async {
    final response = await client.post(
      ApiEndpoints.alertsFeed,
      body: {
        'page': page,
        'limit': limit,
        if (scope != null) 'scope': scope,
        if (status != null) 'status': status,
      },
    );

    final items = response.list('alerts').map(AlertItem.fromJson).toList();
    final counts = asMap(response.data['counts']);

    return (
      Paged<AlertItem>(items: items, meta: response.meta),
      AlertFeed(
        alerts: items,
        canSeeProducts: asBool(response.data['can_see_products']),
        mineCount: asInt(counts['mine']),
        productCount: asInt(counts['products']),
      ),
    );
  }
}
