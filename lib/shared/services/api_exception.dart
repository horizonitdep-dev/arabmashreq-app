class ApiException implements Exception {
  ApiException({
    required this.message,
    this.fieldErrors = const <String, String>{},
    this.statusCode,
  });

  final String message;
  final Map<String, String> fieldErrors;
  final int? statusCode;

  @override
  String toString() => message;
}
