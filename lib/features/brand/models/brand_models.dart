import '../../../core/models/stat_tile.dart';
import '../../../core/utils/json_utils.dart';

class MonthSnapshot {
  final int codesUploaded;
  final int codesActive;
  final int codesInactive;
  final int activatedToday;
  final int scans;

  const MonthSnapshot({
    required this.codesUploaded,
    required this.codesActive,
    required this.codesInactive,
    required this.activatedToday,
    required this.scans,
  });

  factory MonthSnapshot.fromJson(Map<String, dynamic> json) {
    return MonthSnapshot(
      codesUploaded: asInt(json['codes_uploaded']),
      codesActive: asInt(json['codes_active']),
      codesInactive: asInt(json['codes_inactive']),
      activatedToday: asInt(json['activated_today']),
      scans: asInt(json['scans']),
    );
  }
}

class CreditSnapshot {
  final int available;
  final int used;
  final int total;

  const CreditSnapshot({
    required this.available,
    required this.used,
    required this.total,
  });

  double get usedRatio => total == 0 ? 0 : used / total;

  factory CreditSnapshot.fromJson(Map<String, dynamic> json) {
    return CreditSnapshot(
      available: asInt(json['available']),
      used: asInt(json['used']),
      total: asInt(json['total']),
    );
  }
}

class TrendPoint {
  final String date;
  final String day;
  final int count;

  const TrendPoint({
    required this.date,
    required this.day,
    required this.count,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      date: asString(json['date']),
      day: asString(json['day']),
      count: asInt(json['count']),
    );
  }
}

class TopProduct {
  final int id;
  final String name;
  final String? brand;
  final String image;
  final int scans;

  const TopProduct({
    required this.id,
    required this.name,
    required this.image,
    required this.scans,
    this.brand,
  });

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      id: asInt(json['id']),
      name: asString(json['name']),
      brand: asStringOrNull(json['brand']),
      image: asString(json['image']),
      scans: asInt(json['scans']),
    );
  }
}

class BrandAlertPreview {
  final int id;
  final String productName;
  final String description;
  final String kind;
  final String createdAgo;

  const BrandAlertPreview({
    required this.id,
    required this.productName,
    required this.description,
    required this.kind,
    required this.createdAgo,
  });

  factory BrandAlertPreview.fromJson(Map<String, dynamic> json) {
    return BrandAlertPreview(
      id: asInt(json['id']),
      productName: asString(json['product_name']),
      description: asString(json['description']),
      kind: asString(json['kind']),
      createdAgo: asString(json['created_ago']),
    );
  }
}

class BrandDashboard {
  final List<StatTile> stats;
  final MonthSnapshot thisMonth;
  final CreditSnapshot credits;
  final List<TrendPoint> scanTrend;
  final List<TopProduct> topProducts;
  final List<BrandAlertPreview> recentAlerts;
  final int networkNodes;
  final int networkAlerts;

  const BrandDashboard({
    required this.stats,
    required this.thisMonth,
    required this.credits,
    required this.scanTrend,
    required this.topProducts,
    required this.recentAlerts,
    required this.networkNodes,
    required this.networkAlerts,
  });

  factory BrandDashboard.fromJson(Map<String, dynamic> json) {
    final network = asMap(json['supply_chain']);

    return BrandDashboard(
      stats: asList(json['stats'], StatTile.fromJson),
      thisMonth: MonthSnapshot.fromJson(asMap(json['this_month'])),
      credits: CreditSnapshot.fromJson(asMap(json['credits'])),
      scanTrend: asList(json['scan_trend'], TrendPoint.fromJson),
      topProducts: asList(json['top_products'], TopProduct.fromJson),
      recentAlerts: asList(json['recent_alerts'], BrandAlertPreview.fromJson),
      networkNodes: asInt(network['nodes']),
      networkAlerts: asInt(network['alerts']),
    );
  }
}

class BrandProduct {
  final int id;
  final String name;
  final String? brand;
  final String price;
  final String image;
  final String status;
  final bool isActive;
  final int codes;
  final int batches;
  final String createdAt;

  const BrandProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.status,
    required this.isActive,
    required this.codes,
    required this.batches,
    required this.createdAt,
    this.brand,
  });

  factory BrandProduct.fromJson(Map<String, dynamic> json) {
    return BrandProduct(
      id: asInt(json['id']),
      name: asString(json['name']),
      brand: asStringOrNull(json['brand']),
      price: asString(json['price']),
      image: asString(json['image']),
      status: asString(json['status'], 'Inactive'),
      isActive: asBool(json['is_active']),
      codes: asInt(json['codes']),
      batches: asInt(json['batches']),
      createdAt: asString(json['created_at']),
    );
  }
}

class BrandBatch {
  final int id;
  final String code;
  final String? gs1Code;
  final String manufacturedOn;
  final String expiryOn;
  final bool isExpired;
  final String status;
  final int codes;
  final String? remarks;

  const BrandBatch({
    required this.id,
    required this.code,
    required this.manufacturedOn,
    required this.expiryOn,
    required this.isExpired,
    required this.status,
    required this.codes,
    this.gs1Code,
    this.remarks,
  });

