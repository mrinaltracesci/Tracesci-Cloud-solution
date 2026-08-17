import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../../core/utils/json_utils.dart';
import '../models/case_models.dart';

class SeizeResult {
  final int affected;
  final String message;

  const SeizeResult({required this.affected, required this.message});
}

class InspectorRepository {
  final ApiClient client;

  const InspectorRepository(this.client);

  Future<InspectorDashboard> dashboard() async {
    final response = await client.post(ApiEndpoints.inspectorDashboard);
    return InspectorDashboard.fromJson(response.data);
  }

  Future<Paged<CaseCard>> cases({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
    String? search,
  }) async {
    final response = await client.post(
      ApiEndpoints.inspectorCases,
      body: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (type != null) 'type': type,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    return Paged<CaseCard>(
      items: response.list('cases').map(CaseCard.fromJson).toList(),
      meta: response.meta,
    );
  }

  Future<CaseDetail> caseDetail(int id) async {
    final response = await client.post(ApiEndpoints.inspectorCase(id));
    return CaseDetail.fromJson(response.data);
  }

  Future<String> updateCase({
    required int id,
    required String status,
    required String comments,
  }) async {
    final response = await client.post(
      ApiEndpoints.inspectorCaseUpdate(id),
      body: {'status': status, 'comments': comments},
    );

    return response.message;
  }

  Future<SeizeResult> seize({
    required String type,
    required String code,
  }) async {
    final response = await client.post(
      ApiEndpoints.inspectorSeize,
      body: {'type': type, 'code': code},
    );

    return SeizeResult(
      affected: asInt(response.data['affected']),
      message: response.message,
    );
  }

  Future<List<MapPoint>> map({String? status}) async {
    final response = await client.post(
      ApiEndpoints.inspectorMap,
      body: {if (status != null) 'status': status},
    );

    return response.list('points').map(MapPoint.fromJson).toList();
  }
}
