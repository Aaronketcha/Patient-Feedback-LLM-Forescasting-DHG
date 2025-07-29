import 'dart:convert';
import 'package:http/http.dart' as http; // Importez le package http
import '../models/medication.dart'; // Importez le modèle Medication

// Gère le chargement des données brutes des médicaments via une API HTTP.
class MedicationDataService {
  final String baseUrl;

  MedicationDataService({required this.baseUrl});

  Future<List<Medication>> loadMedications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/medications'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Medication.fromJson(json)).toList();
      } else {
        print('Erreur lors du chargement des médicaments depuis l\'API: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Erreur de connexion lors du chargement des médicaments: $e');
      return []; // Retourne une liste vide en cas d'erreur
    }
  }
}