  factory BrandBatch.fromJson(Map<String, dynamic> json) {
    return BrandBatch(
      id: asInt(json['id']),
      code: asString(json['code']),
      gs1Code: asStringOrNull(json['gs1_code']),
      manufacturedOn: asString(json['manufactured_on']),
      expiryOn: asString(json['expiry_on']),
      isExpired: asBool(json['is_expired']),
      status: asString(json['status'], 'Inactive'),
      codes: asInt(json['codes']),
      remarks: asStringOrNull(json['remarks']),
    );
  }
}

class BrandProductDetail {
  final BrandProduct product;
  final String? description;
  final String labelImage;
  final String media;
  final String logo;
  final bool authRequired;
  final bool pinRequired;
  final List<BrandBatch> batches;
  final int codesGenerated;
  final int codesActive;
  final int totalScans;
  final int openAlerts;

  const BrandProductDetail({
    required this.product,
    required this.labelImage,
    required this.media,
    required this.logo,
    required this.authRequired,
    required this.pinRequired,
    required this.batches,
    required this.codesGenerated,
    required this.codesActive,
    required this.totalScans,
    required this.openAlerts,
    this.description,
  });

  factory BrandProductDetail.fromJson(Map<String, dynamic> json) {
    final product = asMap(json['product']);
    final performance = asMap(json['performance']);

    return BrandProductDetail(
      product: BrandProduct.fromJson(product),
      description: asStringOrNull(product['description']),
      labelImage: asString(product['label_image']),
      media: asString(product['media']),
      logo: asString(product['logo']),
      authRequired: asBool(product['auth_required']),
      pinRequired: asBool(product['pin_required']),
      batches: asList(json['batches'], BrandBatch.fromJson),
      codesGenerated: asInt(performance['codes_generated']),
      codesActive: asInt(performance['codes_active']),
      totalScans: asInt(performance['total_scans']),
      openAlerts: asInt(performance['open_alerts']),
    );
  }
}

class BrandScan {
  final int scanId;
  final String? codeData;
  final String productName;
  final String? brand;
  final String image;
  final bool genuine;
  final String scannedBy;
  final Map<String, dynamic>? location;
  final String scannedAt;
  final String scannedAgo;

  const BrandScan({
    required this.scanId,
    required this.productName,
    required this.image,
    required this.genuine,
    required this.scannedBy,
    required this.scannedAt,
    required this.scannedAgo,
    this.codeData,
    this.brand,
    this.location,
  });

  factory BrandScan.fromJson(Map<String, dynamic> json) {
    return BrandScan(
      scanId: asInt(json['scan_id']),
      codeData: asStringOrNull(json['code_data']),
      productName: asString(json['product_name'], 'Unknown product'),
      brand: asStringOrNull(json['brand']),
      image: asString(json['image']),
      genuine: asBool(json['genuine']),
      scannedBy: asString(json['scanned_by']),
      location: asMapOrNull(json['location']),
      scannedAt: asString(json['scanned_at']),
      scannedAgo: asString(json['scanned_ago']),
    );
  }
}

class BrandAlert {
  final int id;
  final String reference;
  final String kind;
  final String productName;
  final String? batch;
  final String? issueType;
  final String description;
  final String status;
  final Map<String, dynamic>? location;
  final String createdAt;
  final String createdAgo;

  const BrandAlert({
    required this.id,
    required this.reference,
    required this.kind,
    required this.productName,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.createdAgo,
    this.batch,
    this.issueType,
    this.location,
  });

  bool get isOpen => status.toLowerCase() != 'closed';

  factory BrandAlert.fromJson(Map<String, dynamic> json) {
    return BrandAlert(
      id: asInt(json['id']),
      reference: asString(json['reference']),
      kind: asString(json['kind']),
      productName: asString(json['product_name']),
      batch: asStringOrNull(json['batch']),
      issueType: asStringOrNull(json['issue_type']),
      description: asString(json['description']),
      status: asString(json['status'], 'Open'),
      location: asMapOrNull(json['location']),
      createdAt: asString(json['created_at']),
      createdAgo: asString(json['created_ago']),
    );
  }
}

class NetworkNode {
  final int id;
  final String name;
  final String? role;
  final String? phone;
  final String? email;
  final String status;
  final int? parentId;
  final String joinedOn;

  const NetworkNode({
    required this.id,
    required this.name,
    required this.status,
    required this.joinedOn,
    this.role,
    this.phone,
    this.email,
    this.parentId,
  });

  bool get isActive => status.toLowerCase() == 'active';

  factory NetworkNode.fromJson(Map<String, dynamic> json) {
    return NetworkNode(
      id: asInt(json['id']),
      name: asString(json['name']),
      role: asStringOrNull(json['role']),
      phone: asStringOrNull(json['phone']),
      email: asStringOrNull(json['email']),
      status: asString(json['status'], 'Inactive'),
      parentId: asIntOrNull(json['parent_id']),
      joinedOn: asString(json['joined_on']),
    );
  }
}
