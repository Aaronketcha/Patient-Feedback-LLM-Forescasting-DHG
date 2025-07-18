import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour DateFormat

// Importez les modèles et utilitaires nécessaires
import '../models/medication.dart';
import '../utils/date_utils.dart';

// Un widget réutilisable pour afficher la barre de calendrier journalière.
class DailyCalendarBar extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final List<Medication> medications;

  const DailyCalendarBar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.medications,
  });

  @override
  Widget build(BuildContext context) {
    // Obtenir les 7 jours à partir de la date sélectionnée (centrée si possible)
    List<DateTime> weekDays = [];
    DateTime startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1)); // Lundi de la semaine

    for (int i = 0; i < 7; i++) {
      weekDays.add(startOfWeek.add(Duration(days: i)));
    }

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: weekDays.map((date) {
          final bool isSelected = isSameDay(date, selectedDate);
          final bool hasMedication = medications.any((med) =>
              med.getMedicationDays().any((medDay) => isSameDay(medDay, date)));

          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.pinkAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('EEE', 'fr_FR').format(date).substring(0, 3), // Jour de la semaine (Lun, Mar, etc.)
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd').format(date), // Numéro du jour
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.pinkAccent : Colors.black87,
                  ),
                ),
                if (hasMedication)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration:  BoxDecoration(
                      color: Colors.blue[700],
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
