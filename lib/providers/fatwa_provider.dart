import 'package:flutter/foundation.dart';
import '../models/fatwa.dart';
import '../services/database_helper.dart';
import '../services/whisper_service.dart';

import '../services/docx_service.dart';

class FatwaProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final DocxService _docxService = DocxService();

  List<Fatwa> _fatwas = [];
  bool _isLoading = false;
  String? _apiKey;

  List<Fatwa> get fatwas => _fatwas;
  bool get isLoading => _isLoading;
  String? get apiKey => _apiKey;

  void setApiKey(String key) {
    _apiKey = key;
    notifyListeners();
  }

  Future<void> loadFatwas() async {
    _isLoading = true;
    notifyListeners();
    _fatwas = await _db.getAllFatwas();
    _isLoading = false;
    notifyListeners();
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
    notifyListeners();
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

      // Update status to transcribing
      _fatwas[index] = fatwa.copyWith(status: TranscriptionStatus.transcribing);
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
    notifyListeners();
  }

  Future<void> updateTranscription(Fatwa fatwa, String newText) async {
    final index = _fatwas.indexWhere((f) => f.id == fatwa.id);
    if (index == -1) return;

    final updated = fatwa.copyWith(transcription: newText);
    _fatwas[index] = updated;
    await _db.updateFatwa(updated);
    notifyListeners();
  }

  Future<void> deleteFatwa(Fatwa fatwa) async {
    await _db.deleteFatwa(fatwa.id!);
    _fatwas.removeWhere((f) => f.id == fatwa.id);
    notifyListeners();
  }

  Future<void> clearAll() async {
    await _db.deleteAllFatwas();
    _fatwas.clear();
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

  /// Group fatwas by date (day)
  Map<DateTime, List<Fatwa>> get groupedFatwas {
    final map = <DateTime, List<Fatwa>>{};
    for (final fatwa in _fatwas) {
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
