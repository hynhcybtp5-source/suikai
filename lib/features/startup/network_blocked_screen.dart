import 'package:flutter/material.dart';

import '../../core/locale_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/mobile_localizations.dart';

class NetworkBlockedScreen extends StatefulWidget {
  const NetworkBlockedScreen({super.key, required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  State<NetworkBlockedScreen> createState() => _NetworkBlockedScreenState();
}

class _NetworkBlockedScreenState extends State<NetworkBlockedScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 56,
                    color: AppTheme.orange,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.ui('networkBlockedTitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.ui('networkBlockedMessage'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.ui('networkBlockedHint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _retrying ? null : _retry,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _retrying
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(l10n.ui('networkBlockedChecking')),
                              ],
                            )
                          : Text(l10n.ui('networkBlockedTryAgain')),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: _supportedLanguage(
                      localeController.locale.languageCode,
                    ),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.language_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'th', child: Text('ไทย')),
                      DropdownMenuItem(value: 'my', child: Text('မြန်မာ')),
                      DropdownMenuItem(value: 'shn', child: Text('လိၵ်ႈတႆး')),
                    ],
                    onChanged: (code) {
                      if (code != null) localeController.setLocale(code);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _supportedLanguage(String code) =>
      {'en', 'th', 'my', 'shn'}.contains(code) ? code : 'en';
}
