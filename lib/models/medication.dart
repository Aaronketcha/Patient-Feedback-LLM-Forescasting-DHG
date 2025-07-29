// import 'dart:math';
// import 'package:intl/intl.dart';
//
// // Définit la structure de données pour un médicament.
// class Medication {
//   final String id;
//   final String medicationName;
//   final DateTime startDate;
//   final DateTime endDate;
//   final int duration; // en jours
//   final String dosage; // ex: "3 times/day"
//   final List<String> times; // ex: ["09:00", "14:00", "20:00"]
//   final String image;
//   final String frequency; // ex: "daily", "every 2 days"
//   final String clientId;
//   Map<String, bool> takenTimes; // Pour suivre les prises pour chaque jour
//
//   Medication({
//     required this.id,
//     required this.medicationName,
//     required this.startDate,
//     required this.endDate,
//     required this.duration,
//     required this.dosage,
//     required this.times,
//     required this.image,
//     required this.frequency,
//     required this.clientId,
//     Map<String, bool>? takenTimes,
//   }) : takenTimes = takenTimes ?? {};
//
//   factory Medication.fromJson(Map<String, dynamic> json, DateTime startDate) {
//     final int duration = json['duration'];
//     final DateTime endDate = startDate.add(Duration(days: duration - 1));
//
//     // Générer aléatoirement la dose et les heures si non spécifié
//     final List<String> possibleDosages = [
//       "1 time/day",
//       "2 times/day",
//       "3 times/day",
//       "4 times/day"
//     ];
//     final List<List<String>> possibleTimes = [
//       ["09:00"],
//       ["09:00", "18:00"],
//       ["09:00", "14:00", "20:00"],
//       ["08:00", "12:00", "17:00", "22:00"]
//     ];
//
//     int dosageIndex = Random().nextInt(possibleDosages.length);
//     int timesIndex = dosageIndex;
//     if (timesIndex >= possibleTimes.length) {
//       timesIndex = possibleTimes.length - 1;
//     }
//
//     return Medication(
//       id: json['id'],
//       medicationName: json['medicationName'],
//       startDate: startDate,
//       endDate: endDate,
//       duration: duration,
//       dosage: json['dosage'] ?? possibleDosages[dosageIndex],
//       times: List<String>.from(json['times'] ?? possibleTimes[timesIndex]),
//       image: json['image'],
//       frequency: json['frequency'],
//       clientId: json['clientId'],
//     );
//   }
//
//   // Méthode pour obtenir les jours où le médicament doit être pris
//   List<DateTime> getMedicationDays() {
//     List<DateTime> days = [];
//     DateTime currentDay = startDate;
//     int dayCount = 0;
//
//     // Convertir la fréquence en jours numériques
//     int frequencyDays = 1; // Par défaut, quotidien
//     if (frequency.startsWith('every ')) {
//       try {
//         frequencyDays = int.parse(frequency.split(' ')[1]);
//       } catch (e) {
//         print('Erreur de parsing de fréquence: $e');
//       }
//     }
//
//     while (currentDay.isBefore(endDate.add(const Duration(days: 1)))) {
//       if (dayCount % frequencyDays == 0) {
//         days.add(DateTime(currentDay.year, currentDay.month, currentDay.day));
//       }
//       currentDay = currentDay.add(const Duration(days: 1));
//       dayCount++;
//     }
//     return days;
//   }
//
//   // Méthode pour marquer une prise
//   void markAsTaken(DateTime date, String time) {
//     final dateKey = DateFormat('yyyy-MM-dd').format(date);
//     final key = '$dateKey-$time';
//     takenTimes[key] = true;
//   }
//
//   // Méthode pour vérifier si une prise est marquée comme prise
//   bool isTaken(DateTime date, String time) {
//     final dateKey = DateFormat('yyyy-MM-dd').format(date);
//     final key = '$dateKey-$time';
//     return takenTimes.containsKey(key) && takenTimes[key] == true;
//   }
//
//   // Méthode pour réinitialiser les prises pour un jour donné
//   void resetTakenTimesForDay(DateTime date) {
//     final dateKey = DateFormat('yyyy-MM-dd').format(date);
//     takenTimes.keys.toList().forEach((key) {
//       if (key.startsWith(dateKey)) {
//         takenTimes.remove(key);
//       }
//     });
//   }
// }


