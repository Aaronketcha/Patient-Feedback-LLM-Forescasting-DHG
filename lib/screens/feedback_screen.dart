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
    if (provider.rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillRequired),
            backgroundColor: Colors.red),
      );
      return;
    }
    final fb = await provider.submitFeedback('patient_123');
    if (mounted) {
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.thankYou),
        content: Text('${AppLocalizations.of(context)!.feedbackSubmitted}\n\n'
            'Dept : ${fb.department}\nUrgent : ${fb.isUrgent ? "Oui" : "Non"}'),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(context);
            provider.resetForm();
            _textController.clear();
          }, child: Text(AppLocalizations.of(context)!.ok)),
        ],
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.patientFeedback),
        backgroundColor: Colors.blue[700],
      ),
      body: Consumer<FeedbackProvider>(
        builder: (context, prov, _) {
          if (prov.speechText.isNotEmpty && _textController.text != prov.speechText) {
            _textController.text = prov.speechText;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const LanguageSelector(),
                const SizedBox(height: 24),
                Card(elevation:2, child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                    Text(loc.howWasYourExperience,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                    const SizedBox(height: 16),
                    Text(loc.overallRating,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Center(child: RatingBar.builder(
                      initialRating: prov.rating,
                      minRating:1, allowHalfRating:true,
                      itemCount:5, itemSize:40,
                      itemBuilder:(_,__)=>const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: prov.updateRating,
                    )),
                    const SizedBox(height: 16),
                    Text(loc.howDoYouFeel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const EmotionSelector(),
                  ]),
                )),
                const SizedBox(height: 24),

                // Department dropdown
                Text(loc.selectDepartment ?? 'Quel service utilisé ?',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: prov.selectedDepartment,
                  items: ['Accueil','Urgences','Laboratoire','Pharmacie','Radiologie']
                      .map((d) => DropdownMenuItem(value:d, child:Text(d))).toList(),
                  onChanged: prov.updateDepartment,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: (v)=> v==null||v.isEmpty
                      ? loc.pleaseFillRequired : null,
                ),

                const SizedBox(height: 24),
                Text(loc.isUrgent ?? 'Ce message est-il urgent ?',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children:[
                  const Text('Non'),
                  Switch(value: prov.isUrgent, onChanged: prov.updateUrgency, activeColor: Colors.red[700]),
                  const Text('Oui'),
                ]),

                const SizedBox(height: 24),
                Card(elevation:2, child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                    Text(loc.additionalComments,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _textController,
                      maxLines:4,
                      decoration: InputDecoration(
                        hintText: loc.writeYourFeedback,
                        border: const OutlineInputBorder(),
                        suffixIcon: const SpeechToTextButton(),
                      ),
                      validator: (v) => prov.rating>0 && (v==null || v.isEmpty)
                          ? loc.pleaseFillRequired : null,
                    ),
                    const SizedBox(height: 16),
                    const VoiceRecorder(),
                  ]),
                )),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity, height:56,
                  child: ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(loc.submitFeedback,
                        style: const TextStyle(fontSize:18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
