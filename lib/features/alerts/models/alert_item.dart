import '../../../core/utils/json_utils.dart';

class AlertItem {
  final int id;
  final String reference;
  final String kind;
  final String title;
  final String productName;
  final String? batch;
  final String? issueType;
  final String description;
  final String status;
  final bool isOpen;
  final bool raisedByMe;
  final String raisedBy;
  final String image;
  final Map<String, dynamic>? location;
  final String? resolution;
  final String createdAt;
  final String createdAgo;

  const AlertItem({
    required this.id,
    required this.reference,
    required this.kind,
    required this.title,
    required this.productName,
    required this.description,
    required this.status,
    required this.isOpen,
    required this.raisedByMe,
    required this.raisedBy,
    required this.image,
    required this.createdAt,
    required this.createdAgo,
    this.batch,
    this.issueType,
    this.location,
    this.resolution,
  });

  bool get isReport => kind.toLowerCase().contains('report');

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: asInt(json['id']),
      reference: asString(json['reference']),
      kind: asString(json['kind']),
      title: asString(json['title'], 'Something looked wrong'),
      productName: asString(json['product_name'], 'Unknown product'),
      batch: asStringOrNull(json['batch']),
      issueType: asStringOrNull(json['issue_type']),
      description: asString(json['description']),
      status: asString(json['status'], 'Open'),
      isOpen: asBool(json['is_open'], true),
      raisedByMe: asBool(json['raised_by_me']),
      raisedBy: asString(json['raised_by'], 'Unknown'),
      image: asString(json['image']),
      location: asMapOrNull(json['location']),
      resolution: asStringOrNull(json['resolution']),
      createdAt: asString(json['created_at']),
      createdAgo: asString(json['created_ago']),
    );
  }
}

class AlertFeed {
  final List<AlertItem> alerts;
  final bool canSeeProducts;
  final int mineCount;
  final int productCount;

  const AlertFeed({
    required this.alerts,
    required this.canSeeProducts,
    required this.mineCount,
    required this.productCount,
  });
}
