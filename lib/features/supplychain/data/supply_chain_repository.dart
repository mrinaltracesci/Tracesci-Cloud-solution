import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../consumer/models/consumer_models.dart';
import '../models/supply_chain_models.dart';

class SupplyChainRepository {
  final ApiClient client;

  const SupplyChainRepository(this.client);

  Future<SupplyChainDashboard> dashboard() async {
    final response = await client.post(ApiEndpoints.supplyChainDashboard);
    return SupplyChainDashboard.fromJson(response.data);
  }

  Future<Paged<ConsignmentCard>> consignments({
    String status = 'all',
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await client.post(
      ApiEndpoints.supplyChainConsignments,
      body: {
        'status': status,
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    return Paged<ConsignmentCard>(
      items:
          response.list('consignments').map(ConsignmentCard.fromJson).toList(),
      meta: response.meta,
    );
  }

  Future<ConsignmentDetail> consignment(String uniqueId) async {
    final response = await client.post(
      ApiEndpoints.supplyChainConsignment(uniqueId),
    );
    return ConsignmentDetail.fromJson(response.data);
  }

  Future<List<JourneyStep>> timeline(String uniqueId) async {
    final response = await client.post(
      ApiEndpoints.supplyChainTimeline(uniqueId),
    );
    return response.list('timeline').map(JourneyStep.fromJson).toList();
  }

  Future<List<Counterparty>> counterparties() async {
    final response = await client.post(ApiEndpoints.supplyChainCounterparties);
    return response.list('users').map(Counterparty.fromJson).toList();
  }

  Future<List<ChainStatusOption>> statuses() async {
    final response = await client.post(ApiEndpoints.supplyChainStatuses);
    return response.list('statuses').map(ChainStatusOption.fromJson).toList();
  }

  Future<Paged<ChainAlert>> alerts({int page = 1, int limit = 20}) async {
    final response = await client.post(
      ApiEndpoints.supplyChainAlerts,
      body: {'page': page, 'limit': limit},
    );

    return Paged<ChainAlert>(
      items: response.list('alerts').map(ChainAlert.fromJson).toList(),
      meta: response.meta,
    );
  }

  Future<Paged<ChainActivity>> activity({int page = 1, int limit = 20}) async {
    final response = await client.post(
      ApiEndpoints.supplyChainActivity,
      body: {'page': page, 'limit': limit},
    );

    return Paged<ChainActivity>(
      items: response.list('activity').map(ChainActivity.fromJson).toList(),
      meta: response.meta,
    );
  }

  Future<SupplyChainScanResult> scan({
    required String code,
    Map<String, dynamic>? location,
  }) async {
    final response = await client.post(
      ApiEndpoints.supplyChainScan,
      body: {
        'code': code,
        if (location != null) 'location': location,
      },
    );

    return SupplyChainScanResult.fromJson(response.data);
  }

  Future<String> performAction({
    required int scanId,
    required String action,
    int? user,
    String? comment,
    String? status,
  }) async {
    final response = await client.post(
      ApiEndpoints.supplyChainAction,
      body: {
        'scan_id': scanId,
        'action': action,
        if (user != null) 'user': user,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );

    return response.message;
  }
}
