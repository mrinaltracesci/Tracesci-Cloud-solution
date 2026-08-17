import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/json_utils.dart';

enum VerdictStatus {
  genuine,
  fake,
  notActivated,
  deactivated,
  blocked,
  expired,
  overScanned,
  unknown;

  static VerdictStatus fromSlug(String slug) {
    switch (slug) {
      case 'genuine':
        return VerdictStatus.genuine;
      case 'fake':
        return VerdictStatus.fake;
      case 'not_activated':
        return VerdictStatus.notActivated;
      case 'deactivated':
        return VerdictStatus.deactivated;
      case 'blocked':
        return VerdictStatus.blocked;
      case 'expired':
        return VerdictStatus.expired;
      case 'over_scanned':
        return VerdictStatus.overScanned;
      default:
        return VerdictStatus.unknown;
    }
  }

  bool get isGenuine => this == VerdictStatus.genuine;

  Color get color {
    switch (this) {
      case VerdictStatus.genuine:
        return AppColors.success;
      case VerdictStatus.expired:
      case VerdictStatus.overScanned:
      case VerdictStatus.notActivated:
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  List<Color> get gradient {
    switch (this) {
      case VerdictStatus.genuine:
        return AppColors.successGradient;
      case VerdictStatus.expired:
      case VerdictStatus.overScanned:
      case VerdictStatus.notActivated:
        return const [Color(0xFFF5A524), Color(0xFFFFC55C)];
      default:
        return AppColors.dangerGradient;
    }
  }

  IconData get icon {
    switch (this) {
      case VerdictStatus.genuine:
        return Icons.verified_rounded;
      case VerdictStatus.fake:
        return Icons.gpp_bad_rounded;
      case VerdictStatus.notActivated:
        return Icons.inventory_rounded;
      case VerdictStatus.deactivated:
        return Icons.block_rounded;
      case VerdictStatus.blocked:
        return Icons.gavel_rounded;
      case VerdictStatus.expired:
        return Icons.event_busy_rounded;
      case VerdictStatus.overScanned:
        return Icons.repeat_rounded;
      case VerdictStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }

  String get advice {
    switch (this) {
      case VerdictStatus.genuine:
        return 'You are good to go.';
      case VerdictStatus.fake:
        return 'Do not use this product. Please report it so we can trace the source.';
      case VerdictStatus.notActivated:
        return 'This pack should not be on sale yet. Please report where you bought it.';
      case VerdictStatus.deactivated:
        return 'Return it to the shop and report it here.';
      case VerdictStatus.blocked:
        return 'This pack was withdrawn by an official. Report it and do not use it.';
      case VerdictStatus.expired:
        return 'Do not consume it. Report it if a shop is still selling it.';
      case VerdictStatus.overScanned:
        return 'The code may have been copied onto fake packs. Reporting helps us confirm.';
      case VerdictStatus.unknown:
        return 'We could not confirm this pack. Reporting it helps.';
    }
  }
}

class VerdictProduct {
  final int? id;
  final String name;
  final String? brand;
  final String image;
  final String? manufacturer;
  final String? batchCode;
  final String? manufacturedOn;
  final String? expiryOn;

  const VerdictProduct({
    required this.name,
    required this.image,
    this.id,
    this.brand,
    this.manufacturer,
    this.batchCode,
    this.manufacturedOn,
    this.expiryOn,
  });

  factory VerdictProduct.fromJson(Map<String, dynamic> json) {
    return VerdictProduct(
      id: asIntOrNull(json['id']),
      name: asString(json['name'], 'Unknown product'),
      brand: asStringOrNull(json['brand']),
      image: asString(json['image']),
      manufacturer: asStringOrNull(json['manufacturer']),
      batchCode: asStringOrNull(json['batch_code']),
      manufacturedOn: asStringOrNull(json['manufactured_on']),
      expiryOn: asStringOrNull(json['expiry_on']),
    );
  }
}

class ScanVerdict {
  final VerdictStatus status;
  final String title;
  final String message;
  final bool isProblem;
  final bool canReport;
  final bool alreadyReported;
  final String scannedCode;
  final String codeData;
  final VerdictProduct? product;

  const ScanVerdict({
    required this.status,
    required this.title,
    required this.message,
    required this.isProblem,
    required this.canReport,
    required this.alreadyReported,
    required this.scannedCode,
    required this.codeData,
    this.product,
  });

  factory ScanVerdict.fromJson(Map<String, dynamic> json) {
    final product = asMapOrNull(json['product']);

    return ScanVerdict(
      status: VerdictStatus.fromSlug(asString(json['status'], 'unknown')),
      title: asString(json['title'], 'Result'),
      message: asString(json['message']),
      isProblem: asBool(json['is_problem'], true),
      canReport: asBool(json['can_report'], true),
      alreadyReported: asBool(json['already_reported']),
      scannedCode: asString(json['scanned_code']),
      codeData: asString(json['code_data']),
      product: product == null ? null : VerdictProduct.fromJson(product),
    );
  }

  factory ScanVerdict.offline(String code, String message) {
    return ScanVerdict(
      status: VerdictStatus.unknown,
      title: 'Could not check this code',
      message: message,
      isProblem: true,
      canReport: true,
      alreadyReported: false,
      scannedCode: code,
      codeData: code,
    );
  }
}
