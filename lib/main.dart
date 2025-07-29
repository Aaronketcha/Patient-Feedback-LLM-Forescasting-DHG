import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// Importez vos composants séparés
import 'models/medication.dart';
import 'services/medication_data_service.dart';
import 'providers/medication_provider.dart';
import 'screens/home_screen.dart';
import 'screens/full_calendar_screen.dart';
import 'widgets/medication_card.dart';
import 'widgets/daily_calendar_bar.dart';
import 'utils/date_utils.dart'; // Utilitaires de date

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('fr_FR', null);

  runApp(
    ChangeNotifierProvider(
      create: (context) => MedicationProvider(
        medicationService: MedicationDataService(
          baseUrl: 'https://reminder-backend-service-231068023969.us-east1.run.app', // Utilisez l'adresse IP de votre machine hôte pour l'émulateur Android, ou 'http://localhost:8000' pour le simulateur iOS ou le web.
        ),
      ),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
