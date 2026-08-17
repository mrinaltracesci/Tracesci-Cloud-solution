class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, List<String>> errors;
  final ApiFailureKind kind;

  const ApiException({
    required this.message,
    this.statusCode = 0,
    this.errors = const {},
    this.kind = ApiFailureKind.unknown,
  });

  bool get isUnauthorized => kind == ApiFailureKind.unauthorized;

  bool get isNetwork => kind == ApiFailureKind.network;

  bool get isForbidden => kind == ApiFailureKind.forbidden;

  String? fieldError(String field) {
    final value = errors[field];
    if (value == null || value.isEmpty) return null;
    return value.first;
  }

  @override
  String toString() => message;
}

enum ApiFailureKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  cancelled,
  unknown,
}
