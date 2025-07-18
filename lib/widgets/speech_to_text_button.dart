import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feedback_provider.dart';
import '../l10n/generated/app_localizations.dart';

class SpeechToTextButton extends StatelessWidget {
  const SpeechToTextButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<FeedbackProvider>(
      builder: (context, provider, child) {
        return IconButton(
          onPressed: provider.speechEnabled
              ? () => provider.toggleListening()
              : null,
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              provider.isListening
                  ? Icons.mic
                  : Icons.mic_none,
              color: provider.isListening
                  ? Colors.red
                  : (provider.speechEnabled ? Colors.blue[700] : Colors.grey),
            ),
          ),
          tooltip: provider.isListening
              ? localizations.listening
              : localizations.tapToSpeak,
        );
      },
    );
  }
}