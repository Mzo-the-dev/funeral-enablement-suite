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

  Future<Map<String, dynamic>> login({
    required String identity,
    required String password,
  }) {
    return _post('/sessions', {'identity': identity, 'password': password});
  }

  Future<void> logout(String sessionToken) async {
    await _post('/sessions/logout', {'sessionToken': sessionToken});
  }

  Future<List<Map<String, dynamic>>> listSpaceTypes() {
    return _getList('/spaces/types');
  }

  Future<List<Map<String, dynamic>>> listDiscoverableSpaces() {
    return _getList('/spaces/discoverable');
  }

  Future<List<Map<String, dynamic>>> listMySpaces(String sessionToken) {
    return _getList(
      '/spaces/mine',
      headers: {'Authorization': 'Bearer $sessionToken'},
    );
  }

  Future<Map<String, dynamic>> getSocietyDashboard({
    required String spaceId,
    required String sessionToken,
  }) {
    return _getMap(
      '/spaces/${Uri.encodeComponent(spaceId)}/dashboard',
      headers: {'Authorization': 'Bearer $sessionToken'},
    );
  }

  Future<Map<String, dynamic>> requestSocietyMembership({
    required String spaceId,
    required String memberNumber,
    required String sessionToken,
  }) {
    return _post(
      '/spaces/${Uri.encodeComponent(spaceId)}/join-requests',
      {'memberNumber': memberNumber},
      headers: {'Authorization': 'Bearer $sessionToken'},
    );
  }

  Future<Map<String, dynamic>> approveMembershipRequest({
    required String spaceId,
    required String requestId,
    required String sessionToken,
  }) {
    return _post(
      '/spaces/${Uri.encodeComponent(spaceId)}/membership-requests/${Uri.encodeComponent(requestId)}/approve',
      const {},
      headers: {'Authorization': 'Bearer $sessionToken'},
    );
  }

  Future<Map<String, dynamic>> approveFuneralCase({
    required String spaceId,
    required String caseId,
    required String sessionToken,
  }) {
    return _post(
      '/spaces/${Uri.encodeComponent(spaceId)}/funeral-cases/${Uri.encodeComponent(caseId)}/approve',
      const {},
      headers: {'Authorization': 'Bearer $sessionToken'},
    );
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic>
            ? decoded['message']
            : null;
        throw RegistrationApiException(
          message is List
              ? message.join('\n')
              : message?.toString() ??
                    'Request failed (${response.statusCode}).',
        );
      }
      if (decoded is! List ||
          decoded.any((item) => item is! Map<String, dynamic>)) {
        throw const RegistrationApiException(
          'The server returned an unexpected response.',
        );
      }
      return decoded.cast<Map<String, dynamic>>();
    } on RegistrationApiException {
      rethrow;
    } on http.ClientException {
      throw const RegistrationApiException(
        'Cannot reach the Spaces server. Check that the local API is running.',
      );
    } on FormatException {
      throw const RegistrationApiException(
        'The server returned an unreadable response.',
      );
    } on Exception catch (error) {
      if (error.toString().contains('TimeoutException')) {
        throw const RegistrationApiException(
          'The Spaces server took too long to respond.',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object?> payload, {
    Map<String, String> headers = const {},
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$path'),
            headers: {'content-type': 'application/json', ...headers},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic>
            ? decoded['message']
            : null;
        throw RegistrationApiException(
          message is List
              ? message.join('\n')
              : message?.toString() ??
                    'Request failed (${response.statusCode}).',
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const RegistrationApiException(
          'The server returned an unexpected response.',
        );
      }
      return decoded;
    } on RegistrationApiException {
      rethrow;
    } on http.ClientException {
      throw const RegistrationApiException(
        'Cannot reach the registration server. Check that the local API is running.',
      );
    } on FormatException {
      throw const RegistrationApiException(
        'The server returned an unreadable response.',
      );
    } on Exception catch (error) {
      if (error.toString().contains('TimeoutException')) {
        throw const RegistrationApiException(
          'The registration server took too long to respond.',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getMap(
    String path, {
    Map<String, String> headers = const {},
  }) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = decoded is Map<String, dynamic>
            ? decoded['message']
            : null;
        throw RegistrationApiException(
          message is List
              ? message.join('\n')
              : message?.toString() ??
                    'Request failed (${response.statusCode}).',
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw const RegistrationApiException(
          'The server returned an unexpected response.',
        );
      }
      return decoded;
    } on RegistrationApiException {
      rethrow;
    } on http.ClientException {
      throw const RegistrationApiException(
        'Cannot reach the Spaces server. Check that the local API is running.',
      );
    } on FormatException {
      throw const RegistrationApiException(
        'The server returned an unreadable response.',
      );
    } on Exception catch (error) {
      if (error.toString().contains('TimeoutException')) {
        throw const RegistrationApiException(
          'The Spaces server took too long to respond.',
        );
      }
      rethrow;
    }
  }
}
