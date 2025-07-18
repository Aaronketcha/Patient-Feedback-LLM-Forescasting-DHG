import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Pour DateFormat

// Importez les modèles et fournisseurs nécessaires
import '../models/medication.dart';
import '../providers/medication_provider.dart';
import '../utils/date_utils.dart'; // Importez les utilitaires de date

// Un widget réutilisable pour afficher les détails d'un médicament.
class MedicationCard extends StatefulWidget {
  final Medication medication;
  final DateTime forDate;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.forDate,
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final medicationProvider = Provider.of<MedicationProvider>(context);
    final currentDay = widget.forDate;
    final now = DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.medication.image,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                // Ajout d'un loadingBuilder pour diagnostiquer les problèmes de chargement d'image
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey[300],
                  child: const Icon(Icons.medication_outlined, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.medication.medicationName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Durée: ${widget.medication.duration} jours',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Dose: ${widget.medication.dosage}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        trailing: Icon(
          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.grey[700],
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Heures de prise:',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Column(
                  children: widget.medication.times.map((timeStr) {
                    final parts = timeStr.split(':');
                    final hour = int.parse(parts[0]);
                    final minute = int.parse(parts[1]);
                    final medicationTime = DateTime(
                        currentDay.year, currentDay.month, currentDay.day, hour, minute);

                    bool isTaken = widget.medication.isTaken(currentDay, timeStr);
                    bool isMissed = medicationTime.isBefore(now) &&
                        isSameDay(currentDay, now) &&
                        !isTaken;
                    bool isFuture = medicationTime.isAfter(now) || !isSameDay(currentDay, now);

                    Color stepperColor;
                    IconData? icon;
                    Color iconColor;

                    if (isTaken) {
                      stepperColor = Colors.green;
                      icon = Icons.check_circle;
                      iconColor = Colors.green[800]!;
                    } else if (isMissed) {
                      stepperColor = Colors.red;
                      icon = Icons.cancel;
                      iconColor = Colors.red[800]!;
                    } else {
                      stepperColor = Colors.grey[300]!;
                      icon = Icons.circle_outlined;
                      iconColor = Colors.grey[600]!;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: stepperColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isTaken
                                  ? Colors.green[800]
                                  : isMissed
                                  ? Colors.red[800]
                                  : Colors.black87,
                              decoration: isTaken
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          const Spacer(),
                          if (!isTaken) // Bouton pour marquer comme pris, seulement si pas déjà pris
                            ElevatedButton.icon(
                              onPressed: () {
                                medicationProvider.markMedicationTimeAsTaken(
                                    widget.medication, currentDay, timeStr);
                                // Lancer WhatsApp
                                final message =
                                    "Rappel: J'ai pris mon ${widget.medication.medicationName} à $timeStr le ${DateFormat('dd/MM/yyyy').format(currentDay)}.";
                                medicationProvider.launchWhatsApp(message);
                              },
                              icon: const Icon(Icons.done_all, size: 18),
                              label: const Text('Marquer comme pris'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: isMissed ? Colors.red[400] : Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
