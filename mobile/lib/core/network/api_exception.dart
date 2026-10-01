import '../localization/api_error_messages.dart';

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required String message,
    this.statusCode,
  }) : serverMessage = message;

  final String code;
  final String serverMessage;
  final int? statusCode;

  String get message {
    return ApiErrorMessages.translate(
      code,
      fallback: serverMessage,
    );
  }

  @override
  String toString() => message;
}
