import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Pour DateFormat
import 'package:table_calendar/table_calendar.dart' hide isSameDay; // Pour le widget TableCalendar

// Importez les composants nécessaires
import '../models/medication.dart';
import '../providers/medication_provider.dart';
import '../widgets/medication_card.dart';
import '../utils/date_utils.dart'; // Importez les utilitaires de date

// Représente l'interface utilisateur de l'écran du calendrier complet.
class FullCalendarScreen extends StatefulWidget {
  const FullCalendarScreen({super.key});

  @override
  State<FullCalendarScreen> createState() => _FullCalendarScreenState();
}

class _FullCalendarScreenState extends State<FullCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final medicationProvider = Provider.of<MedicationProvider>(context);

    // Fonction pour obtenir les événements (médicaments) pour un jour donné
    List<Medication> _getEventsForDay(DateTime day) {
      return medicationProvider.medications.where((med) {
        return med.getMedicationDays().any((medDay) => isSameDay(medDay, day));
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier Complet'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'fr_FR', // Définir la locale pour le français
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay!, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay; // update `_focusedDay` here as well
              });
              medicationProvider.setSelectedDate(selectedDay); // Mettre à jour la date sélectionnée dans le provider
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay, // Utilise eventLoader pour les points
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventsMarker(date, events),
                  );
                }
                return null;
              },
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false, // Cache le bouton de format (semaine/mois)
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.black87),
              rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.black87),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.pinkAccent.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.blue[700],
                shape: BoxShape.circle,
              ),
              defaultTextStyle: const TextStyle(color: Colors.black87),
              weekendTextStyle: const TextStyle(color: Colors.red),
              outsideTextStyle: TextStyle(color: Colors.grey[400]),
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded( // Utilisation d'Expanded pour que le ListView prenne l'espace restant
            child: _selectedDay == null
                ? const Center(child: Text('Sélectionnez une date pour voir les médicaments.'))
                : medicationProvider.getMedicationsForSelectedDay().isEmpty
                ? Center(
              child: Text(
                'Aucun médicament prévu pour le ${DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDay!)}.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: medicationProvider.getMedicationsForSelectedDay().length,
              itemBuilder: (context, index) {
                final medication =
                medicationProvider.getMedicationsForSelectedDay()[index];
                return MedicationCard(
                  medication: medication,
                  forDate: _selectedDay!,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsMarker(DateTime date, List events) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue[700],
      ),
      width: 8.0,
      height: 8.0,
    );
  }
}
