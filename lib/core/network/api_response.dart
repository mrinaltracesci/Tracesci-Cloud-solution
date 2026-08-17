class PageMeta {
  final int page;
  final int limit;
  final int total;
  final int lastPage;
  final bool hasMore;

  const PageMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.lastPage,
    required this.hasMore,
  });

  factory PageMeta.empty() => const PageMeta(
        page: 1,
        limit: 20,
        total: 0,
        lastPage: 1,
        hasMore: false,
      );

  factory PageMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PageMeta.empty();
    return PageMeta(
      page: _toInt(json['page'], 1),
      limit: _toInt(json['limit'], 20),
      total: _toInt(json['total'], 0),
      lastPage: _toInt(json['last_page'], 1),
      hasMore: json['has_more'] == true,
    );
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}

class ApiResponse {
  final bool success;
  final String message;
  final Map<String, dynamic> data;
  final Map<String, List<String>> errors;
  final PageMeta meta;
  final int statusCode;

  const ApiResponse({
    required this.success,
    required this.message,
    required this.data,
    required this.errors,
    required this.meta,
    required this.statusCode,
  });

  factory ApiResponse.fromJson(dynamic body, int statusCode) {
    if (body is! Map) {
      return ApiResponse(
        success: false,
        message: 'Unexpected response from server.',
        data: const {},
        errors: const {},
        meta: PageMeta.empty(),
        statusCode: statusCode,
      );
    }

    final map = Map<String, dynamic>.from(body);

    const envelopeKeys = {
      'success',
      'error',
      'message',
      'errors',
      'meta',
      'status',
      'data',
    };

    final rawData = map['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{
            for (final entry in map.entries)
              if (!envelopeKeys.contains(entry.key)) '${entry.key}': entry.value,
          };

    final rawErrors = map['errors'];
    final errors = <String, List<String>>{};

    if (rawErrors is Map) {
      rawErrors.forEach((key, value) {
        if (value is List) {
          errors['$key'] = value.map((e) => '$e').toList();
        } else if (value != null) {
          errors['$key'] = ['$value'];
        }
      });
    }

    final rawMeta = map['meta'];

    return ApiResponse(
      success: map['success'] == true || map['error'] == false,
      message: '${map['message'] ?? ''}',
      data: data,
      errors: errors,
      meta: PageMeta.fromJson(
        rawMeta is Map ? Map<String, dynamic>.from(rawMeta) : null,
      ),
      statusCode: statusCode,
    );
  }

  String get firstError {
    if (errors.isEmpty) return message;
    final first = errors.values.first;
    return first.isNotEmpty ? first.first : message;
  }

  List<Map<String, dynamic>> list(String key) {
    final value = data[key];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> object(String key) {
    final value = data[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
