import '../../../core/models/stat_tile.dart';
import '../../../core/utils/json_utils.dart';
import '../../consumer/models/consumer_models.dart';

export '../../consumer/models/consumer_models.dart' show JourneyStep;

class ChainActivity {
  final String code;
  final String action;
  final String title;
  final String? status;
  final String? comment;
  final String? by;
  final String? forUser;
  final bool verified;
  final String createdAt;
  final String createdAgo;

  const ChainActivity({
    required this.code,
    required this.action,
    required this.title,
    required this.verified,
    required this.createdAt,
    required this.createdAgo,
    this.status,
    this.comment,
    this.by,
    this.forUser,
  });

  factory ChainActivity.fromJson(Map<String, dynamic> json) {
    return ChainActivity(
      code: asString(json['code']),
      action: asString(json['action']),
      title: asString(json['title']),
      status: asStringOrNull(json['status']),
      comment: asStringOrNull(json['comment']),
      by: asStringOrNull(json['by']),
      forUser: asStringOrNull(json['for']),
      verified: asBool(json['verified']),
      createdAt: asString(json['created_at']),
      createdAgo: asString(json['created_ago']),
    );
  }
}

class SupplyChainDashboard {
  final List<StatTile> stats;
  final int alertsOpen;
  final List<ChainActivity> activity;
  final bool canDispatch;

  const SupplyChainDashboard({
    required this.stats,
    required this.alertsOpen,
    required this.activity,
    required this.canDispatch,
  });

  factory SupplyChainDashboard.fromJson(Map<String, dynamic> json) {
    return SupplyChainDashboard(
      stats: asList(json['stats'], StatTile.fromJson),
      alertsOpen: asInt(json['alerts_open']),
      activity: asList(json['activity'], ChainActivity.fromJson),
      canDispatch: asBool(json['can_dispatch']),
    );
  }
}

class ConsignmentCard {
  final String code;
  final String level;
  final String custody;
  final String action;
  final String? counterparty;
  final String? status;
  final String? comment;
  final String eligibleFor;
  final String updatedAt;
  final String updatedAgo;

  const ConsignmentCard({
    required this.code,
    required this.level,
    required this.custody,
    required this.action,
    required this.eligibleFor,
    required this.updatedAt,
    required this.updatedAgo,
    this.counterparty,
    this.status,
    this.comment,
  });

  bool get canCheckIn => eligibleFor == 'checkin';

  bool get canCheckOut => eligibleFor == 'checkout';

  factory ConsignmentCard.fromJson(Map<String, dynamic> json) {
    return ConsignmentCard(
      code: asString(json['code']),
      level: asString(json['level']),
      custody: asString(json['custody']),
      action: asString(json['action']),
      counterparty: asStringOrNull(json['counterparty']),
      status: asStringOrNull(json['status']),
      comment: asStringOrNull(json['comment']),
      eligibleFor: asString(json['eligible_for']),
      updatedAt: asString(json['updated_at']),
      updatedAgo: asString(json['updated_ago']),
    );
  }
}

class PackedProduct {
  final String name;
  final String? brand;
  final String image;
  final String batchCode;
  final String manufacturedOn;
  final String expiryOn;
  final bool isExpired;
  final int quantity;

  const PackedProduct({
    required this.name,
    required this.image,
    required this.batchCode,
    required this.manufacturedOn,
    required this.expiryOn,
    required this.isExpired,
    required this.quantity,
    this.brand,
  });

  factory PackedProduct.fromJson(Map<String, dynamic> json) {
    return PackedProduct(
      name: asString(json['name'], 'Unknown product'),
      brand: asStringOrNull(json['brand']),
      image: asString(json['image']),
      batchCode: asString(json['batch_code']),
      manufacturedOn: asString(json['manufactured_on']),
      expiryOn: asString(json['expiry_on']),
      isExpired: asBool(json['is_expired']),
      quantity: asInt(json['quantity']),
    );
  }
}

class ConsignmentDetail {
  final String code;
  final String level;
  final int totalUnits;
  final int childCount;
  final List<PackedProduct> products;
  final String custody;
  final ChainActivity? lastAction;
  final String eligibleFor;
  final List<JourneyStep> timeline;

