import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/fatwa.dart';
import '../providers/fatwa_provider.dart';
import '../theme.dart';
import 'fatwa_detail_screen.dart';
import 'upload_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FatwaProvider>().loadFatwas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final provider = context.watch<FatwaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.sheikhName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (provider.fatwas.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: l10n.downloadAll,
              onPressed: () => _exportAll(context),
            ),
          if (provider.fatwas.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: l10n.clearAll,
              onPressed: () => _showClearAllDialog(context),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settings,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.fatwas.isEmpty
              ? _buildEmptyState(context, l10n)
              : _buildFatwaList(context, provider, l10n),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadScreen()),
          );
        },
        icon: const Icon(Icons.upload_file),
        label: Text(l10n.upload),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: AppTheme.primaryGreen.withAlpha(100),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noFatwas,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.noFatwasDescription,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFatwaList(
      BuildContext context, FatwaProvider provider, AppLocalizations l10n) {
    final grouped = provider.groupedFatwas;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final fatwas = grouped[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateHeader(context, date, l10n),
            ...fatwas.map((fatwa) => _buildFatwaCard(context, fatwa, l10n)),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(
      BuildContext context, DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    if (date == today) {
      dateText = l10n.today;
    } else if (date == yesterday) {
      dateText = l10n.yesterday;
    } else {
      final dayName = DateFormat('EEEE', Localizations.localeOf(context).languageCode)
          .format(date);
      dateText = '${DateFormat('yyyy/MM/dd').format(date)} - $dayName';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppTheme.primaryGreen.withAlpha(20),
      child: Text(
        dateText,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGreen,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFatwaCard(
      BuildContext context, Fatwa fatwa, AppLocalizations l10n) {
    final statusColor = _getStatusColor(fatwa.status);
    final statusText = _getStatusText(fatwa.status, l10n);

    return Dismissible(
      key: Key('fatwa_${fatwa.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _showDeleteDialog(context, l10n),
      onDismissed: (_) => context.read<FatwaProvider>().deleteFatwa(fatwa),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: fatwa.status == TranscriptionStatus.done
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FatwaDetailScreen(fatwa: fatwa),
                    ),
                  )
              : null,
          onLongPress: () async {
            final confirmed = await _showDeleteDialog(context, l10n);
            if (confirmed == true && context.mounted) {
              context.read<FatwaProvider>().deleteFatwa(fatwa);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mic, color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fatwa.fileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (fatwa.status == TranscriptionStatus.transcribing)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (fatwa.status == TranscriptionStatus.transcribing)
                            const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.sheikhName,
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (fatwa.transcription != null &&
                    fatwa.transcription!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    fatwa.transcription!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
                if (fatwa.status == TranscriptionStatus.error &&
                    fatwa.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fatwa.errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context
                            .read<FatwaProvider>()
                            .retryTranscription(fatwa),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: Text(l10n.retryTranscription),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TranscriptionStatus status) {
    switch (status) {
      case TranscriptionStatus.pending:
        return Colors.orange;
      case TranscriptionStatus.transcribing:
        return Colors.blue;
      case TranscriptionStatus.done:
        return Colors.green;
      case TranscriptionStatus.error:
        return Colors.red;
    }
  }

  String _getStatusText(TranscriptionStatus status, AppLocalizations l10n) {
    switch (status) {
      case TranscriptionStatus.pending:
        return l10n.pending;
      case TranscriptionStatus.transcribing:
        return l10n.transcribingStatus;
      case TranscriptionStatus.done:
        return l10n.done;
      case TranscriptionStatus.error:
        return l10n.error;
    }
  }

  Future<bool?> _showDeleteDialog(
      BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearAll),
        content: Text(l10n.clearAllDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              context.read<FatwaProvider>().clearAll();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAll(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final path = await context.read<FatwaProvider>().exportAllFatwas();
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
