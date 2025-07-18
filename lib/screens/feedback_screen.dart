import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../providers/feedback_provider.dart';
import '../models/feedback_model.dart';
import '../l10n/generated/app_localizations.dart';
import '../widgets/language_selector.dart';
import '../widgets/emotion_selector.dart';
import '../widgets/voice_recorder.dart';
import '../widgets/speech_to_text_button.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      context.read<FeedbackProvider>().updateTextFeedback(_textController.text);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FeedbackProvider>();

    if (provider.rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseFillRequired),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await provider.submitFeedback('patient_123'); // Replace with actual patient ID

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.thankYou),
            content: Text(AppLocalizations.of(context)!.feedbackSubmitted),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  provider.resetForm();
                  _textController.clear();
                },
                child: Text(AppLocalizations.of(context)!.ok),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.error}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.patientFeedback),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Consumer<FeedbackProvider>(
        builder: (context, provider, child) {
          // Update text controller when speech text changes
          if (provider.speechText.isNotEmpty &&
              _textController.text != provider.speechText) {
            _textController.text = provider.speechText;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language Selector
                  const LanguageSelector(),
                  const SizedBox(height: 24),

                  // Main Question
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.howWasYourExperience,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Star Rating
                          Text(
                            localizations.overallRating,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: RatingBar.builder(
                              initialRating: provider.rating,
                              minRating: 1,
                              direction: Axis.horizontal,
                              allowHalfRating: true,
                              itemCount: 5,
                              itemSize: 40,
                              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                              itemBuilder: (context, _) => const Icon(
                                Icons.star,
                                color: Colors.amber,
                              ),
                              onRatingUpdate: (rating) {
                                provider.updateRating(rating);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Emotion Selector
                          Text(
                            localizations.howDoYouFeel,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const EmotionSelector(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Text Feedback Section
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.additionalComments,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Text Input with Speech-to-Text
                          TextFormField(
                            controller: _textController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: localizations.writeYourFeedback,
                              border: const OutlineInputBorder(),
                              suffixIcon: const SpeechToTextButton(),
                            ),
                            validator: (value) {
                              if (provider.rating > 0 && (value?.isEmpty ?? true)) {
                                return localizations.pleaseFillRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Voice Recording
                          const VoiceRecorder(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        localizations.submitFeedback,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}