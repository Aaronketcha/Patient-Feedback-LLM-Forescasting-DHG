import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/feedback_model.dart';
// import 'package:record/record_platform_interface.dart';


class FeedbackProvider with ChangeNotifier {
  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _speechText = '';
  bool _speechEnabled = false;

  // Text to Speech
  final FlutterTts _flutterTts = FlutterTts();

  // Audio Recording
  final Record _record = Record();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;

  // Feedback Form Data
  double _rating = 0.0;
  String _textFeedback = '';
  EmotionType _selectedEmotion = EmotionType.neutral;
  String _currentLanguage = 'en';

  // Getters
  bool get isListening => _isListening;
  String get speechText => _speechText;
  bool get speechEnabled => _speechEnabled;
  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;
  String? get recordingPath => _recordingPath;
  double get rating => _rating;
  String get textFeedback => _textFeedback;
  EmotionType get selectedEmotion => _selectedEmotion;
  String get currentLanguage => _currentLanguage;

  FeedbackProvider() {
    _initializeSpeech();
    _initializeTts();
  }

  // Initialize Speech to Text
  Future<void> _initializeSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing speech: $e');
    }
  }

  // Initialize Text to Speech
  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  // Start/Stop Speech Recognition
  Future<void> toggleListening() async {
    if (!_speechEnabled) return;

    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    } else {
      await _speechToText.listen(
        onResult: (result) {
          _speechText = result.recognizedWords;
          _textFeedback = _speechText;
          notifyListeners();
        },
        localeId: _getLocaleId(_currentLanguage),
        listenMode: ListenMode.confirmation,
      );
      _isListening = true;
    }
    notifyListeners();
  }

  // Start Audio Recording
  Future<void> startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/feedback_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _record.start(
          path: path,
          encoder: AudioEncoder.aacLc, // encodage audio
          bitRate: 128000,             // qualité audio (optionnel)
          samplingRate: 44100,         // fréquence (optionnel)
        );

        _isRecording = true;
        _recordingPath = path;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }


  // Stop Audio Recording
  Future<void> stopRecording() async {
    try {
      await _record.stop();
      _isRecording = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  // Play Audio Recording
  Future<void> playRecording() async {
    if (_recordingPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        _isPlaying = false;
      } else {
        await _audioPlayer.play(DeviceFileSource(_recordingPath!));
        _isPlaying = true;

        _audioPlayer.onPlayerComplete.listen((event) {
          _isPlaying = false;
          notifyListeners();
        });
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error playing recording: $e');
    }
  }

  // Delete Audio Recording
  Future<void> deleteRecording() async {
    if (_recordingPath == null) return;

    try {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        await file.delete();
      }
      _recordingPath = null;
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting recording: $e');
    }
  }

  // Speak Text
  Future<void> speakText(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  // Update Rating
  void updateRating(double newRating) {
    _rating = newRating;
    notifyListeners();
  }

  // Update Text Feedback
  void updateTextFeedback(String text) {
    _textFeedback = text;
    notifyListeners();
  }

  // Update Selected Emotion
  void updateSelectedEmotion(EmotionType emotion) {
    _selectedEmotion = emotion;
    notifyListeners();
  }

  // Change Language
  Future<void> changeLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    await _flutterTts.setLanguage(languageCode);
    notifyListeners();
  }

  // Submit Feedback
  Future<FeedbackModel> submitFeedback(String patientId) async {
    final feedback = FeedbackModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rating: _rating,
      textFeedback: _textFeedback,
      audioPath: _recordingPath,
      emotionRating: _selectedEmotion.name,
      language: _currentLanguage,
      timestamp: DateTime.now(),
      patientId: patientId,
    );

    // Here you would typically save to a database
    // For now, we'll just return the model
    return feedback;
  }

  // Reset Form
  void resetForm() {
    _rating = 0.0;
    _textFeedback = '';
    _speechText = '';
    _selectedEmotion = EmotionType.neutral;
    _recordingPath = null;
    _isPlaying = false;
    notifyListeners();
  }

  // Helper method to get locale ID
  String _getLocaleId(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'en_US';
      case 'fr':
        return 'fr_FR';
      case 'es':
        return 'es_ES';
      default:
        return 'en_US';
    }
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
    _record.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}