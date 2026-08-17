import '../../../core/utils/json_utils.dart';

enum UserRole {
  consumer,
  supplyChain,
  brand,
  inspector,
  authority,
  admin;

  static UserRole fromSlug(String slug) {
    switch (slug) {
      case 'supply_chain':
        return UserRole.supplyChain;
      case 'brand':
        return UserRole.brand;
      case 'inspector':
        return UserRole.inspector;
      case 'authority':
        return UserRole.authority;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.consumer;
    }
  }

  bool get isConsumer => this == UserRole.consumer;

  bool get isSupplyChain => this == UserRole.supplyChain;

  bool get isFieldAgent => this == UserRole.inspector || this == UserRole.authority;

  bool get isBrandSide => this == UserRole.brand || this == UserRole.admin;
}

class CompanyInfo {
  final String name;
  final String? gst;
  final String? cin;
  final String? address;

  const CompanyInfo({
    required this.name,
    this.gst,
    this.cin,
    this.address,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      name: asString(json['name']),
      gst: asStringOrNull(json['gst']),
      cin: asStringOrNull(json['cin']),
      address: asStringOrNull(json['address']),
    );
  }
}

class SupplyChainNode {
  final String nodeRole;
  final bool hasParent;
  final String? parent;

  const SupplyChainNode({
    required this.nodeRole,
    required this.hasParent,
    this.parent,
  });

  factory SupplyChainNode.fromJson(Map<String, dynamic> json) {
    return SupplyChainNode(
      nodeRole: asString(json['node_role'], 'Supply Chain User'),
      hasParent: asBool(json['has_parent']),
      parent: asStringOrNull(json['parent']),
    );
  }
}

class UserProfile {
  final int id;
  final String name;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? phoneCode;
  final String? phone;
  final String? email;
  final String? dob;
  final String? gender;
  final String? photo;
  final String? addressOne;
  final String? addressTwo;
  final String? zip;
  final String type;
  final UserRole role;
  final String roleLabel;
  final String? designation;
  final String? brand;
  final String? memberSince;
  final CompanyInfo? company;
  final SupplyChainNode? supplyChain;

  const UserProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.role,
    required this.roleLabel,
    this.firstName,
    this.middleName,
    this.lastName,
    this.phoneCode,
    this.phone,
    this.email,
    this.dob,
    this.gender,
    this.photo,
    this.addressOne,
    this.addressTwo,
    this.zip,
    this.designation,
    this.brand,
    this.memberSince,
    this.company,
    this.supplyChain,
  });

  factory UserProfile.empty() => const UserProfile(
        id: 0,
        name: 'User',
        type: '0',
        role: UserRole.consumer,
        roleLabel: 'Consumer',
      );

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final company = asMapOrNull(json['company']);
    final supplyChain = asMapOrNull(json['supply_chain']);

    return UserProfile(
      id: asInt(json['id']),
      name: asString(json['name'], 'User'),
      firstName: asStringOrNull(json['first_name']),
      middleName: asStringOrNull(json['middle_name']),
      lastName: asStringOrNull(json['last_name']),
      phoneCode: asStringOrNull(json['phone_code']),
      phone: asStringOrNull(json['phone']),
      email: asStringOrNull(json['email']),
      dob: asStringOrNull(json['dob']),
      gender: asStringOrNull(json['gender']),
      photo: asStringOrNull(json['photo']),
      addressOne: asStringOrNull(json['address_one']),
      addressTwo: asStringOrNull(json['address_two']),
      zip: asStringOrNull(json['zip']),
      type: asString(json['type'], '0'),
      role: UserRole.fromSlug(asString(json['role'], 'consumer')),
      roleLabel: asString(json['role_label'], 'User'),
      designation: asStringOrNull(json['designation']),
      brand: asStringOrNull(json['brand']),
      memberSince: asStringOrNull(json['member_since']),
      company: company == null ? null : CompanyInfo.fromJson(company),
      supplyChain:
          supplyChain == null ? null : SupplyChainNode.fromJson(supplyChain),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  String get displayPhone {
    if (phone == null || phone!.isEmpty) return '';
    final code = phoneCode == null || phoneCode!.isEmpty ? '' : '+$phoneCode ';
    return '$code$phone';
  }
}

class Capabilities {
  final Map<String, bool> _flags;

  const Capabilities(this._flags);

  factory Capabilities.fromJson(Map<String, dynamic> json) {
    final flags = <String, bool>{};
    json.forEach((key, value) => flags[key] = asBool(value));
    return Capabilities(flags);
  }

