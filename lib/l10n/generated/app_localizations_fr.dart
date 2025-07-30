// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Système de Commentaires Hospitaliers';

  @override
  String get patientFeedback => 'Commentaires des Patients';

  @override
  String get howWasYourExperience => 'Comment s\'est passée votre expérience?';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get selectDepartment => 'Quel service utilisé ?';

  @override
  String get isUrgent => 'Ce message est-il urgent ?';

  @override
  String get overallRating => 'Note globale';

  @override
  String get writeYourFeedback => 'Écrivez vos commentaires ici...';

  @override
  String get speakYourFeedback => 'Parlez vos commentaires';

  @override
  String get recordVoice => 'Enregistrer la voix';

  @override
  String get stopRecording => 'Arrêter l\'enregistrement';

  @override
  String get playRecording => 'Lire l\'enregistrement';

  @override
  String get deleteRecording => 'Supprimer l\'enregistrement';

  @override
  String get submitFeedback => 'Soumettre les commentaires';

  @override
  String get thankYou => 'Merci!';

  @override
  String get feedbackSubmitted => 'Vos commentaires ont été soumis avec succès';

  @override
  String get pleaseFillRequired => 'Veuillez remplir les champs obligatoires';

  @override
  String get permissionDenied => 'Permission refusée';

  @override
  String get microphonePermission =>
      'L\'autorisation du microphone est requise pour l\'enregistrement vocal';

  @override
  String get listening => 'Écoute...';

  @override
  String get tapToSpeak => 'Appuyez pour parler';

  @override
  String get howDoYouFeel =>
      'Comment vous sentez-vous par rapport à votre expérience?';

  @override
  String get veryHappy => 'Très heureux';

  @override
  String get happy => 'Heureux';

  @override
  String get neutral => 'Neutre';

  @override
  String get sad => 'Triste';

  @override
  String get verySad => 'Très triste';

  @override
  String get additionalComments => 'Commentaires supplémentaires';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Erreur';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get recording => 'Enregistrement...';
}
