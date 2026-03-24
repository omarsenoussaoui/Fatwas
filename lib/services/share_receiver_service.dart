import 'package:flutter/services.dart';

/// Service to receive audio files shared from other apps (Telegram, WhatsApp, etc.)
/// Uses a MethodChannel to communicate with the native Android side.
class ShareReceiverService {
  static const _channel = MethodChannel('com.fatwas.fatwas_app/share');

  /// Callback when files are shared while the app is already running
  static Function(List<String> filePaths)? onSharedFiles;

  /// Initialize the listener for incoming shared files
  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedFiles') {
        final files = (call.arguments as List).cast<String>();
        if (files.isNotEmpty) {
          onSharedFiles?.call(files);
        }
      }
    });
  }

  /// Check if the app was launched via a share intent (cold start)
  /// Returns file paths or null if no pending shared files
  static Future<List<String>?> getInitialSharedFiles() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getSharedFiles');
      if (result != null && result.isNotEmpty) {
        return result.cast<String>();
      }
    } on PlatformException {
      // Channel not available (e.g. running on web/desktop)
    }
    return null;
  }
}
