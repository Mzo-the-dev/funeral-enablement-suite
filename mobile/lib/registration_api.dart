import 'dart:convert';

import 'package:http/http.dart' as http;

class RegistrationApiException implements Exception {
  const RegistrationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RegistrationApi {
  const RegistrationApi();

  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  Future<Map<String, dynamic>> register(Map<String, Object?> payload) async {
    return _post('/registrations', payload);
  }

  Future<Map<String, dynamic>> verify({
    required String registrationId,
    required String code,
  }) async {
    return _post('/registrations/verify', {
      'registrationId': registrationId,
      'code': code,
    });
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> payload,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic>
            ? decoded['message']
            : null;
        throw RegistrationApiException(
          message is List ? message.join('\n') : message?.toString() ?? 'Request failed (${response.statusCode}).',
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const RegistrationApiException('The server returned an unexpected response.');
      }
      return decoded;
    } on RegistrationApiException {
      rethrow;
    } on http.ClientException {
      throw const RegistrationApiException(
        'Cannot reach the registration server. Check that the local API is running.',
      );
    } on FormatException {
      throw const RegistrationApiException('The server returned an unreadable response.');
    } on Exception catch (error) {
      if (error.toString().contains('TimeoutException')) {
        throw const RegistrationApiException('The registration server took too long to respond.');
      }
      rethrow;
    }
  }
}
