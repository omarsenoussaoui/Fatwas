import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/fatwa.dart';

class DocxService {
  static const String _sheikhName = 'الشيخ بن حنيفية زين العابدين';

  /// Generate a DOCX file for a single fatwa
  Future<String> exportSingleFatwa(Fatwa fatwa, int number) async {
    final content = _buildDocxXml([_FatwaEntry(fatwa: fatwa, number: number)]);
    return await _saveDocx(content, 'fatwa_$number.docx');
  }

  /// Generate a DOCX file for all fatwas
  Future<String> exportAllFatwas(List<Fatwa> fatwas) async {
    final entries = <_FatwaEntry>[];
    for (var i = 0; i < fatwas.length; i++) {
      entries.add(_FatwaEntry(fatwa: fatwas[i], number: i + 1));
    }
    final content = _buildDocxXml(entries);
    return await _saveDocx(content, 'all_fatwas.docx');
  }

  String _buildDocxXml(List<_FatwaEntry> entries) {
    final buffer = StringBuffer();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final dateStr = DateFormat('yyyy/MM/dd').format(entry.fatwa.createdAt);
      final text = entry.fatwa.transcription ?? '';
      final title = entry.fatwa.displayTitle;

      // Add page break before each fatwa except the first
      if (i > 0) {
        buffer.writeln('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
      }

      // Title
      buffer.writeln('''<w:p>
  <w:pPr><w:bidi/><w:jc w:val="center"/>
    <w:rPr><w:b/><w:bCs/><w:sz w:val="36"/><w:szCs w:val="36"/><w:rtl/></w:rPr>
  </w:pPr>
  <w:r><w:rPr><w:b/><w:bCs/><w:sz w:val="36"/><w:szCs w:val="36"/><w:rtl/></w:rPr>
    <w:t>فتوى رقم ${entry.number}</w:t>
  </w:r>
</w:p>''');

      // Custom title if set
      if (title != entry.fatwa.fileName) {
        buffer.writeln('''<w:p>
  <w:pPr><w:bidi/><w:jc w:val="center"/>
    <w:rPr><w:b/><w:bCs/><w:sz w:val="28"/><w:szCs w:val="28"/><w:rtl/></w:rPr>
  </w:pPr>
  <w:r><w:rPr><w:b/><w:bCs/><w:sz w:val="28"/><w:szCs w:val="28"/><w:rtl/></w:rPr>
    <w:t>${_escapeXml(title)}</w:t>
  </w:r>
</w:p>''');
      }

      // Sheikh name
      buffer.writeln('''<w:p>
  <w:pPr><w:bidi/><w:jc w:val="center"/>
    <w:rPr><w:b/><w:bCs/><w:sz w:val="28"/><w:szCs w:val="28"/><w:rtl/><w:color w:val="1B5E20"/></w:rPr>
  </w:pPr>
  <w:r><w:rPr><w:b/><w:bCs/><w:sz w:val="28"/><w:szCs w:val="28"/><w:rtl/><w:color w:val="1B5E20"/></w:rPr>
    <w:t>$_sheikhName</w:t>
  </w:r>
</w:p>''');

      // Date
      buffer.writeln('''<w:p>
  <w:pPr><w:bidi/><w:jc w:val="center"/>
    <w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/><w:rtl/><w:color w:val="666666"/></w:rPr>
  </w:pPr>
  <w:r><w:rPr><w:sz w:val="22"/><w:szCs w:val="22"/><w:rtl/><w:color w:val="666666"/></w:rPr>
    <w:t>$dateStr</w:t>
  </w:r>
</w:p>''');

      // Separator
      buffer.writeln('<w:p><w:pPr><w:bidi/></w:pPr></w:p>');

      // Body text - split into paragraphs
      final paragraphs = text.split('\n');
      for (final para in paragraphs) {
        final escaped = _escapeXml(para.trim());
        if (escaped.isEmpty) {
          buffer.writeln('<w:p><w:pPr><w:bidi/></w:pPr></w:p>');
        } else {
          buffer.writeln('''<w:p>
  <w:pPr><w:bidi/><w:jc w:val="both"/>
    <w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/><w:rtl/></w:rPr>
  </w:pPr>
  <w:r><w:rPr><w:sz w:val="24"/><w:szCs w:val="24"/><w:rtl/></w:rPr>
    <w:t xml:space="preserve">$escaped</w:t>
  </w:r>
</w:p>''');
        }
      }
    }

    return buffer.toString();
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  Future<String> _saveDocx(String bodyContent, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/$fileName';

    // Build a complete OOXML .docx as a ZIP archive
    final contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

    final relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas"
  xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
  xmlns:o="urn:schemas-microsoft-com:office:office"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math"
  xmlns:v="urn:schemas-microsoft-com:vml"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:w10="urn:schemas-microsoft-com:office:word"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:w14="http://schemas.microsoft.com/office/word/2010/wordml"
  xmlns:wpg="http://schemas.microsoft.com/office/word/2010/wordprocessingGroup"
  xmlns:wpi="http://schemas.microsoft.com/office/word/2010/wordprocessingInk"
  xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml"
  xmlns:wps="http://schemas.microsoft.com/office/word/2010/wordprocessingShape"
  mc:Ignorable="w14 wp14">
  <w:body>
$bodyContent
  </w:body>
</w:document>''';

    // Create ZIP archive manually using dart:io ZLibCodec
    // We'll use a simpler approach: write raw DOCX using Archive
    // Since we don't have archive package, we'll create ZIP manually

    final zipData = _createZip({
      '[Content_Types].xml': contentTypesXml,
      '_rels/.rels': relsXml,
      'word/document.xml': documentXml,
    });

    await File(filePath).writeAsBytes(zipData);
    return filePath;
  }

  /// Creates a minimal ZIP archive from a map of filename -> content
  List<int> _createZip(Map<String, String> files) {
    final List<int> centralDirectory = [];
    final List<int> localFiles = [];
    var offset = 0;

    for (final entry in files.entries) {
      final nameBytes = utf8.encode(entry.key);
      final contentBytes = utf8.encode(entry.value);
      final crc = _crc32(contentBytes);

      // Local file header
      final localHeader = <int>[
        // Signature
        0x50, 0x4B, 0x03, 0x04,
        // Version needed
        0x14, 0x00,
        // Flags
        0x00, 0x00,
        // Compression (none)
        0x00, 0x00,
        // Mod time
        0x00, 0x00,
        // Mod date
        0x00, 0x00,
        // CRC-32
        ...(_int32Bytes(crc)),
        // Compressed size
        ...(_int32Bytes(contentBytes.length)),
        // Uncompressed size
        ...(_int32Bytes(contentBytes.length)),
        // File name length
        ...(_int16Bytes(nameBytes.length)),
        // Extra field length
        0x00, 0x00,
      ];

      localFiles.addAll(localHeader);
      localFiles.addAll(nameBytes);
      localFiles.addAll(contentBytes);

      // Central directory entry
      final cdEntry = <int>[
        // Signature
        0x50, 0x4B, 0x01, 0x02,
        // Version made by
        0x14, 0x00,
        // Version needed
        0x14, 0x00,
        // Flags
        0x00, 0x00,
        // Compression
        0x00, 0x00,
        // Mod time
        0x00, 0x00,
        // Mod date
        0x00, 0x00,
        // CRC-32
        ...(_int32Bytes(crc)),
        // Compressed size
        ...(_int32Bytes(contentBytes.length)),
        // Uncompressed size
        ...(_int32Bytes(contentBytes.length)),
        // File name length
        ...(_int16Bytes(nameBytes.length)),
        // Extra field length
        0x00, 0x00,
        // File comment length
        0x00, 0x00,
        // Disk number start
        0x00, 0x00,
        // Internal file attributes
        0x00, 0x00,
        // External file attributes
        0x00, 0x00, 0x00, 0x00,
        // Relative offset of local header
        ...(_int32Bytes(offset)),
      ];

      centralDirectory.addAll(cdEntry);
      centralDirectory.addAll(nameBytes);

      offset += localHeader.length + nameBytes.length + contentBytes.length;
    }

    // End of central directory
    final endOfCd = <int>[
      // Signature
      0x50, 0x4B, 0x05, 0x06,
      // Disk number
      0x00, 0x00,
      // Central directory disk number
      0x00, 0x00,
      // Number of entries on this disk
      ...(_int16Bytes(files.length)),
      // Total entries
      ...(_int16Bytes(files.length)),
      // Central directory size
      ...(_int32Bytes(centralDirectory.length)),
      // Central directory offset
      ...(_int32Bytes(offset)),
      // Comment length
      0x00, 0x00,
    ];

    return [...localFiles, ...centralDirectory, ...endOfCd];
  }

  List<int> _int16Bytes(int value) => [value & 0xFF, (value >> 8) & 0xFF];
  List<int> _int32Bytes(int value) => [value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF];

  int _crc32(List<int> data) {
    const table = <int>[
      0x00000000, 0x77073096, 0xEE0E612C, 0x990951BA, 0x076DC419, 0x706AF48F,
      0xE963A535, 0x9E6495A3, 0x0EDB8832, 0x79DCB8A4, 0xE0D5E91B, 0x97D2D988,
      0x09B64C2B, 0x7EB17CBE, 0xE7B82D09, 0x90BF1D91, 0x1DB71064, 0x6AB020F2,
      0xF3B97148, 0x84BE41DE, 0x1ADAD47D, 0x6DDDE4EB, 0xF4D4B551, 0x83D385C7,
      0x136C9856, 0x646BA8C0, 0xFD62F97A, 0x8A65C9EC, 0x14015C4F, 0x63066CD9,
      0xFA0F3D63, 0x8D080DF5, 0x20D02B80, 0x57D4D916, 0xCADDB1EC, 0xBDDAD78A,
      0x27B70A89, 0x50B0781F, 0xC9B7D9A5, 0xBEB0C9D1, 0x28D4C3AB, 0x5FD3B93D,
      0xC6DAE887, 0xB1DDD8E1, 0x2BB45A92, 0x5CB36A04, 0xC3BA6BBE, 0xB4BDBDF8,
      0x2CD99E8B, 0x5BDEAE1D, 0xC8D75BA7, 0xBFD06131, 0x21B4F4B5, 0x56B3C423,
      0xCFBA9599, 0xB8BDA50F, 0x2802B89E, 0x5F058808, 0xC60CD9B2, 0xB10BE924,
      0x2F6F7C87, 0x58684C11, 0xC1611DAB, 0xB6662D3D, 0x76DC4190, 0x01DB7106,
      0x98D220BC, 0xEFD5102A, 0x71B18589, 0x06B6B51F, 0x9FBFE4A5, 0xE8B8D433,
      0x7807C9A2, 0x0F00F934, 0x9609A88E, 0xE10E9818, 0x7F6A0D6B, 0x086D3D2D,
      0x91646C97, 0xE6635C01, 0x6B6B51F4, 0x1C6C6162, 0x856530D8, 0xF262004E,
      0x6C0695ED, 0x1B01A57B, 0x8208F4C1, 0xF50FC457, 0x65B0D9C6, 0x12B7E950,
      0x8BBEB8EA, 0xFCB9887C, 0x62DD1DDF, 0x15DA2D49, 0x8CD37CF3, 0xFBD44C65,
      0x4DB26158, 0x3AB551CE, 0xA3BC0074, 0xD4BB30E2, 0x4ADFA541, 0x3DD895D7,
      0xA4D1C46D, 0xD3D6F4FB, 0x4369E96A, 0x346ED9FC, 0xAD678846, 0xDA60B8D0,
      0x44042D73, 0x33031DE5, 0xAA0A4C5F, 0xDD0D7AC9, 0x5005713C, 0x270241AA,
      0xBE0B1010, 0xC90C2086, 0x5768B525, 0x206F85B3, 0xB966D409, 0xCE61E49F,
      0x5EDEF90E, 0x29D9C998, 0xB0D09822, 0xC7D7A8B4, 0x59B33D17, 0x2EB40D81,
      0xB7BD5C3B, 0xC0BA6CAD, 0xEDB88320, 0x9ABFB3B6, 0x03B6E20C, 0x74B1D29A,
      0xEAD54739, 0x9DD277AF, 0x04DB2615, 0x73DC1683, 0xE3630B12, 0x94643B84,
      0x0D6D6A3E, 0x7A6A5AA8, 0xE40ECF0B, 0x9309FF9D, 0x0A00AE27, 0x7D079EB1,
      0xF00F9344, 0x8708A3D2, 0x1E01F268, 0x6906C2FE, 0xF762575D, 0x806567CB,
      0x196C3671, 0x6E6B06E7, 0xFED41B76, 0x89D32BE0, 0x10DA7A5A, 0x67DD4ACC,
      0xF9B9DF6F, 0x8EBEEFF9, 0x17B7BE43, 0x60B08ED5, 0xD6D6A3E8, 0xA1D1937E,
      0x38D8C2C4, 0x4FDFF252, 0xD1BB67F1, 0xA6BC5767, 0x3FB506DD, 0x48B2364B,
      0xD80D2BDA, 0xAF0A1B4C, 0x36034AF6, 0x41047A60, 0xDF60EFC3, 0xA8670855,
      0x316E8A07, 0x46697E91, 0xD06016F7, 0xA7672661, 0xD0646D0E, 0xA7630698,
      0x3E6E7722, 0x4969474D, 0xD762372A, 0xA0654BCE, 0x376D1B5C, 0x4064290C,
      0xDC631BA9, 0xAB64CB3F, 0x32637A85, 0x45646113, 0xD9D65ADC, 0xAEDC484A,
      0x37D5B9F0, 0x40D2E966, 0xDA6C39C5, 0xAD6B2953, 0x3463B8E9, 0x4364D87F,
      0xD36D0D4E, 0xA46A3DD8, 0x3D634562, 0x4A6476F4, 0xDCD60DCF, 0xABD13D59,
      0x34D8A4E3, 0x43DF5475, 0xD30E0AD6, 0xA4090A40, 0x3D00DBFA, 0x4A07EB6C,
      0xD56A99FB, 0xA26DA86D, 0x3B64D9D7, 0x4C63E941, 0xDC7C0FA0, 0xAB7B3F36,
      0x32721A8C, 0x4575EA1A, 0xDB397AB9, 0xAC3E4A2F, 0x35370B95, 0x42303B03,
      0xD4D5063C, 0xA3D236AA, 0x0D684710, 0x7A6F5786, 0xE4082225, 0x930912B3,
      0x0B680E09, 0x7C6F7E9F, 0xE5665F24, 0x92610FB2, 0x026D7323, 0x756A63B5,
      0xEC63340F, 0x9B643D99, 0x0500083A, 0x720709AC, 0xEB0E5816, 0x9C096880,
      0x1101B4F5, 0x6606C463, 0xF90FA0D9, 0x8E08D04F, 0x1061B7EC, 0x6766877A,
      0xFE6FC6C0, 0x896FCD56, 0x1963BFC7, 0x6E64AF51, 0xF76D8FEB, 0x806B9F7D,
      0x1E0F0CDE, 0x69082B48, 0xF00103F2, 0x87063364, 0x0E0A2C11, 0x790F0C87,
      0xE0060F3D, 0x97032DAB, 0x09674808, 0x7E60789E, 0xE7695824, 0x906E68B2,
      0x007E1423, 0x777924B5, 0xEE70750F, 0x99777499, 0x0711163A, 0x701626AC,
      0xE91B7716, 0x9E1C4780, 0x13142475, 0x641314E3, 0xFD1A4559, 0x8A1D75CF,
      0x1479806C, 0x637EB0FA, 0xFA77E140, 0x8D70D1D6, 0x1D6EAEE7, 0x6A69BE71,
      0xF360EFCB, 0x8467DF5D, 0x1A0373FE, 0x6D044368, 0xF40B12D2, 0x833F0E44,
    ];

    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc = (crc >> 8) ^ table[(crc ^ byte) & 0xFF];
    }
    return crc ^ 0xFFFFFFFF;
  }
}

class _FatwaEntry {
  final Fatwa fatwa;
  final int number;

  _FatwaEntry({required this.fatwa, required this.number});
}
