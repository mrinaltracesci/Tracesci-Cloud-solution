import '../../../core/models/stat_tile.dart';
import '../../../core/utils/json_utils.dart';
import '../../consumer/models/consumer_models.dart';

export '../../consumer/models/consumer_models.dart' show JourneyStep;

class CaseCard {
  final int id;
  final String reference;
  final String kind;
  final String productName;
  final String? batch;
  final String? issueType;
  final String description;
  final String status;
  final bool isOpen;
  final String reportedBy;
  final Map<String, dynamic>? location;
  final String createdAt;
  final String createdAgo;

  const CaseCard({
    required this.id,
    required this.reference,
    required this.kind,
    required this.productName,
    required this.description,
    required this.status,
    required this.isOpen,
    required this.reportedBy,
    required this.createdAt,
    required this.createdAgo,
    this.batch,
    this.issueType,
    this.location,
  });

  factory CaseCard.fromJson(Map<String, dynamic> json) {
    return CaseCard(
      id: asInt(json['id']),
      reference: asString(json['reference']),
      kind: asString(json['kind']),
      productName: asString(json['product_name'], 'Unknown product'),
      batch: asStringOrNull(json['batch']),
      issueType: asStringOrNull(json['issue_type']),
      description: asString(json['description']),
      status: asString(json['status'], 'Open'),
      isOpen: asBool(json['is_open'], true),
      reportedBy: asString(json['reported_by']),
      location: asMapOrNull(json['location']),
      createdAt: asString(json['created_at']),
      createdAgo: asString(json['created_ago']),
    );
  }
}

class CaseProduct {
  final int? id;
  final String name;
  final String? brand;
  final String image;
  final String? codeData;
  final String? codeStatus;
  final String? batchCode;
  final String manufacturedOn;
  final String expiryOn;

  const CaseProduct({
    required this.name,
    required this.image,
    required this.manufacturedOn,
    required this.expiryOn,
    this.id,
    this.brand,
    this.codeData,
    this.codeStatus,
    this.batchCode,
  });

  factory CaseProduct.fromJson(Map<String, dynamic> json) {
    return CaseProduct(
      id: asIntOrNull(json['id']),
      name: asString(json['name'], 'Unknown product'),
      brand: asStringOrNull(json['brand']),
      image: asString(json['image']),
      codeData: asStringOrNull(json['code_data']),
      codeStatus: asStringOrNull(json['code_status']),
      batchCode: asStringOrNull(json['batch_code']),
      manufacturedOn: asString(json['manufactured_on']),
      expiryOn: asString(json['expiry_on']),
    );
  }
}

class ContactCard {
  final String name;
  final String? phone;
  final String? email;
  final String? address;

  const ContactCard({
    required this.name,
    this.phone,
    this.email,
    this.address,
  });

  factory ContactCard.fromJson(Map<String, dynamic> json) {
    return ContactCard(
      name: asString(json['name']),
      phone: asStringOrNull(json['phone']),
      email: asStringOrNull(json['email']),
      address: asStringOrNull(json['address']),
    );
  }
}

class CaseDetail {
  final int id;
  final String reference;
  final String kind;
  final String? issueType;
  final String description;
  final String status;
  final bool isOpen;
  final String image;
  final Map<String, dynamic>? location;
  final String createdAt;
  final String createdAgo;
  final String? resolution;
  final CaseProduct? product;
  final ContactCard? reportedBy;
  final ContactCard? manufacturer;
  final List<JourneyStep> journey;
  final bool canClose;
  final bool canDeactivate;

  const CaseDetail({
    required this.id,
    required this.reference,
    required this.kind,
    required this.description,
    required this.status,
    required this.isOpen,
    required this.image,
    required this.createdAt,
    required this.createdAgo,
    required this.journey,
    required this.canClose,
    required this.canDeactivate,
    this.issueType,
    this.location,
    this.resolution,
    this.product,
    this.reportedBy,
    this.manufacturer,
  });

  factory CaseDetail.fromJson(Map<String, dynamic> json) {
    final root = asMap(json['case']);
    final product = asMapOrNull(json['product']);
    final reporter = asMapOrNull(json['reported_by']);
    final manufacturer = asMapOrNull(json['manufacturer']);
    final actions = asMap(json['actions']);

    return CaseDetail(
      id: asInt(root['id']),
      reference: asString(root['reference']),
      kind: asString(root['kind']),
      issueType: asStringOrNull(root['issue_type']),
      description: asString(root['description']),
      status: asString(root['status'], 'Open'),
      isOpen: asBool(root['is_open'], true),
      image: asString(root['image']),
      location: asMapOrNull(root['location']),
      createdAt: asString(root['created_at']),
      createdAgo: asString(root['created_ago']),
      resolution: asStringOrNull(root['resolution']),
      product: product == null ? null : CaseProduct.fromJson(product),
      reportedBy: reporter == null ? null : ContactCard.fromJson(reporter),
      manufacturer:
          manufacturer == null ? null : ContactCard.fromJson(manufacturer),
      journey: asList(json['journey'], JourneyStep.fromJson),
      canClose: asBool(actions['can_close']),
      canDeactivate: asBool(actions['can_deactivate']),
    );
  }
}

class InspectorDashboard {
  final List<StatTile> stats;
  final List<CaseCard> recentCases;

  const InspectorDashboard({
    required this.stats,
    required this.recentCases,
  });

  factory InspectorDashboard.fromJson(Map<String, dynamic> json) {
    return InspectorDashboard(
      stats: asList(json['stats'], StatTile.fromJson),
      recentCases: asList(json['recent_cases'], CaseCard.fromJson),
    );
  }
}

class MapPoint {
  final int? id;
  final double latitude;
  final double longitude;
  final String title;
  final String? subtitle;
  final String? status;
  final bool? genuine;
  final String date;

  const MapPoint({
    required this.latitude,
    required this.longitude,
    required this.title,
    required this.date,
    this.id,
    this.subtitle,
    this.status,
    this.genuine,
  });

  factory MapPoint.fromJson(Map<String, dynamic> json) {
    return MapPoint(
      id: asIntOrNull(json['id']),
      latitude: asDouble(json['latitude']),
      longitude: asDouble(json['longitude']),
      title: asString(json['title']),
      subtitle: asStringOrNull(json['subtitle']),
      status: asStringOrNull(json['status']),
      genuine: json['genuine'] == null ? null : asBool(json['genuine']),
      date: asString(json['date']),
    );
  }
}
