import 'package:flutter/foundation.dart';
import '../models/fatwa.dart';
import '../services/database_helper.dart';
import '../services/whisper_service.dart';
import '../services/docx_service.dart';
import '../services/pdf_service.dart';
import '../services/groq_llm_service.dart';

class FatwaProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final DocxService _docxService = DocxService();
  final PdfService _pdfService = PdfService();

  List<Fatwa> _fatwas = [];
  List<Fatwa> _filteredFatwas = [];
  bool _isLoading = false;
  String? _apiKey;
  String _searchQuery = '';

  List<Fatwa> get fatwas => _filteredFatwas;
  List<Fatwa> get allFatwas => _fatwas;
  bool get isLoading => _isLoading;
  String? get apiKey => _apiKey;
  String get searchQuery => _searchQuery;

  void setApiKey(String key) {
    _apiKey = key;
    notifyListeners();
  }

  Future<void> loadFatwas() async {
    _isLoading = true;
    notifyListeners();
    _fatwas = await _db.getAllFatwas();
    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var result = List<Fatwa>.from(_fatwas);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((f) {
        return (f.transcription?.toLowerCase().contains(q) ?? false) ||
            (f.title?.toLowerCase().contains(q) ?? false) ||
            f.fileName.toLowerCase().contains(q);
      }).toList();
    }

    _filteredFatwas = result;
  }

  Future<void> addFatwas(List<String> filePaths, List<String> fileNames) async {
    for (var i = 0; i < filePaths.length; i++) {
      final fatwa = Fatwa(
        fileName: fileNames[i],
        filePath: filePaths[i],
        status: TranscriptionStatus.pending,
      );
      final id = await _db.insertFatwa(fatwa);
      _fatwas.insert(0, fatwa.copyWith(id: id));
    }
    _applyFilters();
    notifyListeners();
  }

  /// Add shared files from external apps (Telegram, WhatsApp, etc.)
  /// and automatically start transcription
  Future<void> addSharedFilesAndTranscribe(List<String> filePaths) async {
    final fileNames = filePaths.map((p) {
      final name = p.split('/').last;
      return name.isNotEmpty ? name : 'shared_audio_${DateTime.now().millisecondsSinceEpoch}';
    }).toList();

    await addFatwas(filePaths, fileNames);
    // Auto-transcribe the newly added files
    await transcribeAll();
  }

  Future<void> transcribeAll() async {
    if (_apiKey == null || _apiKey!.isEmpty) return;

    final whisper = GroqWhisperService(apiKey: _apiKey!);
    final pendingFatwas = _fatwas
        .where((f) =>
            f.status == TranscriptionStatus.pending ||
            f.status == TranscriptionStatus.error)
        .toList();

    for (final fatwa in pendingFatwas) {
      final index = _fatwas.indexWhere((f) => f.id == fatwa.id);
      if (index == -1) continue;

      _fatwas[index] = fatwa.copyWith(status: TranscriptionStatus.transcribing);
      _applyFilters();
      notifyListeners();

      try {
        final text = await whisper.transcribe(fatwa.filePath!);
        final updated = fatwa.copyWith(
          status: TranscriptionStatus.done,
          transcription: text,
        );
        _fatwas[index] = updated;
        await _db.updateFatwa(updated);
      } catch (e) {
        final updated = fatwa.copyWith(
          status: TranscriptionStatus.error,
          errorMessage: e.toString(),
        );
        _fatwas[index] = updated;
        await _db.updateFatwa(updated);
      }
      _applyFilters();
      notifyListeners();

      // Rate limit delay between requests
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> retryTranscription(Fatwa fatwa) async {
    if (_apiKey == null || _apiKey!.isEmpty) return;

    final index = _fatwas.indexWhere((f) => f.id == fatwa.id);
    if (index == -1) return;

    _fatwas[index] = fatwa.copyWith(status: TranscriptionStatus.transcribing);
    _applyFilters();
    notifyListeners();

    final whisper = GroqWhisperService(apiKey: _apiKey!);
    try {
      final text = await whisper.transcribe(fatwa.filePath!);
      final updated = fatwa.copyWith(
        status: TranscriptionStatus.done,
        transcription: text,
      );
      _fatwas[index] = updated;
      await _db.updateFatwa(updated);
    } catch (e) {
      final updated = fatwa.copyWith(
        status: TranscriptionStatus.error,
        errorMessage: e.toString(),
      );
      _fatwas[index] = updated;
      await _db.updateFatwa(updated);
    }
    _applyFilters();
    notifyListeners();
  }

  Future<void> updateTranscription(Fatwa fatwa, String newText) async {
    final index = _fatwas.indexWhere((f) => f.id == fatwa.id);
    if (index == -1) return;

    final updated = fatwa.copyWith(transcription: newText);
    _fatwas[index] = updated;
    await _db.updateFatwa(updated);
    _applyFilters();
    notifyListeners();
  }

  Future<void> updateTitle(Fatwa fatwa, String newTitle) async {
    final index = _fatwas.indexWhere((f) => f.id == fatwa.id);
    if (index == -1) return;

    final updated = fatwa.copyWith(title: newTitle);
    _fatwas[index] = updated;
    await _db.updateFatwa(updated);
    _applyFilters();
    notifyListeners();
  }

  Future<String> autoFormatTranscription(Fatwa fatwa) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('No API key');
    }
    if (fatwa.transcription == null || fatwa.transcription!.isEmpty) {
      throw Exception('No text to format');
    }

    final llm = GroqLlmService(apiKey: _apiKey!);
    final formatted = await llm.autoFormat(fatwa.transcription!);

    final index = _fatwas.indexWhere((f) => f.id == fatwa.id);
    if (index != -1) {
      final updated = fatwa.copyWith(transcription: formatted);
      _fatwas[index] = updated;
      await _db.updateFatwa(updated);
      _applyFilters();
      notifyListeners();
    }

    return formatted;
  }

  Future<void> deleteFatwa(Fatwa fatwa) async {
    await _db.deleteFatwa(fatwa.id!);
    _fatwas.removeWhere((f) => f.id == fatwa.id);
    _applyFilters();
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _db.deleteAllFatwas();
    _fatwas.clear();
    _applyFilters();
    notifyListeners();
  }

  Future<String> exportSingleFatwa(Fatwa fatwa) async {
    final index = _fatwas.indexOf(fatwa);
    return await _docxService.exportSingleFatwa(fatwa, index + 1);
  }

  Future<String> exportAllFatwas() async {
    final doneFatwas =
        _fatwas.where((f) => f.status == TranscriptionStatus.done).toList();
    return await _docxService.exportAllFatwas(doneFatwas);
  }

  Future<String> exportSinglePdf(Fatwa fatwa) async {
    final index = _fatwas.indexOf(fatwa);
    return await _pdfService.exportSingleFatwa(fatwa, index + 1);
  }

  Future<String> exportAllPdf() async {
    final doneFatwas =
        _fatwas.where((f) => f.status == TranscriptionStatus.done).toList();
    return await _pdfService.exportAllFatwas(doneFatwas);
  }

  /// Group fatwas by date (day)
  Map<DateTime, List<Fatwa>> get groupedFatwas {
    final map = <DateTime, List<Fatwa>>{};
    for (final fatwa in _filteredFatwas) {
      final dateKey = DateTime(
        fatwa.createdAt.year,
        fatwa.createdAt.month,
        fatwa.createdAt.day,
      );
      map.putIfAbsent(dateKey, () => []).add(fatwa);
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }
}
