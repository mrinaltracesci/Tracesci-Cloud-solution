import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../inspector/models/case_models.dart';
import '../models/brand_models.dart';

class BrandRepository {
  final ApiClient client;

  const BrandRepository(this.client);

  Future<BrandDashboard> dashboard() async {
    final response = await client.post(ApiEndpoints.brandDashboard);
    return BrandDashboard.fromJson(response.data);
  }

  Future<Paged<BrandProduct>> products({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final response = await client.post(
      ApiEndpoints.brandProducts,
      body: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
      },
    );

    return Paged<BrandProduct>(
      items: response.list('products').map(BrandProduct.fromJson).toList(),
      meta: response.meta,
    );
  }

  Future<BrandProductDetail> product(int id) async {
    final response = await client.post(ApiEndpoints.brandProduct(id));
    return BrandProductDetail.fromJson(response.data);
  }

  Future<Paged<BrandScan>> scans({
    int page = 1,
    int limit = 20,
    int? productId,
    String? genuine,
  }) async {
    final response = await client.post(
      ApiEndpoints.brandScans,
      body: {
        'page': page,
        'limit': limit,
        if (productId != null) 'product_id': productId,
        if (genuine != null) 'genuine': genuine,
      },
    );

    return Paged<BrandScan>(
      items: response.list('scans').map(BrandScan.fromJson).toList(),
      meta: response.meta,
    );
  }

  Future<Paged<BrandAlert>> alerts({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) async {
    final response = await client.post(
      ApiEndpoints.brandAlerts,
      body: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (type != null) 'type': type,
      },
    );

    return Paged<BrandAlert>(
      items: response.list('alerts').map(BrandAlert.fromJson).toList(),
      meta: response.meta,
    );
  }

  Future<List<NetworkNode>> network() async {
    final response = await client.post(ApiEndpoints.brandNetwork);
    return response.list('nodes').map(NetworkNode.fromJson).toList();
  }

  Future<List<MapPoint>> scanMap() async {
    final response = await client.post(ApiEndpoints.brandScanMap);
    return response.list('points').map(MapPoint.fromJson).toList();
  }
}
