import 'package:flutter/material.dart';
import '../models/medication.dart'; // Importez le modèle Medication
import '../services/medication_data_service.dart'; // Importez le service
import '../utils/date_utils.dart'; // Importez les utilitaires de date
import 'package:url_launcher/url_launcher.dart'; // Pour lancer WhatsApp

// Gère l'état de l'application et la logique métier.
class MedicationProvider with ChangeNotifier {
  List<Medication> _medications = [];
  DateTime _selectedDate = DateTime.now();
  final String _whatsappNumber = "+237657624346"; // Numéro WhatsApp par défaut

  final MedicationDataService medicationService; // Dépendance injectée

  List<Medication> get medications => _medications;
  DateTime get selectedDate => _selectedDate;
  String get whatsappNumber => _whatsappNumber;

  MedicationProvider({required this.medicationService}) {
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    _medications = await medicationService.loadMedications();
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  List<Medication> getMedicationsForSelectedDay() {
    return _medications.where((med) {
      return med.getMedicationDays().any((day) => isSameDay(day, _selectedDate));
    }).toList();
  }

  // Marquer une prise de médicament comme effectuée
  void markMedicationTimeAsTaken(
      Medication medication, DateTime date, String time) {
    medication.markAsTaken(date, time);
    notifyListeners();
  }

  // Lancer WhatsApp
  Future<void> launchWhatsApp(String message) async {
    final Uri whatsappUri =
    Uri.parse('whatsapp://send?phone=$_whatsappNumber&text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    } else {
      debugPrint('Impossible de lancer WhatsApp. Assurez-vous qu\'il est installé.');
      // Gérer l'erreur, par exemple afficher un SnackBar
    }
  }
}
