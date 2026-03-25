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
      throw Exception('الملف غير موجود: $filePath');
    }

    final fileSize = await file.length();
    if (fileSize > _maxFileSize) {
      throw Exception('حجم الملف كبير جداً (${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB). الحد الأقصى 25MB.\nقص الملف إلى مقاطع أصغر وأعد المحاولة.');
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
    } on SocketException {
      throw Exception('خطأ في الاتصال بالشبكة — تحقق من الإنترنت');
    } on HttpException {
      throw Exception('خطأ في الاتصال بالخادم');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('فشل الطلب: $e');
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
      throw Exception('استجابة فارغة من الخادم');
    }
    try {
      final json = jsonDecode(body);
      final text = json['text'];
      if (text == null || (text is String && text.isEmpty)) {
        throw Exception('لم يتم العثور على نص في الاستجابة');
      }
      return text as String;
    } on FormatException {
      if (body.trim().isNotEmpty) {
        return body.trim();
      }
      throw Exception('استجابة غير صالحة من الخادم');
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

    switch (status) {
      case 400:
        return 'طلب غير صالح — الملف قد يكون تالفاً أو بصيغة غير مدعومة';
      case 401:
        return 'مفتاح API غير صالح';
      case 413:
        return 'حجم الملف كبير جداً';
      case 429:
        return 'تم تجاوز الحد المسموح — حاول لاحقاً';
      default:
        return 'خطأ غير متوقع (رمز $status)';
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
