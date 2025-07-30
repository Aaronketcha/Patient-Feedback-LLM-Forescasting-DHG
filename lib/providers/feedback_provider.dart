import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../models/feedback_model.dart';

class FeedbackProvider with ChangeNotifier {
  // === Reconnaissance vocale
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _speechText = '';
  bool _speechEnabled = false;

  // === Synthèse vocale
  final FlutterTts _flutterTts = FlutterTts();

  // === Enregistrement audio
  final Record _record = Record();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;

  // === Feedback fields
  double _rating = 0.0;
  String _textFeedback = '';
  EmotionType _selectedEmotion = EmotionType.neutral;
  String _currentLanguage = 'en';
  String? _selectedDepartment;
  bool _isUrgent = false;

  // === Getters
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
  String? get selectedDepartment => _selectedDepartment;
  bool get isUrgent => _isUrgent;

  FeedbackProvider() {
    _initializeSpeech();
    _initializeTts();
  }

  Future<void> _initializeSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (e) => debugPrint('Speech error: $e'),
        onStatus: (s) => debugPrint('Speech status: $s'),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error init speech: $e');
    }
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setSpeechRate(0.5);
    } catch (e) {
      debugPrint('Error init TTS: $e');
    }
  }

  Future<void> toggleListening() async {
    if (!_speechEnabled) return;
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    } else {
      await _speechToText.listen(
        onResult: (res) {
          _speechText = res.recognizedWords;
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

  Future<void> startRecording() async {
    if (await Permission.microphone.request().isGranted) {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/feedback_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _record.start(path: path, encoder: AudioEncoder.aacLc,
          bitRate: 128000, samplingRate: 44100);
      _recordingPath = path;
      _isRecording = true;
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    await _record.stop();
    _isRecording = false;
    notifyListeners();
  }

  Future<void> playRecording() async {
    if (_recordingPath == null) return;
    if (_isPlaying) {
      await _audioPlayer.stop();
      _isPlaying = false;
    } else {
      await _audioPlayer.play(DeviceFileSource(_recordingPath!));
      _isPlaying = true;
      _audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> deleteRecording() async {
    if (_recordingPath != null) {
      final f = File(_recordingPath!);
      if (await f.exists()) await f.delete();
      _recordingPath = null;
      _isPlaying = false;
      notifyListeners();
    }
  }

  void updateRating(double r) {
    _rating = r;
    notifyListeners();
  }

  void updateTextFeedback(String text) {
    _textFeedback = text;
    notifyListeners();
  }

  void updateSelectedEmotion(EmotionType e) {
    _selectedEmotion = e;
    notifyListeners();
  }

  Future<void> changeLanguage(String code) async {
    _currentLanguage = code;
    await _flutterTts.setLanguage(code);
    notifyListeners();
  }

  void updateDepartment(String? dep) {
    _selectedDepartment = dep;
    notifyListeners();
  }

  void updateUrgency(bool val) {
    _isUrgent = val;
    notifyListeners();
  }

  Future<FeedbackModel> submitFeedback(String patientId) async {
    final fb = FeedbackModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rating: _rating,
      textFeedback: _textFeedback,
      audioPath: _recordingPath,
      emotionRating: _selectedEmotion.name,
      language: _currentLanguage,
      timestamp: DateTime.now(),
      patientId: patientId,
      department: _selectedDepartment ?? 'N/A',
      isUrgent: _isUrgent,
    );
    return fb;
  }

  void resetForm() {
    _rating = 0.0;
    _textFeedback = '';
    _speechText = '';
    _selectedEmotion = EmotionType.neutral;
    _currentLanguage = 'en';
    _selectedDepartment = null;
    _isUrgent = false;
    _recordingPath = null;
    _isPlaying = false;
    notifyListeners();
  }

  String _getLocaleId(String code) {
    return switch (code) {
      'fr' => 'fr_FR',
      'es' => 'es_ES',
      _ => 'en_US',
    };
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
