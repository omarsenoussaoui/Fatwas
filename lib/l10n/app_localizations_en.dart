// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Fatwas of Sheikh Ben Hanifa Zine El Abidine';

  @override
  String get sheikhName => 'الشيخ بن حنيفية زين العابدين';

  @override
  String get home => 'Home';

  @override
  String get upload => 'Upload';

  @override
  String get settings => 'Settings';

  @override
  String get uploadFiles => 'Upload Audio Files';

  @override
  String get selectAudioFiles => 'Select Audio Files';

  @override
  String get selectFiles => 'Select Files';

  @override
  String get transcribe => 'Transcribe';

  @override
  String get transcribing => 'Transcribing...';

  @override
  String get download => 'Download';

  @override
  String get downloadAll => 'Download All';

  @override
  String get downloadDocx => 'Download DOCX';

  @override
  String get clearAll => 'Clear All';

  @override
  String get clearAllConfirm => 'Are you sure you want to clear all fatwas?';

  @override
  String get clearAllDescription => 'All fatwas will be permanently deleted';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirm => 'Are you sure you want to delete this fatwa?';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String fatwaNumber(int number) {
    return 'Fatwa #$number';
  }

  @override
  String get date => 'Date';

  @override
  String get author => 'Author';

  @override
  String get noFatwas => 'No fatwas yet';

  @override
  String get noFatwasDescription => 'Upload audio files to start transcription';

  @override
  String get pending => 'Pending';

  @override
  String get transcribingStatus => 'Transcribing';

  @override
  String get done => 'Done';

  @override
  String get error => 'Error';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get apiKey => 'Groq API Key';

  @override
  String get apiKeyHint => 'Enter your Groq API key';

  @override
  String get testKey => 'Test Key';

  @override
  String get testKeySuccess => 'Key is valid ✓';

  @override
  String get testKeyFailed => 'Key is invalid ✗';

  @override
  String get testingKey => 'Testing...';

  @override
  String get usingDefaultKey => 'Using default key';

  @override
  String get usingCustomKey => 'Using custom key';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String filesSelected(int count) {
    return '$count files selected';
  }

  @override
  String get transcriptionComplete => 'Transcription complete';

  @override
  String get transcriptionFailed => 'Transcription failed';

  @override
  String get exportSuccess => 'Export successful';

  @override
  String get exportFailed => 'Export failed';

  @override
  String get noApiKey => 'Please enter your API key in Settings';

  @override
  String get fileLimitWarning => 'You can select 1 to 10 files only';

  @override
  String get retryTranscription => 'Retry';

  @override
  String get allFatwas => 'All Fatwas';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get playAudio => 'Play Audio';

  @override
  String get pauseAudio => 'Pause';

  @override
  String get audioNotFound => 'Audio file not found';
}
