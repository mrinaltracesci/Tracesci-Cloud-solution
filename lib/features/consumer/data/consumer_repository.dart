import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/paged.dart';
import '../../../core/utils/json_utils.dart';
import '../models/consumer_models.dart';
import '../models/verdict.dart';

class ProductScanResult {
  final ProductDetail product;
  final List<JourneyStep> journey;
  final int? scanId;
  final bool genuine;
  final String? lastScanned;
  final String? appliedOffer;
  final String? htmlDescription;

  const ProductScanResult({
    required this.product,
    required this.journey,
    required this.genuine,
    this.scanId,
    this.lastScanned,
    this.appliedOffer,
    this.htmlDescription,
  });

  factory ProductScanResult.fromJson(Map<String, dynamic> json) {
    final product = asMap(json['product']);

    return ProductScanResult(
      product: ProductDetail.fromJson(product),
      journey: asList(json['journey'], JourneyStep.fromJson),
      scanId: asIntOrNull(product['scan_id']),
      genuine: asBool(product['genuine_product'], true),
      lastScanned: asStringOrNull(product['last_scanned']),
      appliedOffer: asStringOrNull(product['applied_offer']),
      htmlDescription: asStringOrNull(product['html_description']),
    );
  }
}

class ConsumerRepository {
  final ApiClient client;

  const ConsumerRepository(this.client);

  Future<ConsumerHome> home() async {
    final response = await client.post(ApiEndpoints.consumerHome);
    return ConsumerHome.fromJson(response.data);
  }

  Future<Paged<ScanCard>> scans({
    int page = 1,
    int limit = 20,
    String? genuine,
    String? search,
  }) async {
    final response = await client.post(
      ApiEndpoints.consumerScans,
      body: {
        'page': page,
        'limit': limit,
        if (genuine != null) 'genuine': genuine,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );

    return Paged<ScanCard>(
      items: response.list('scans').map(ScanCard.fromJson).toList(),
      meta: response.meta,
    );
  }

  Future<ScanDetail> scanDetail(int scanId) async {
    final response = await client.post(
      ApiEndpoints.consumerScanDetail(scanId),
    );
    return ScanDetail.fromJson(response.data);
  }

  Future<ProductScanResult> scanCode({
    required String code,
    Map<String, dynamic>? location,
  }) async {
    final response = await client.post(
      ApiEndpoints.scanProduct(code),
      body: {
        if (location != null) 'location': location,
      },
    );

    return ProductScanResult.fromJson(response.data);
  }

  Future<ScanVerdict> diagnose(String code) async {
    final response = await client.post(
      ApiEndpoints.consumerDiagnose,
      body: {'code': code},
    );

    return ScanVerdict.fromJson(response.data);
  }

  Future<ReportItem> report({
    required String issueType,
    required String description,
    String? codeData,
    int? productId,
    String? batch,
    int? scanId,
    String? photoPath,
    Map<String, dynamic>? location,
  }) async {
    final fields = <String, dynamic>{
      'issue_type': issueType,
      'description': description,
      if (codeData != null && codeData.isNotEmpty) 'code_data': codeData,
      if (productId != null) 'product_id': productId,
      if (batch != null && batch.isNotEmpty) 'batch': batch,
      if (scanId != null) 'scan_id': scanId,
      if (location != null) 'location': jsonEncode(location),
    };

    if (photoPath == null || photoPath.isEmpty) {
      final response = await client.post(
        ApiEndpoints.consumerReport,
        body: fields,
      );
      return ReportItem.fromJson(response.object('report'));
    }

    final formData = FormData.fromMap({
      ...fields,
      'photo': await MultipartFile.fromFile(
        photoPath,
        filename: photoPath.split('/').last,
      ),
    });

    final response = await client.upload(
      ApiEndpoints.consumerReport,
      formData: formData,
    );

    return ReportItem.fromJson(response.object('report'));
  }

  Future<Paged<ReportItem>> reports({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final response = await client.post(
      ApiEndpoints.consumerReports,
      body: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
    );

    return Paged<ReportItem>(
      items: response.list('reports').map(ReportItem.fromJson).toList(),
      meta: response.meta,
    );
  }

  Future<List<AppNotification>> notifications() async {
    final response = await client.post(ApiEndpoints.consumerNotifications);
    return response.list('notifications').map(AppNotification.fromJson).toList();
  }
}
