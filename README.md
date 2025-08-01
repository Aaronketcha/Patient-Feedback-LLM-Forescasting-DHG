# 🗣️ Patient Feedback System — Flutter + FastAPI

A modern, multilingual feedback system designed to collect and store patient reviews using speech, emotion, and text. Built with **Flutter** (frontend) and **FastAPI** (backend), it supports English, Français, Ewondo, Douala, and Sawa.

---

## 🌍 Use Case

Hospitals and health centers in Africa (and beyond) need a culturally contextualized feedback system. This app empowers patients to express their experiences using voice, text, emojis, and local languages.

---

## 📱 Flutter App (Frontend)

### Key Features

- ✨ **Speech to Text** & **Text to Speech**
- 🎙️ **Voice Recorder** with playback
- ⭐ **Star Rating System**
- 😃 **Emotion Selector (Happy, Sad, etc.)**
- 🌐 **Language Selector**: en, fr, ewondo, douala, sawa
- 📄 **Local Validation & Submission**
- 🧠 **Provider State Management**

### 📦 Packages Used

- `speech_to_text`
- `flutter_tts`
- `record`
- `audioplayers`
- `provider`
- `flutter_rating_bar`
- `intl` (for localization)

### 🚀 Run Flutter App

```bash
flutter pub get
flutter run

Application de Rappel de Médicaments - Frontend Flutter
Cette section décrit comment installer les dépendances et exécuter l'application frontend développée avec Flutter.

1. Prérequis
   Flutter SDK : Assurez-vous d'avoir Flutter installé et configuré sur votre machine. Vous pouvez vérifier votre installation en ouvrant un terminal et en exécutant la commande :

flutter doctor

Suivez les instructions si des problèmes sont signalés.

2. Étapes d'Installation et d'Exécution
   Naviguez vers le répertoire du frontend :
   Ouvrez votre terminal ou invite de commande et accédez au dossier racine de votre projet Flutter (le dossier qui contient pubspec.yaml).

Installez les dépendances Flutter :
Exécutez la commande suivante pour télécharger et installer tous les paquets Dart nécessaires (y compris le paquet http pour la communication avec le backend) :

flutter pub get

Configurez l'URL du Backend :
Ouvrez le fichier lib/main.dart de votre projet Flutter.
Trouvez la ligne où MedicationDataService est instancié et ajustez le baseUrl en fonction de l'environnement où votre backend FastAPI est en cours d'exécution :

// lib/main.dart
// ...
runApp(
ChangeNotifierProvider(
create: (context) => MedicationProvider(
medicationService: MedicationDataService(
// --- ADRESSE DU BACKEND À CONFIGURER ---
// Pour l'émulateur Android (si votre backend tourne sur votre machine):
baseUrl: 'http://10.0.2.2:8000',
// Pour le simulateur iOS ou le navigateur web (si votre backend tourne sur votre machine):
// baseUrl: 'http://localhost:8000',
// Pour un appareil physique (remplacez par l'adresse IP locale de votre machine):
// baseUrl: 'http://VOTRE_IP_LOCALE:8000',
),
),
child: const MyApp(),
),
);
// ...

Choisissez l'option appropriée pour votre baseUrl et commentez les autres.

Lancez l'application Flutter :
Il est crucial d'effectuer un redémarrage complet de l'application (pas seulement un "hot reload" ou "hot restart") après avoir modifié le baseUrl ou si vous venez de démarrer votre backend. Cela garantit que les changements de configuration et l'initialisation des fournisseurs sont pris en compte.

Dans votre IDE (VS Code, Android Studio) : Arrêtez l'application en cours d'exécution (généralement un bouton carré rouge) et relancez-la (bouton vert "Run" ou "Debug").

Depuis le terminal (dans le dossier racine de votre projet Flutter) :

flutter run

3. Ordre d'Exécution
   Assurez-vous toujours que votre backend FastAPI est démarré et fonctionne avant de lancer l'application Flutter. L'application Flutter tentera de récupérer les données du backend dès son démarrage.

4. Dépannage (Frontend)
   Application Flutter vide ou erreurs de connexion :

Assurez-vous que le backend est en cours d'exécution et accessible depuis l'adresse IP/port configuré.

Vérifiez que le baseUrl dans lib/main.dart est correct pour votre environnement (émulateur, simulateur, appareil physique).

Effectuez un redémarrage complet de l'application Flutter.

Vérifiez les logs de l'application Flutter dans la console de débogage de votre IDE pour des messages d'erreur HTTP ou de parsing.

LocaleDataException :

Cela signifie que initializeDateFormatting('fr_FR', null); n'a pas été appelé ou n'a pas pris effet correctement. Un redémarrage complet de l'application Flutter est nécessaire.

ProviderNotFoundException :

Cela signifie que le MedicationProvider n'est pas disponible dans le BuildContext où il est demandé. Un redémarrage complet de l'application Flutter est nécessaire.

En suivant ces étapes, vous devriez pouvoir installer et exécuter votre application frontend Flutter.