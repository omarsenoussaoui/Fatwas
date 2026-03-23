import 'dart:io';
import 'package:flutter/material.dart';
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
  bool _isEditing = false;

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _audioAvailable = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.fatwa.transcription ?? '');
    _initAudio();
  }

  Future<void> _initAudio() async {
    final path = widget.fatwa.filePath;
    if (path == null || !await File(path).exists()) {
      return;
    }

    try {
      final duration = await _audioPlayer.setFilePath(path);
      if (duration != null && mounted) {
        setState(() {
          _duration = duration;
          _audioAvailable = true;
        });
      }

      // Listen to position changes
      _audioPlayer.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });

      // Listen to player state to update UI when audio completes
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) setState(() {});
      });
    } catch (_) {
      // Audio file can't be loaded — keep player hidden
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
      // If completed, seek to start before playing
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = DateFormat('yyyy/MM/dd - EEEE',
            Localizations.localeOf(context).languageCode)
        .format(widget.fatwa.createdAt);

    final isPlaying = _audioPlayer.playing;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fatwa.fileName),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            tooltip: _isEditing ? l10n.save : l10n.edit,
            onPressed: () {
              if (_isEditing) {
                context
                    .read<FatwaProvider>()
                    .updateTranscription(widget.fatwa, _controller.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.save)),
                );
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: l10n.downloadDocx,
            onPressed: () => _exportFatwa(context),
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
                        const Text(
                          '﷽',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                          ),
                        ),
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
                          child: Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Audio file info
                  Row(
                    children: [
                      Icon(Icons.audio_file,
                          color: AppTheme.primaryGreen, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.fatwa.fileName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                      style: const TextStyle(
                        fontSize: 16,
                        height: 2.0,
                      ),
                    )
                  else
                    SelectableText(
                      _controller.text,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 2.0,
                      ),
                    ),

                  // Bottom padding so text isn't hidden behind player
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
                          max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                          value: _position.inMilliseconds
                              .toDouble()
                              .clamp(0, _duration.inMilliseconds.toDouble()),
                          onChanged: (value) {
                            _audioPlayer
                                .seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),

                      // Time labels + controls
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            const Spacer(),
                            Text(
                              _formatDuration(_duration),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Playback controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Rewind 5s
                          IconButton(
                            icon: const Icon(Icons.replay_5),
                            iconSize: 28,
                            color: AppTheme.primaryGreen,
                            onPressed: _rewind5,
                          ),
                          const SizedBox(width: 12),

                          // Play/Pause button
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                              ),
                              iconSize: 32,
                              color: Colors.white,
                              onPressed: _togglePlayPause,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Forward 5s
                          IconButton(
                            icon: const Icon(Icons.forward_5),
                            iconSize: 28,
                            color: AppTheme.primaryGreen,
                            onPressed: _forward5,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (widget.fatwa.filePath != null)
            // Audio file not found message
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.orange.withAlpha(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l10n.audioNotFound,
                    style: const TextStyle(color: Colors.orange, fontSize: 13),
                  ),
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
      final provider = context.read<FatwaProvider>();
      final path = await provider.exportSingleFatwa(widget.fatwa);
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
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
