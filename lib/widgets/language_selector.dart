import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feedback_provider.dart';
import '../models/feedback_model.dart';
import '../l10n/generated/app_localizations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<FeedbackProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.language,
                  color: Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  localizations.selectLanguage,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                DropdownButton<String>(
                  value: provider.currentLanguage,
                  underline: Container(),
                  icon: const Icon(Icons.arrow_drop_down),
                  items: FeedbackConstants.supportedLanguages.map((language) {
                    return DropdownMenuItem<String>(
                      value: language['code'],
                      child: Text(language['name']!),
                    );
                  }).toList(),
                  onChanged: (String? newLanguage) {
                    if (newLanguage != null) {
                      provider.changeLanguage(newLanguage);

                      // Change app locale
                      final locale = Locale(newLanguage);
                      // Note: In a real app, you'd use a localization provider
                      // to change the app's locale dynamically
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}