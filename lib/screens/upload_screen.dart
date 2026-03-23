import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/app_localizations.dart';
import '../providers/fatwa_provider.dart';
import '../theme.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  List<PlatformFile> _selectedFiles = [];
  bool _isTranscribing = false;

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'flac', 'webm'],
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      if (result.files.length > 10) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.fileLimitWarning),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _selectedFiles = result.files.take(10).toList();
        });
      } else {
        setState(() {
          _selectedFiles = result.files;
        });
      }
    }
  }

  Future<void> _startTranscription() async {
    final provider = context.read<FatwaProvider>();
    final l10n = AppLocalizations.of(context)!;

    if (provider.apiKey == null || provider.apiKey!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noApiKey),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isTranscribing = true);

    final paths = _selectedFiles.map((f) => f.path!).toList();
    final names = _selectedFiles.map((f) => f.name).toList();

    await provider.addFatwas(paths, names);

    // Start transcription in background
    provider.transcribeAll();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.transcribing)),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.uploadFiles),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card with Islamic styling
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.primaryGreen.withAlpha(200),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    l10n.selectAudioFiles,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MP3, WAV, M4A (1-10 ${l10n.upload})',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Select files button
            OutlinedButton.icon(
              onPressed: _isTranscribing ? null : _pickFiles,
              icon: const Icon(Icons.folder_open),
              label: Text(l10n.selectFiles),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(height: 16),

            // Selected files count
            if (_selectedFiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.filesSelected(_selectedFiles.length),
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // File list
            Expanded(
              child: _selectedFiles.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.audio_file,
                              size: 64,
                              color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          Text(
                            l10n.selectAudioFiles,
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        final sizeKb = (file.size / 1024).toStringAsFixed(1);
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppTheme.primaryGreen.withAlpha(30),
                              child: Icon(Icons.audio_file,
                                  color: AppTheme.primaryGreen),
                            ),
                            title: Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text('$sizeKb KB'),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: _isTranscribing
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedFiles.removeAt(index);
                                      });
                                    },
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),

            // Transcribe button
            ElevatedButton.icon(
              onPressed: _selectedFiles.isEmpty || _isTranscribing
                  ? null
                  : _startTranscription,
              icon: _isTranscribing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.transcribe),
              label: Text(
                _isTranscribing ? l10n.transcribing : l10n.transcribe,
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
