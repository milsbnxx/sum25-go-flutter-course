// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';
  static const Duration timeout = Duration(seconds: 30);
  late final http.Client _client;

  ApiService({http.Client? client}) {
    _client = client ?? http.Client();
  }

  void dispose() => _client.close();

  Map<String, String> _getHeaders() => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  Future<List<Message>> getMessages() async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/api/messages'), headers: _getHeaders())
          .timeout(timeout);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
        if (jsonMap['success'] != true) {
          throw ApiException(jsonMap['error'] ?? 'Unknown error');
        }
        final data = jsonMap['data'] as List<dynamic>;
        return data
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (resp.statusCode >= 400 && resp.statusCode < 500) {
        throw ValidationException(
            'Client error: ${resp.statusCode} ${resp.body}');
      } else if (resp.statusCode >= 500 && resp.statusCode < 600) {
        throw ServerException('Server error: ${resp.statusCode}');
      } else {
        throw ApiException('Unexpected status code: ${resp.statusCode}');
      }
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<Message> createMessage(CreateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw ValidationException(validationError);
    }
    try {
      final resp = await _client
          .post(
            Uri.parse('$baseUrl/api/messages'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
        if (jsonMap['success'] != true) {
          throw ApiException(jsonMap['error'] ?? 'Unknown error');
        }
        final data = jsonMap['data'] as Map<String, dynamic>;
        return Message.fromJson(data);
      } else if (resp.statusCode >= 400 && resp.statusCode < 500) {
        throw ValidationException(
            'Client error: ${resp.statusCode} ${resp.body}');
      } else {
        throw ServerException('Server error: ${resp.statusCode}');
      }
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<Message> updateMessage(int id, UpdateMessageRequest request) async {
    final validationError = request.validate();
    if (validationError != null) {
      throw ValidationException(validationError);
    }
    try {
      final resp = await _client
          .put(
            Uri.parse('$baseUrl/api/messages/$id'),
            headers: _getHeaders(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
        if (jsonMap['success'] != true) {
          throw ApiException(jsonMap['error'] ?? 'Unknown error');
        }
        final data = jsonMap['data'] as Map<String, dynamic>;
        return Message.fromJson(data);
      } else if (resp.statusCode >= 400 && resp.statusCode < 500) {
        throw ValidationException(
            'Client error: ${resp.statusCode} ${resp.body}');
      } else {
        throw ServerException('Server error: ${resp.statusCode}');
      }
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<void> deleteMessage(int id) async {
    try {
      final resp = await _client
          .delete(Uri.parse('$baseUrl/api/messages/$id'),
              headers: _getHeaders())
          .timeout(timeout);
      if (resp.statusCode != 204) {
        throw ApiException(
            'Failed to delete: ${resp.statusCode} ${resp.body}');
      }
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<HTTPStatusResponse> getHTTPStatus(int statusCode) async {
    if (statusCode < 100 || statusCode > 599) {
      throw ValidationException('Invalid status code: $statusCode');
    }
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/api/status/$statusCode'),
              headers: _getHeaders())
          .timeout(timeout);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final jsonMap = jsonDecode(resp.body) as Map<String, dynamic>;
        if (jsonMap['success'] != true) {
          throw ApiException(jsonMap['error'] ?? 'Unknown error');
        }
        final data = jsonMap['data'] as Map<String, dynamic>;
        return HTTPStatusResponse.fromJson(data);
      } else if (resp.statusCode >= 400 && resp.statusCode < 500) {
        throw ValidationException(
            'Client error: ${resp.statusCode} ${resp.body}');
      } else {
        throw ServerException('Server error: ${resp.statusCode}');
      }
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/api/health'), headers: _getHeaders())
          .timeout(timeout);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } else {
        throw ApiException('Health check failed: ${resp.statusCode}');
      }
    } on TimeoutException {
      throw NetworkException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw NetworkException(e.toString());
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => 'ApiException: $message';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message);
}