  const ConsignmentDetail({
    required this.code,
    required this.level,
    required this.totalUnits,
    required this.childCount,
    required this.products,
    required this.custody,
    required this.eligibleFor,
    required this.timeline,
    this.lastAction,
  });

  factory ConsignmentDetail.fromJson(Map<String, dynamic> json) {
    final last = asMapOrNull(json['last_action']);

    return ConsignmentDetail(
      code: asString(json['code']),
      level: asString(json['level']),
      totalUnits: asInt(json['total_units']),
      childCount: asInt(json['child_count']),
      products: asList(json['products'], PackedProduct.fromJson),
      custody: asString(json['custody']),
      lastAction: last == null ? null : ChainActivity.fromJson(last),
      eligibleFor: asString(json['eligible_for']),
      timeline: asList(json['timeline'], JourneyStep.fromJson),
    );
  }
}

class Counterparty {
  final String label;
  final int value;
  final String? role;
  final String direction;

  const Counterparty({
    required this.label,
    required this.value,
    required this.direction,
    this.role,
  });

  bool get isReturn => direction == 'return';

  factory Counterparty.fromJson(Map<String, dynamic> json) {
    return Counterparty(
      label: asString(json['label']),
      value: asInt(json['value']),
      role: asStringOrNull(json['role']),
      direction: asString(json['direction'], 'downstream'),
    );
  }
}

class ChainStatusOption {
  final String label;
  final String value;
  final String? comment;

  const ChainStatusOption({
    required this.label,
    required this.value,
    this.comment,
  });

  factory ChainStatusOption.fromJson(Map<String, dynamic> json) {
    return ChainStatusOption(
      label: asString(json['label']),
      value: asString(json['value']),
      comment: asStringOrNull(json['comment']),
    );
  }
}

class ChainAlert {
  final int id;
  final String message;
  final String? code;
  final String? level;
  final String? scannedBy;
  final String createdAt;
  final String createdAgo;

  const ChainAlert({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.createdAgo,
    this.code,
    this.level,
    this.scannedBy,
  });

  factory ChainAlert.fromJson(Map<String, dynamic> json) {
    return ChainAlert(
      id: asInt(json['id']),
      message: asString(json['message']),
      code: asStringOrNull(json['code']),
      level: asStringOrNull(json['level']),
      scannedBy: asStringOrNull(json['scanned_by']),
      createdAt: asString(json['created_at']),
      createdAgo: asString(json['created_ago']),
    );
  }
}

class ScanActionUser {
  final String label;
  final int value;

  const ScanActionUser({required this.label, required this.value});

  factory ScanActionUser.fromJson(Map<String, dynamic> json) {
    return ScanActionUser(
      label: asString(json['label']),
      value: asInt(json['value']),
    );
  }
}

class SupplyChainScanResult {
  final int total;
  final String aggregationUniqueId;
  final String? lastScanned;
  final String eligibleFor;
  final int? scanId;
  final List<ScanActionUser> users;
  final List<ChainStatusOption> statuses;
  final List<JourneyStep> history;
  final List<PackedProduct> products;

  const SupplyChainScanResult({
    required this.total,
    required this.aggregationUniqueId,
    required this.eligibleFor,
    required this.users,
    required this.statuses,
    required this.history,
    required this.products,
    this.lastScanned,
    this.scanId,
  });

  bool get hasAction => eligibleFor.isNotEmpty && scanId != null;

  bool get isCheckout => eligibleFor == 'checkout';

  factory SupplyChainScanResult.fromJson(Map<String, dynamic> json) {
    final action = asMap(json['action']);

    return SupplyChainScanResult(
      total: asInt(json['total']),
      aggregationUniqueId: asString(json['aggregation_unique_id']),
      lastScanned: asStringOrNull(json['last_scanned']),
      eligibleFor: asString(action['eligible_for']),
      scanId: asIntOrNull(action['scan_id']),
      users: asList(action['users'], ScanActionUser.fromJson),
      statuses: asList(action['status'], ChainStatusOption.fromJson),
      history: asList(json['history'], JourneyStep.fromJson),
      products: asList(json['products'], PackedProduct.fromJson),
    );
  }
}
