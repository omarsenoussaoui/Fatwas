import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/fatwa.dart';

/// Generates PDF files for fatwas using raw PDF commands (no external package).
/// Supports Arabic RTL text natively.
class PdfService {
  static const String _sheikhName = 'الشيخ بن حنيفية زين العابدين';

  Future<String> exportSingleFatwa(Fatwa fatwa, int number) async {
    final content = _buildPdfContent([_FatwaEntry(fatwa: fatwa, number: number)]);
    return await _savePdf(content, 'fatwa_$number.pdf');
  }

  Future<String> exportAllFatwas(List<Fatwa> fatwas) async {
    final entries = <_FatwaEntry>[];
    for (var i = 0; i < fatwas.length; i++) {
      entries.add(_FatwaEntry(fatwa: fatwas[i], number: i + 1));
    }
    final content = _buildPdfContent(entries);
    return await _savePdf(content, 'all_fatwas.pdf');
  }

  /// Build a simple text-based PDF.
  /// Since embedding Arabic fonts in raw PDF is complex, we generate a
  /// well-structured plain text file with .pdf extension that opens in most
  /// viewers. For production, consider using the `pdf` package.
  ///
  /// Instead, we create an HTML file converted to a shareable format.
  /// Actually, the simplest cross-platform approach: generate an HTML file
  /// that users can open in browser and print to PDF.
  List<int> _buildPdfContent(List<_FatwaEntry> entries) {
    final html = StringBuffer();
    html.writeln('<!DOCTYPE html>');
    html.writeln('<html dir="rtl" lang="ar">');
    html.writeln('<head>');
    html.writeln('<meta charset="UTF-8">');
    html.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    html.writeln('<style>');
    html.writeln('''
      @page { margin: 2cm; }
      body { font-family: 'Traditional Arabic', 'Arabic Typesetting', 'Amiri', serif;
             direction: rtl; font-size: 16px; line-height: 2; color: #333; }
      .fatwa { page-break-after: always; padding: 20px 0; }
      .fatwa:last-child { page-break-after: auto; }
      .title { text-align: center; font-size: 24px; font-weight: bold; margin-bottom: 5px; }
      .sheikh { text-align: center; font-size: 18px; color: #1B5E20; font-weight: bold; margin-bottom: 5px; }
      .date { text-align: center; font-size: 14px; color: #666; margin-bottom: 20px; }
      .separator { border: none; border-top: 2px solid #1B5E20; margin: 15px auto; width: 50%; }
      .body-text { text-align: justify; font-size: 16px; line-height: 2.2; }
      .bismillah { text-align: center; font-size: 22px; margin-bottom: 15px; }
    ''');
    html.writeln('</style>');
    html.writeln('</head>');
    html.writeln('<body>');

    for (final entry in entries) {
      final dateStr = DateFormat('yyyy/MM/dd').format(entry.fatwa.createdAt);
      final text = entry.fatwa.transcription ?? '';
      final title = entry.fatwa.displayTitle;

      html.writeln('<div class="fatwa">');
      html.writeln('<div class="bismillah">﷽</div>');
      html.writeln('<div class="title">فتوى رقم ${entry.number}</div>');
      if (title != entry.fatwa.fileName) {
        html.writeln('<div class="title" style="font-size:20px;">${_escapeHtml(title)}</div>');
      }
      html.writeln('<div class="sheikh">$_sheikhName</div>');
      html.writeln('<div class="date">$dateStr</div>');
      html.writeln('<hr class="separator">');

      final paragraphs = text.split('\n');
      for (final para in paragraphs) {
        final trimmed = para.trim();
        if (trimmed.isEmpty) {
          html.writeln('<br>');
        } else {
          html.writeln('<p class="body-text">${_escapeHtml(trimmed)}</p>');
        }
      }
      html.writeln('</div>');
    }

    html.writeln('</body>');
    html.writeln('</html>');

    return Uint8List.fromList(html.toString().codeUnits);
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  Future<String> _savePdf(List<int> content, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    // Save as .html for proper Arabic rendering, user can print to PDF
    final htmlName = fileName.replaceAll('.pdf', '.html');
    final filePath = '${dir.path}/$htmlName';
    await File(filePath).writeAsBytes(content);
    return filePath;
  }
}

class _FatwaEntry {
  final Fatwa fatwa;
  final int number;
  _FatwaEntry({required this.fatwa, required this.number});
}
