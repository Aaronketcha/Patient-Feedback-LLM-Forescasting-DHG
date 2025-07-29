import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Importez les composants nécessaires
import '../providers/medication_provider.dart';
import '../widgets/daily_calendar_bar.dart';
import '../widgets/medication_card.dart';
import 'full_calendar_screen.dart';

// Représente l'interface utilisateur de l'écran d'accueil.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final medicationProvider = Provider.of<MedicationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.grid_view, color: Colors.black54),
              onPressed: () {
                // Action pour le bouton grille
              },
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: NetworkImage(
                  'https://placehold.co/60x60/FF6347/FFFFFF?text=User'), // Image de profil
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mes Médicaments',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FullCalendarScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Voir tout'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black87, backgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            DailyCalendarBar(
              selectedDate: medicationProvider.selectedDate,
              onDateSelected: (date) {
                medicationProvider.setSelectedDate(date);
              },
              medications: medicationProvider.medications,
            ),
            const SizedBox(height: 20),
            medicationProvider.getMedicationsForSelectedDay().isEmpty
                ? Center(
              child: Text(
                'Aucun médicament prévu pour le ${DateFormat('dd MMMM', 'fr_FR').format(medicationProvider.selectedDate)}.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount:
              medicationProvider.getMedicationsForSelectedDay().length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final medication = medicationProvider
                    .getMedicationsForSelectedDay()[index];
                return MedicationCard(
                  medication: medication,
                  forDate: medicationProvider.selectedDate,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action pour ajouter un nouveau médicament
        },
        backgroundColor: Colors.blue[700],
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        elevation: 0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.calendar_today,
                  color: Colors.grey[600], size: 28),
              onPressed: () {
                // Action pour "Today"
              },
            ),
            const SizedBox(width: 48),
            IconButton(
              icon: Icon(Icons.medication, color: Colors.blue[700], size: 28),
              onPressed: () {
                // Action pour "Medications"
              },
            ),
          ],
        ),
      ),
    );
  }
}
