import '../../../core/models/stat_tile.dart';
import '../../../core/utils/json_utils.dart';

class BrandPoints {
  final String brand;
  final double points;

  const BrandPoints({required this.brand, required this.points});

  factory BrandPoints.fromJson(Map<String, dynamic> json) {
    return BrandPoints(
      brand: asString(json['brand']),
      points: asDouble(json['points']),
    );
  }
}

class WalletSnapshot {
  final double totalPoints;
  final List<BrandPoints> brands;

  const WalletSnapshot({required this.totalPoints, required this.brands});

  factory WalletSnapshot.empty() =>
      const WalletSnapshot(totalPoints: 0, brands: []);

  factory WalletSnapshot.fromJson(Map<String, dynamic> json) {
    return WalletSnapshot(
      totalPoints: asDouble(json['total_points']),
      brands: asList(json['brands'], BrandPoints.fromJson),
    );
  }
}

class ScanCard {
  final int scanId;
  final int? codeId;
  final String? codeData;
  final String productName;
  final String? brand;
  final String image;
  final bool genuine;
  final String statusLabel;
  final String scannedAt;
  final String scannedAgo;

  const ScanCard({
    required this.scanId,
    required this.productName,
    required this.image,
    required this.genuine,
    required this.statusLabel,
    required this.scannedAt,
    required this.scannedAgo,
    this.codeId,
    this.codeData,
    this.brand,
  });

  factory ScanCard.fromJson(Map<String, dynamic> json) {
    return ScanCard(
      scanId: asInt(json['scan_id']),
      codeId: asIntOrNull(json['code_id']),
      codeData: asStringOrNull(json['code_data']),
      productName: asString(json['product_name'], 'Unknown product'),
      brand: asStringOrNull(json['brand']),
      image: asString(json['image']),
      genuine: asBool(json['genuine']),
      statusLabel: asString(json['status_label'], 'Could not verify'),
      scannedAt: asString(json['scanned_at']),
      scannedAgo: asString(json['scanned_ago']),
    );
  }
}

class Highlight {
  final int id;
  final String title;
  final String image;
  final String excerpt;
  final String publishDate;

  const Highlight({
    required this.id,
    required this.title,
    required this.image,
    required this.excerpt,
    required this.publishDate,
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: asInt(json['id']),
      title: asString(json['title']),
      image: asString(json['image']),
      excerpt: asString(json['excerpt']),
      publishDate: asString(json['publish_date']),
    );
  }
}

class ConsumerHome {
  final List<StatTile> stats;
  final WalletSnapshot wallet;
  final List<ScanCard> recentScans;
  final int openReports;
  final List<Highlight> highlights;

  const ConsumerHome({
    required this.stats,
    required this.wallet,
    required this.recentScans,
    required this.openReports,
    required this.highlights,
  });

  factory ConsumerHome.fromJson(Map<String, dynamic> json) {
    return ConsumerHome(
      stats: asList(json['stats'], StatTile.fromJson),
      wallet: WalletSnapshot.fromJson(asMap(json['wallet'])),
      recentScans: asList(json['recent_scans'], ScanCard.fromJson),
      openReports: asInt(json['open_reports']),
      highlights: asList(json['highlights'], Highlight.fromJson),
    );
  }
}

class ProductDetail {
  final int id;
  final String name;
  final String? brand;
  final String? description;
  final String price;
  final String manufacturer;
  final String? codeData;
  final String batchCode;
  final String manufacturedOn;
  final String expiryOn;
  final bool isExpired;
  final String image;
  final String labelImage;
  final String media;
  final String logo;
  final int scanCount;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.manufacturer,
    required this.batchCode,
    required this.manufacturedOn,
    required this.expiryOn,
    required this.isExpired,
    required this.image,
    required this.labelImage,
    required this.media,
    required this.logo,
    required this.scanCount,
    this.brand,
    this.description,
    this.codeData,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    return ProductDetail(
      id: asInt(json['id']),
      name: asString(json['name'], 'Unknown product'),
      brand: asStringOrNull(json['brand']),
      description: asStringOrNull(json['description']),
      price: asString(json['price']),
      manufacturer: asString(json['manufacturer']),
      codeData: asStringOrNull(json['code_data']),
      batchCode: asString(json['batch_code']),
      manufacturedOn: asString(json['manufactured_on']),
      expiryOn: asString(json['expiry_on']),
      isExpired: asBool(json['is_expired']),
      image: asString(json['image']),
      labelImage: asString(json['label_image']),
      media: asString(json['media']),
      logo: asString(json['logo']),
      scanCount: asInt(json['scan_count']),
    );
  }
}

