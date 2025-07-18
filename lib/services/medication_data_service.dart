import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/medication.dart'; // Importez le modèle Medication

// Gère le chargement des données brutes des médicaments.
class MedicationDataService {
  Future<List<Medication>> loadMedications() async {
    try {
      final String response =
      await rootBundle.loadString('lib/assets/data/medications.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) {
        // Pour simuler une date de début réaliste, nous allons fixer la date de début
        // de toutes les médications à une date récente ou à aujourd'hui.
        return Medication.fromJson(json, DateTime.now().subtract(const Duration(days: 2)));
      }).toList();
    } catch (e) {
      print('Erreur lors du chargement des médicaments via service: $e');
      return []; // Retourne une liste vide en cas d'erreur
    }
  }
}
