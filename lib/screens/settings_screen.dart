import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/fatwa_provider.dart';
import '../providers/locale_provider.dart';
import '../services/whisper_service.dart';
import '../constants.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isTesting = false;
  String? _testResult; // 'success', 'failed', or null
  bool _isUsingCustomKey = false;

  String get _defaultKey => defaultGroqApiKey;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final customKey = prefs.getString('groq_api_key');

    if (customKey != null && customKey.isNotEmpty) {
      _apiKeyController.text = customKey;
      _isUsingCustomKey = true;
    } else {
      _apiKeyController.text = _defaultKey;
      _isUsingCustomKey = false;
    }

    if (mounted) {
      context.read<FatwaProvider>().setApiKey(_apiKeyController.text);
      setState(() {});
    }
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == _defaultKey || key.isEmpty) {
      await prefs.remove('groq_api_key');
      _isUsingCustomKey = false;
    } else {
      await prefs.setString('groq_api_key', key);
      _isUsingCustomKey = true;
    }
    if (mounted) {
      final activeKey = key.isEmpty ? _defaultKey : key;
      context.read<FatwaProvider>().setApiKey(activeKey);
      setState(() {
        _testResult = null;
      });
    }
  }

  Future<void> _resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('groq_api_key');
    _apiKeyController.text = _defaultKey;
    _isUsingCustomKey = false;
    if (mounted) {
      context.read<FatwaProvider>().setApiKey(_defaultKey);
      setState(() {
        _testResult = null;
      });
    }
  }

  Future<void> _testKey() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final key = _apiKeyController.text.trim();
    final isValid = await GroqWhisperService.testApiKey(key);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testResult = isValid ? 'success' : 'failed';
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sheikh name header
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
                const Text(
                  '﷽',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.sheikhName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Language section
          Text(
            l10n.language,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: RadioGroup<String>(
              groupValue: localeProvider.locale.languageCode,
              onChanged: (value) {
                if (value != null) localeProvider.setLocale(Locale(value));
              },
              child: Column(
                children: [
                  ListTile(
                    title: Text(l10n.arabic),
                    subtitle: const Text('العربية'),
                    leading: Radio<String>(
                      value: 'ar',
                    ),
                    onTap: () => localeProvider.setLocale(const Locale('ar')),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.english),
                    subtitle: const Text('English'),
                    leading: Radio<String>(
                      value: 'en',
                    ),
                    onTap: () => localeProvider.setLocale(const Locale('en')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // API Key section
          Text(
            l10n.apiKey,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isUsingCustomKey
                          ? Colors.blue.withAlpha(25)
                          : AppTheme.primaryGreen.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isUsingCustomKey ? Icons.person : Icons.lock,
                          size: 16,
                          color: _isUsingCustomKey ? Colors.blue : AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isUsingCustomKey ? l10n.usingCustomKey : l10n.usingDefaultKey,
                          style: TextStyle(
                            fontSize: 12,
                            color: _isUsingCustomKey ? Colors.blue : AppTheme.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // API key input
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      hintText: l10n.apiKeyHint,
                      prefixIcon: const Icon(Icons.key),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureKey ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscureKey = !_obscureKey);
                        },
                      ),
                    ),
                    onChanged: _saveApiKey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Groq Whisper Large V3 API',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Test Key + Reset buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTesting || _apiKeyController.text.isEmpty
                              ? null
                              : _testKey,
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.verified_user, size: 18),
                          label: Text(
                            _isTesting ? l10n.testingKey : l10n.testKey,
                          ),
                        ),
                      ),
                      if (_isUsingCustomKey) ...[
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _resetToDefault,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryGreen),
                          ),
                          child: Text(l10n.resetToDefault),
                        ),
                      ],
                    ],
                  ),

                  // Test result
                  if (_testResult != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _testResult == 'success'
                            ? Colors.green.withAlpha(25)
                            : Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _testResult == 'success'
                              ? Colors.green.withAlpha(100)
                              : Colors.red.withAlpha(100),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _testResult == 'success'
                                ? Icons.check_circle
                                : Icons.error,
                            color: _testResult == 'success'
                                ? Colors.green
                                : Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _testResult == 'success'
                                ? l10n.testKeySuccess
                                : l10n.testKeyFailed,
                            style: TextStyle(
                              color: _testResult == 'success'
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