class JourneyStep {
  final String code;
  final String type;
  final String action;
  final String? comment;
  final String? status;
  final String scannedBy;
  final String scannedAt;
  final String? actionFor;
  final Map<String, dynamic>? location;

  const JourneyStep({
    required this.code,
    required this.type,
    required this.action,
    required this.scannedBy,
    required this.scannedAt,
    this.comment,
    this.status,
    this.actionFor,
    this.location,
  });

  factory JourneyStep.fromJson(Map<String, dynamic> json) {
    return JourneyStep(
      code: asString(json['code']),
      type: asString(json['type']),
      action: asString(json['action']),
      comment: asStringOrNull(json['comment']),
      status: asStringOrNull(json['status']),
      scannedBy: asString(json['scanned_by']),
      scannedAt: asString(json['scanned_at']),
      actionFor: asStringOrNull(json['action_for']),
      location: asMapOrNull(json['location']),
    );
  }
}

class ScanDetail {
  final int scanId;
  final bool genuine;
  final String scannedAt;
  final String scannedAgo;
  final Map<String, dynamic>? location;
  final ProductDetail? product;
  final List<JourneyStep> journey;
  final bool reported;

  const ScanDetail({
    required this.scanId,
    required this.genuine,
    required this.scannedAt,
    required this.scannedAgo,
    required this.journey,
    required this.reported,
    this.location,
    this.product,
  });

  factory ScanDetail.fromJson(Map<String, dynamic> json) {
    final scan = asMap(json['scan']);
    final product = asMapOrNull(json['product']);

    return ScanDetail(
      scanId: asInt(scan['scan_id']),
      genuine: asBool(scan['genuine']),
      scannedAt: asString(scan['scanned_at']),
      scannedAgo: asString(scan['scanned_ago']),
      location: asMapOrNull(scan['location']),
      product: product == null ? null : ProductDetail.fromJson(product),
      journey: asList(json['journey'], JourneyStep.fromJson),
      reported: asBool(json['reported']),
    );
  }
}

class ReportItem {
  final int id;
  final String reference;
  final String productName;
  final String? batch;
  final String issueType;
  final String description;
  final String status;
  final String? resolution;
  final String createdAt;
  final String createdAgo;

  const ReportItem({
    required this.id,
    required this.reference,
    required this.productName,
    required this.issueType,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.createdAgo,
    this.batch,
    this.resolution,
  });

  bool get isOpen => status.toLowerCase() != 'closed';

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      id: asInt(json['id']),
      reference: asString(json['reference']),
      productName: asString(json['product_name']),
      batch: asStringOrNull(json['batch']),
      issueType: asString(json['issue_type']),
      description: asString(json['description']),
      status: asString(json['status'], 'Open'),
      resolution: asStringOrNull(json['resolution']),
      createdAt: asString(json['created_at']),
      createdAgo: asString(json['created_ago']),
    );
  }
}

class AppNotification {
  final String type;
  final String title;
  final String body;
  final String icon;
  final String createdAt;
  final String createdAgo;

  const AppNotification({
    required this.type,
    required this.title,
    required this.body,
    required this.icon,
    required this.createdAt,
    required this.createdAgo,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      type: asString(json['type']),
      title: asString(json['title']),
      body: asString(json['body']),
      icon: asString(json['icon']),
      createdAt: asString(json['created_at']),
      createdAgo: asString(json['created_ago']),
    );
  }
}

class IssueType {
  final String label;
  final String value;

  const IssueType({required this.label, required this.value});

  factory IssueType.fromJson(Map<String, dynamic> json) {
    return IssueType(
      label: asString(json['label']),
      value: asString(json['value']),
    );
  }
}
