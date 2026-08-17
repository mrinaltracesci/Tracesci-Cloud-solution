import '../../../core/utils/json_utils.dart';
import '../../consumer/models/consumer_models.dart';

export '../../consumer/models/consumer_models.dart' show BrandPoints;

class LedgerEntry {
  final int id;
  final String type;
  final String direction;
  final double points;
  final double? amount;
  final String? brand;
  final String title;
  final String? scheme;
  final String status;
  final String createdAt;
  final String createdAgo;

  const LedgerEntry({
    required this.id,
    required this.type,
    required this.direction,
    required this.points,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.createdAgo,
    this.amount,
    this.brand,
    this.scheme,
  });

  bool get isCredit => type == 'credit';

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: asInt(json['id']),
      type: asString(json['type']),
      direction: asString(json['direction'], '+'),
      points: asDouble(json['points']),
      amount: json['amount'] == null ? null : asDouble(json['amount']),
      brand: asStringOrNull(json['brand']),
      title: asString(json['title']),
      scheme: asStringOrNull(json['scheme']),
      status: asString(json['status']),
      createdAt: asString(json['created_at']),
      createdAgo: asString(json['created_ago']),
    );
  }
}

class RewardSummary {
  final double balance;
  final double lifetimeEarned;
  final double lifetimeSpent;
  final double cashRedeemed;
  final List<BrandPoints> brands;
  final int pendingOrders;
  final List<LedgerEntry> recent;

  const RewardSummary({
    required this.balance,
    required this.lifetimeEarned,
    required this.lifetimeSpent,
    required this.cashRedeemed,
    required this.brands,
    required this.pendingOrders,
    required this.recent,
  });

  factory RewardSummary.fromJson(Map<String, dynamic> json) {
    return RewardSummary(
      balance: asDouble(json['balance']),
      lifetimeEarned: asDouble(json['lifetime_earned']),
      lifetimeSpent: asDouble(json['lifetime_spent']),
      cashRedeemed: asDouble(json['cash_redeemed']),
      brands: asList(json['brands'], BrandPoints.fromJson),
      pendingOrders: asInt(json['pending_orders']),
      recent: asList(json['recent'], LedgerEntry.fromJson),
    );
  }
}

class RewardItem {
  final double points;
  final String type;
  final String item;
  final String label;
  final bool canRedeem;
  final double shortBy;

  const RewardItem({
    required this.points,
    required this.type,
    required this.item,
    required this.label,
    required this.canRedeem,
    required this.shortBy,
  });

  bool get isCash => type == 'amount';

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      points: asDouble(json['points']),
      type: asString(json['type'], 'product'),
      item: asString(json['item']),
      label: asString(json['label']),
      canRedeem: asBool(json['can_redeem']),
      shortBy: asDouble(json['short_by']),
    );
  }
}

class RewardScheme {
  final int schemeId;
  final String title;
  final String? brand;
  final double pointsPerScan;
  final String validFrom;
  final String validTo;
  final double balance;
  final List<RewardItem> items;

  const RewardScheme({
    required this.schemeId,
    required this.title,
    required this.pointsPerScan,
    required this.validFrom,
    required this.validTo,
    required this.balance,
    required this.items,
    this.brand,
  });

  factory RewardScheme.fromJson(Map<String, dynamic> json) {
    return RewardScheme(
      schemeId: asInt(json['scheme_id']),
      title: asString(json['title']),
      brand: asStringOrNull(json['brand']),
      pointsPerScan: asDouble(json['points_per_scan']),
      validFrom: asString(json['valid_from']),
      validTo: asString(json['valid_to']),
      balance: asDouble(json['balance']),
      items: asList(json['items'], RewardItem.fromJson),
    );
  }
}

class OrderTimelineEntry {
  final String message;
  final String date;

  const OrderTimelineEntry({required this.message, required this.date});

  factory OrderTimelineEntry.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEntry(
      message: asString(json['message']),
      date: asString(json['date']),
    );
  }
}

class RewardOrder {
  final int id;
  final String reference;
  final String product;
  final double points;
  final String status;
  final String address;
  final String placedOn;
  final List<OrderTimelineEntry> timeline;

  const RewardOrder({
    required this.id,
    required this.reference,
    required this.product,
    required this.points,
    required this.status,
    required this.address,
    required this.placedOn,
    required this.timeline,
  });

  factory RewardOrder.fromJson(Map<String, dynamic> json) {
    return RewardOrder(
      id: asInt(json['id']),
      reference: asString(json['reference']),
      product: asString(json['product']),
      points: asDouble(json['points']),
      status: asString(json['status'], 'Pending'),
      address: asString(json['address']),
      placedOn: asString(json['placed_on']),
      timeline: asList(json['timeline'], OrderTimelineEntry.fromJson),
    );
  }
}

class RedeemResult {
  final double pointsAdded;
  final String? brand;
  final double balance;
  final double totalBalance;
  final String message;

  const RedeemResult({
    required this.pointsAdded,
    required this.balance,
    required this.totalBalance,
    required this.message,
    this.brand,
  });
}