import 'dart:math';
import 'package:intl/intl.dart';

// Définit la structure de données pour un médicament.
class Medication {
  final String id;
  final String medicationName;
  final DateTime startDate;
  final DateTime endDate;
  final int duration; // en jours
  final String dosage; // ex: "3 times/day"
  final List<String> times; // ex: ["09:00", "14:00", "20:00"]
  final String image;
  final String frequency; // ex: "daily", "every 2 days"
  final String phoneNumber; // Changé de clientId à phoneNumber
  Map<String, bool> takenTimes; // Pour suivre les prises pour chaque jour

  Medication({
    required this.id,
    required this.medicationName,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.dosage,
    required this.times,
    required this.image,
    required this.frequency,
    required this.phoneNumber,
    Map<String, bool>? takenTimes,
  }) : takenTimes = takenTimes ?? {};

  factory Medication.fromJson(Map<String, dynamic> json) {
    // La startDate est maintenant lue directement depuis le JSON
    final DateTime startDate = DateTime.parse(json['startDate']);
    final int duration = json['duration'];
    final DateTime endDate = startDate.add(Duration(days: duration - 1));

    // Générer aléatoirement la dose et les heures si non spécifié (logique conservée pour la flexibilité)
    final List<String> possibleDosages = [
      "1 time/day",
      "2 times/day",
      "3 times/day",
      "4 times/day"
    ];
    final List<List<String>> possibleTimes = [
      ["09:00"],
      ["09:00", "18:00"],
      ["09:00", "14:00", "20:00"],
      ["08:00", "12:00", "17:00", "22:00"]
    ];

    int dosageIndex = Random().nextInt(possibleDosages.length);
    int timesIndex = dosageIndex;
    if (timesIndex >= possibleTimes.length) {
      timesIndex = possibleTimes.length - 1;
    }

    return Medication(
      id: json['id'],
      medicationName: json['medicationName'],
      startDate: startDate,
      endDate: endDate,
      duration: duration,
      dosage: json['dosage'] ?? possibleDosages[dosageIndex],
      times: List<String>.from(json['times'] ?? possibleTimes[timesIndex]),
      image: json['image'],
      frequency: json['frequency'],
      phoneNumber: json['phoneNumber'], // Lire le numéro de téléphone
    );
  }

  // Méthode pour obtenir les jours où le médicament doit être pris
  List<DateTime> getMedicationDays() {
    List<DateTime> days = [];
    DateTime currentDay = startDate;
    int dayCount = 0;

    // Convertir la fréquence en jours numériques
    int frequencyDays = 1; // Par défaut, quotidien
    if (frequency.startsWith('every ')) {
      try {
        frequencyDays = int.parse(frequency.split(' ')[1]);
      } catch (e) {
        print('Erreur de parsing de fréquence: $e');
      }
    }

    while (currentDay.isBefore(endDate.add(const Duration(days: 1)))) {
      if (dayCount % frequencyDays == 0) {
        days.add(DateTime(currentDay.year, currentDay.month, currentDay.day));
      }
      currentDay = currentDay.add(const Duration(days: 1));
      dayCount++;
    }
    return days;
  }

  // Méthode pour marquer une prise
  void markAsTaken(DateTime date, String time) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final key = '$dateKey-$time';
    takenTimes[key] = true;
  }

  // Méthode pour vérifier si une prise est marquée comme prise
  bool isTaken(DateTime date, String time) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final key = '$dateKey-$time';
    return takenTimes.containsKey(key) && takenTimes[key] == true;
  }

  // Méthode pour réinitialiser les prises pour un jour donné
  void resetTakenTimesForDay(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    takenTimes.keys.toList().forEach((key) {
      if (key.startsWith(dateKey)) {
        takenTimes.remove(key);
      }
    });
  }
}
