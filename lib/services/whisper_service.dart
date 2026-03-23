import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class GroqWhisperService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
  static const String _modelsUrl = 'https://api.groq.com/openai/v1/models';
  static const Duration _rateLimitDelay = Duration(seconds: 3);
  static const int _maxRetries = 3;
  // Groq limit is 25MB
  static const int _maxFileSize = 25 * 1024 * 1024;

  final String apiKey;

  GroqWhisperService({required this.apiKey});

  /// Transcribe an audio file to Arabic text using Groq Whisper API
  Future<String> transcribe(String filePath, {int retryCount = 0}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('File not found: $filePath');
    }

    final fileSize = await file.length();
    if (fileSize > _maxFileSize) {
      throw Exception('File too large (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). Groq limit is 25MB.');
    }

    final mimeType = lookupMimeType(filePath) ?? 'audio/mpeg';
    final mimeTypeParts = mimeType.split('/');

    http.Response response;
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.fields['model'] = 'whisper-large-v3';
      request.fields['language'] = 'ar';
      request.fields['response_format'] = 'json';

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
      ));

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );
      response = await http.Response.fromStream(streamedResponse);
    } on SocketException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP error: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Request failed: $e');
    }

    // Handle rate limiting - retry after delay
    if (response.statusCode == 429 && retryCount < _maxRetries) {
      await Future.delayed(_rateLimitDelay * (retryCount + 1));
      return transcribe(filePath, retryCount: retryCount + 1);
    }

    // Handle server errors with retry
    if (response.statusCode >= 500 && retryCount < _maxRetries) {
      await Future.delayed(_rateLimitDelay);
      return transcribe(filePath, retryCount: retryCount + 1);
    }

    if (response.statusCode == 200) {
      return _parseSuccessResponse(response.body);
    } else {
      throw Exception(_parseErrorMessage(response));
    }
  }

  String _parseSuccessResponse(String body) {
    if (body.isEmpty) {
      throw Exception('Empty response from API');
    }
    try {
      final json = jsonDecode(body);
      final text = json['text'];
      if (text == null || (text is String && text.isEmpty)) {
        throw Exception('No transcription text in response');
      }
      return text as String;
    } on FormatException {
      // Response is not JSON - might be plain text transcription
      if (body.trim().isNotEmpty) {
        return body.trim();
      }
      throw Exception('Invalid response format from API');
    }
  }

  String _parseErrorMessage(http.Response response) {
    final status = response.statusCode;
    final body = response.body;

    // Try to parse as JSON error
    try {
      final json = jsonDecode(body);
      final message = json['error']?['message'] ?? json['message'] ?? json['error'];
      if (message != null) {
        return '$message (HTTP $status)';
      }
    } on FormatException {
      // Not JSON
    }

    // Common status code messages
    switch (status) {
      case 400:
        return 'Bad request - file may be corrupted or unsupported format (HTTP 400)';
      case 401:
        return 'Invalid API key (HTTP 401)';
      case 413:
        return 'File too large for API (HTTP 413)';
      case 429:
        return 'Rate limit exceeded - please try again later (HTTP 429)';
      default:
        if (body.isNotEmpty && body.length < 200) {
          return 'API error: $body (HTTP $status)';
        }
        return 'Transcription failed (HTTP $status)';
    }
  }

  /// Test the API key by calling the models endpoint
  static Future<bool> testApiKey(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse(_modelsUrl),
        headers: {'Authorization': 'Bearer $apiKey'},
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
