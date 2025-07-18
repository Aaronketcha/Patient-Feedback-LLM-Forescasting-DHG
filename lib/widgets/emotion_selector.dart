import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feedback_provider.dart';
import '../models/feedback_model.dart';
import '../l10n/generated/app_localizations.dart';

class EmotionSelector extends StatelessWidget {
  const EmotionSelector({Key? key}) : super(key: key);

  String _getEmotionLabel(BuildContext context, String labelKey) {
    final localizations = AppLocalizations.of(context)!;

    switch (labelKey) {
      case 'veryHappy':
        return localizations.veryHappy;
      case 'happy':
        return localizations.happy;
      case 'neutral':
        return localizations.neutral;
      case 'sad':
        return localizations.sad;
      case 'verySad':
        return localizations.verySad;
      default:
        return labelKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FeedbackProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: FeedbackConstants.emotions.map((emotion) {
              final isSelected = provider.selectedEmotion == emotion.type;

              return GestureDetector(
                onTap: () => provider.updateSelectedEmotion(emotion.type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue[100]
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.blue[700]!
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        emotion.emoji,
                        style: TextStyle(
                          fontSize: isSelected ? 32 : 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getEmotionLabel(context, emotion.labelKey),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Colors.blue[700]
                              : Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}