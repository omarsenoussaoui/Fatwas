import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';
import 'package:just_audio/just_audio.dart';
import '../l10n/app_localizations.dart';
import '../models/fatwa.dart';
import '../providers/fatwa_provider.dart';
import '../theme.dart';

class FatwaDetailScreen extends StatefulWidget {
  final Fatwa fatwa;

  const FatwaDetailScreen({super.key, required this.fatwa});

  @override
  State<FatwaDetailScreen> createState() => _FatwaDetailScreenState();
}

class _FatwaDetailScreenState extends State<FatwaDetailScreen> {
  late TextEditingController _controller;
  late TextEditingController _titleController;
  late Fatwa _fatwa;
  bool _isEditing = false;
  bool _isFormatting = false;

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _audioAvailable = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;

  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    _fatwa = widget.fatwa;
    _controller = TextEditingController(text: _fatwa.transcription ?? '');
    _titleController = TextEditingController(text: _fatwa.title ?? '');
    _initAudio();
  }

  Future<void> _initAudio() async {
    final path = _fatwa.filePath;
    if (path == null || !await File(path).exists()) return;

    try {
      final duration = await _audioPlayer.setFilePath(path);
      if (duration != null && mounted) {
        setState(() {
          _duration = duration;
          _audioAvailable = true;
        });
      }

      _audioPlayer.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) setState(() {});
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlayPause() async {
    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      if (_audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
      }
      await _audioPlayer.play();
    }
  }

  Future<void> _rewind5() async {
    final newPos = _position - const Duration(seconds: 5);
    await _audioPlayer.seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  Future<void> _forward5() async {
    final newPos = _position + const Duration(seconds: 5);
    await _audioPlayer.seek(newPos > _duration ? _duration : newPos);
  }

  Future<void> _cycleSpeed() async {
    final currentIdx = _speeds.indexOf(_playbackSpeed);
    final nextIdx = (currentIdx + 1) % _speeds.length;
    _playbackSpeed = _speeds[nextIdx];
    await _audioPlayer.setSpeed(_playbackSpeed);
    setState(() {});
  }

  void _showTitleDialog(BuildContext context, AppLocalizations l10n) {
    _titleController.text = _fatwa.title ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editTitle),
        content: TextField(
          controller: _titleController,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(hintText: l10n.titleHint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final newTitle = _titleController.text.trim();
              context.read<FatwaProvider>().updateTitle(_fatwa, newTitle);
              setState(() => _fatwa = _fatwa.copyWith(title: newTitle));
              Navigator.pop(ctx);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Future<void> _shareText() async {
    final text = '${_fatwa.displayTitle}\n'
        'الشيخ بن حنيفية زين العابدين\n\n'
        '${_fatwa.transcription ?? ''}';
    await Share.share(text);
  }

  Future<void> _copyText(AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: _fatwa.transcription ?? ''));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.copiedToClipboard)),
      );
    }
  }

  Future<void> _autoFormat(AppLocalizations l10n) async {
    setState(() => _isFormatting = true);
    try {
      final formatted = await context.read<FatwaProvider>().autoFormatTranscription(_fatwa);
      _controller.text = formatted;
      setState(() {
        _fatwa = _fatwa.copyWith(transcription: formatted);
        _isFormatting = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.formatSuccess)),
        );
      }
    } catch (e) {
      setState(() => _isFormatting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.formatFailed}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('yyyy/MM/dd - EEEE',
            Localizations.localeOf(context).languageCode)
        .format(_fatwa.createdAt);

    final isPlaying = _audioPlayer.playing;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _showTitleDialog(context, l10n),
          child: Text(
            _fatwa.displayTitle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          // Share text
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: l10n.shareText,
            onPressed: _shareText,
          ),
          // Edit toggle
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            tooltip: _isEditing ? l10n.save : l10n.edit,
            onPressed: () {
              if (_isEditing) {
                context
                    .read<FatwaProvider>()
                    .updateTranscription(_fatwa, _controller.text);
                _fatwa = _fatwa.copyWith(transcription: _controller.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.save)),
                );
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
          // More menu
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'docx':
                  _exportFatwa(context);
                case 'pdf':
                  _exportPdf(context);
                case 'copy':
                  _copyText(l10n);
                case 'title':
                  _showTitleDialog(context, l10n);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'docx', child: Text(l10n.downloadDocx)),
              PopupMenuItem(value: 'pdf', child: Text(l10n.downloadPdf)),
              PopupMenuItem(value: 'copy', child: Text(l10n.copiedToClipboard)),
              PopupMenuItem(value: 'title', child: Text(l10n.editTitle)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
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
                        const Text('﷽',
                            style: TextStyle(color: Colors.white, fontSize: 28)),
                        const SizedBox(height: 12),
                        Text(
                          l10n.sheikhName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(dateStr,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info row: file name + word count
                  Row(
                    children: [
                      Icon(Icons.audio_file,
                          color: AppTheme.primaryGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fatwa.fileName,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ),
                      Text(
                        l10n.words(_fatwa.wordCount),
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),

                  // AI Auto-Format button (only in edit mode)
                  if (_isEditing) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isFormatting ? null : () => _autoFormat(l10n),
                      icon: _isFormatting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_fix_high, size: 18),
                      label: Text(
                          _isFormatting ? l10n.formatting : l10n.autoFormat),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.autoFormatDesc,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ],

                  const Divider(height: 24),

                  // Transcription text
                  if (_isEditing)
                    TextField(
                      controller: _controller,
                      maxLines: null,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: l10n.edit,
                      ),
                      style: const TextStyle(fontSize: 16, height: 2.0),
                    )
                  else
                    SelectableText(
                      _controller.text,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 16, height: 2.0),
                    ),

                  if (_audioAvailable) const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Sticky audio player at the bottom
          if (_audioAvailable)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Seek bar
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.primaryGreen,
                          inactiveTrackColor:
                              AppTheme.primaryGreen.withAlpha(50),
                          thumbColor: AppTheme.primaryGreen,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          trackHeight: 3,
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14),
                        ),
                        child: Slider(
                          min: 0,
                          max: _duration.inMilliseconds
                              .toDouble()
                              .clamp(1, double.infinity),
                          value: _position.inMilliseconds
                              .toDouble()
                              .clamp(
                                  0, _duration.inMilliseconds.toDouble()),
                          onChanged: (value) {
                            _audioPlayer.seek(
                                Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),

                      // Time labels
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(_formatDuration(_position),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                            const Spacer(),
                            Text(_formatDuration(_duration),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Playback controls with speed
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Speed button
                          GestureDetector(
                            onTap: _cycleSpeed,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_playbackSpeed}x',
                                style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Rewind 5s
                          IconButton(
                            icon: const Icon(Icons.replay_5),
                            iconSize: 28,
                            color: AppTheme.primaryGreen,
                            onPressed: _rewind5,
                          ),
                          const SizedBox(width: 8),

                          // Play/Pause
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow),
                              iconSize: 32,
                              color: Colors.white,
                              onPressed: _togglePlayPause,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Forward 5s
                          IconButton(
                            icon: const Icon(Icons.forward_5),
                            iconSize: 28,
                            color: AppTheme.primaryGreen,
                            onPressed: _forward5,
                          ),

                          const SizedBox(width: 16),
                          // Placeholder for symmetry
                          const SizedBox(width: 48),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_fatwa.filePath != null)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withAlpha(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(l10n.audioNotFound,
                      style:
                          const TextStyle(color: Colors.orange, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _exportFatwa(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final path =
          await context.read<FatwaProvider>().exportSingleFatwa(_fatwa);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportSuccess)),
      );
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${l10n.exportFailed}: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = await context.read<FatwaProvider>().exportSinglePdf(_fatwa);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportSuccess)),
      );
      await Share.shareXFiles([XFile(path)]);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${l10n.exportFailed}: $e'),
            backgroundColor: Colors.red),
      );
    }
  }
}
