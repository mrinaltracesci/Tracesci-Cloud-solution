import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../../core/utils/json_utils.dart';
import '../models/reward_models.dart';

class RewardRepository {
  final ApiClient client;

  const RewardRepository(this.client);

  Future<RewardSummary> summary() async {
    final response = await client.post(ApiEndpoints.rewardsSummary);
    return RewardSummary.fromJson(response.data);
  }

  Future<Paged<LedgerEntry>> ledger({
    int page = 1,
    int limit = 20,
    String? type,
    String? brand,
  }) async {
    final response = await client.post(
      ApiEndpoints.rewardsLedger,
      body: {
        'page': page,
        'limit': limit,
        if (type != null) 'type': type,
        if (brand != null) 'brand': brand,
      },
    );

    return Paged<LedgerEntry>(
      items: response.list('entries').map(LedgerEntry.fromJson).toList(),
      meta: response.meta,
    );
  }

  Future<List<RewardScheme>> catalog() async {
    final response = await client.post(ApiEndpoints.rewardsCatalog);
    return response.list('schemes').map(RewardScheme.fromJson).toList();
  }

  Future<RedeemResult> redeemCoupon({
    required String couponCode,
    int? scanId,
  }) async {
    final response = await client.post(
      ApiEndpoints.rewardsRedeemCoupon,
      body: {
        'coupon_code': couponCode,
        if (scanId != null) 'scan_id': scanId,
      },
    );

    return RedeemResult(
      pointsAdded: asDouble(response.data['points_added']),
      brand: asStringOrNull(response.data['brand']),
      balance: asDouble(response.data['balance']),
      totalBalance: asDouble(response.data['total_balance']),
      message: response.message,
    );
  }

  Future<RedeemResult> redeemCash({
    required int schemeId,
    required double points,
    required String upiId,
    String? brand,
  }) async {
    final response = await client.post(
      ApiEndpoints.rewardsRedeemCash,
      body: {
        'scheme_id': schemeId,
        'points': points,
        'upi_id': upiId,
        if (brand != null) 'brand': brand,
      },
    );

    return RedeemResult(
      pointsAdded: 0,
      brand: brand,
      balance: asDouble(response.data['balance']),
      totalBalance: asDouble(response.data['balance']),
      message: response.message,
    );
  }

  Future<RewardOrder> placeOrder({
    required int schemeId,
    required double points,
    required String name,
    required String address,
    required String city,
    required String state,
    required String pinCode,
    String? brand,
  }) async {
    final response = await client.post(
      ApiEndpoints.rewardsOrder,
      body: {
        'scheme_id': schemeId,
        'points': points,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'pin_code': pinCode,
        if (brand != null) 'brand': brand,
      },
    );

    return RewardOrder.fromJson(response.object('order'));
  }

  Future<Paged<RewardOrder>> orders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final response = await client.post(
      ApiEndpoints.rewardsOrders,
      body: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
    );

    return Paged<RewardOrder>(
      items: response.list('orders').map(RewardOrder.fromJson).toList(),
      meta: response.meta,
    );
  }
}
