import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqLlmService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  final String apiKey;

  GroqLlmService({required this.apiKey});

  /// Auto-format Arabic text: add punctuation, paragraph breaks, clean dialect
  Future<String> autoFormat(String text) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {
            'role': 'system',
            'content': 'أنت مساعد متخصص في تنسيق النصوص العربية. '
                'مهمتك هي تحسين النص المُملى (من تحويل صوت إلى نص) عن طريق: '
                '1. إضافة علامات الترقيم المناسبة (نقاط، فواصل، علامات استفهام) '
                '2. تقسيم النص إلى فقرات منطقية '
                '3. تصحيح الأخطاء الإملائية الواضحة '
                'لا تغير المعنى أو تضف محتوى جديد. أعد النص المنسق فقط بدون أي شرح.',
          },
          {
            'role': 'user',
            'content': text,
          },
        ],
        'temperature': 0.1,
        'max_tokens': 4096,
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final content = json['choices']?[0]?['message']?['content'];
      if (content != null && content is String && content.isNotEmpty) {
        return content.trim();
      }
      throw Exception('Empty response from LLM');
    } else {
      String msg = 'Formatting failed (HTTP ${response.statusCode})';
      try {
        final json = jsonDecode(response.body);
        msg = json['error']?['message'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }
}