  factory Capabilities.empty() => const Capabilities({});

  bool has(String key) => _flags[key] ?? false;

  bool get scanProduct => has('scan_product');

  bool get scanSupplyChain => has('scan_supply_chain');

  bool get reportProduct => has('report_product');

  bool get rewards => has('rewards');

  bool get wallet => has('wallet');

  bool get cases => has('reports');

  bool get brandDashboard => has('brand_dashboard');

  bool get supplyChainBoard => has('supply_chain_board');

  bool get alerts => has('alerts');

  bool get scanHistory => has('scan_history');

  bool get canScanAnything => scanProduct || scanSupplyChain;

  Map<String, bool> toJson() => Map<String, bool>.from(_flags);
}

class AppTab {
  final String key;
  final String label;
  final String icon;
  final String endpoint;

  const AppTab({
    required this.key,
    required this.label,
    required this.icon,
    required this.endpoint,
  });

  factory AppTab.fromJson(Map<String, dynamic> json) {
    return AppTab(
      key: asString(json['key']),
      label: asString(json['label']),
      icon: asString(json['icon']),
      endpoint: asString(json['endpoint']),
    );
  }
}

class QuickAction {
  final String key;
  final String label;
  final String icon;
  final bool primary;

  const QuickAction({
    required this.key,
    required this.label,
    required this.icon,
    required this.primary,
  });

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      key: asString(json['key']),
      label: asString(json['label']),
      icon: asString(json['icon']),
      primary: asBool(json['primary']),
    );
  }
}

enum ScannerMode { product, supplyChain }

class ScannerConfig {
  final ScannerMode mode;
  final String submitEndpoint;
  final bool requiresLocation;
  final String hint;

  const ScannerConfig({
    required this.mode,
    required this.submitEndpoint,
    required this.requiresLocation,
    required this.hint,
  });

  factory ScannerConfig.fallback() => const ScannerConfig(
        mode: ScannerMode.product,
        submitEndpoint: 'p/{code}',
        requiresLocation: true,
        hint: 'Point the camera at the QR code on the pack',
      );

  factory ScannerConfig.fromJson(Map<String, dynamic> json) {
    return ScannerConfig(
      mode: asString(json['mode']) == 'supply_chain'
          ? ScannerMode.supplyChain
          : ScannerMode.product,
      submitEndpoint: asString(json['submit_endpoint'], 'p/{code}'),
      requiresLocation: asBool(json['requires_location'], true),
      hint: asString(json['hint'], 'Scan the code'),
    );
  }
}

class AppTheming {
  final String accent;
  final String greeting;
  final String displayName;

  const AppTheming({
    required this.accent,
    required this.greeting,
    required this.displayName,
  });

  factory AppTheming.fallback() => const AppTheming(
        accent: '#0F62FE',
        greeting: 'Welcome',
        displayName: 'User',
      );

  factory AppTheming.fromJson(Map<String, dynamic> json) {
    return AppTheming(
      accent: asString(json['accent'], '#0F62FE'),
      greeting: asString(json['greeting'], 'Welcome'),
      displayName: asString(json['display_name'], 'User'),
    );
  }
}

class BootstrapData {
  final UserProfile profile;
  final UserRole role;
  final String roleLabel;
  final Capabilities capabilities;
  final List<AppTab> tabs;
  final List<QuickAction> quickActions;
  final ScannerConfig scanner;
  final AppTheming theme;

  const BootstrapData({
    required this.profile,
    required this.role,
    required this.roleLabel,
    required this.capabilities,
    required this.tabs,
    required this.quickActions,
    required this.scanner,
    required this.theme,
  });

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    return BootstrapData(
      profile: UserProfile.fromJson(asMap(json['profile'])),
      role: UserRole.fromSlug(asString(json['role'], 'consumer')),
      roleLabel: asString(json['role_label'], 'User'),
      capabilities: Capabilities.fromJson(asMap(json['capabilities'])),
      tabs: asList(json['tabs'], AppTab.fromJson),
      quickActions: asList(json['quick_actions'], QuickAction.fromJson),
      scanner: json['scanner'] == null
          ? ScannerConfig.fallback()
          : ScannerConfig.fromJson(asMap(json['scanner'])),
      theme: json['theme'] == null
          ? AppTheming.fallback()
          : AppTheming.fromJson(asMap(json['theme'])),
    );
  }
}
