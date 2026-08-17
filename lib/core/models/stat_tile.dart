import '../utils/json_utils.dart';

class StatTile {
  final String key;
  final String label;
  final int value;
  final String icon;
  final String? filter;

  const StatTile({
    required this.key,
    required this.label,
    required this.value,
    required this.icon,
    this.filter,
  });

  factory StatTile.fromJson(Map<String, dynamic> json) {
    return StatTile(
      key: asString(json['key']),
      label: asString(json['label']),
      value: asInt(json['value']),
      icon: asString(json['icon']),
      filter: asStringOrNull(json['filter']),
    );
  }
}
