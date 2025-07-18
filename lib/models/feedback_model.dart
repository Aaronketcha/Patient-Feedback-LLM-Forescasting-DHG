class FeedbackModel {
  final String id;
  final double rating;
  final String textFeedback;
  final String? audioPath;
  final String emotionRating;
  final String language;
  final DateTime timestamp;
  final String patientId;

  FeedbackModel({
    required this.id,
    required this.rating,
    required this.textFeedback,
    this.audioPath,
    required this.emotionRating,
    required this.language,
    required this.timestamp,
    required this.patientId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'textFeedback': textFeedback,
      'audioPath': audioPath,
      'emotionRating': emotionRating,
      'language': language,
      'timestamp': timestamp.toIso8601String(),
      'patientId': patientId,
    };
  }

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'],
      rating: json['rating'].toDouble(),
      textFeedback: json['textFeedback'],
      audioPath: json['audioPath'],
      emotionRating: json['emotionRating'],
      language: json['language'],
      timestamp: DateTime.parse(json['timestamp']),
      patientId: json['patientId'],
    );
  }
}

enum EmotionType {
  veryHappy,
  happy,
  neutral,
  sad,
  verySad,
}

class EmotionData {
  final EmotionType type;
  final String emoji;
  final String labelKey;

  const EmotionData({
    required this.type,
    required this.emoji,
    required this.labelKey,
  });
}

class FeedbackConstants {
  static const List<EmotionData> emotions = [
    EmotionData(
      type: EmotionType.veryHappy,
      emoji: '😄',
      labelKey: 'veryHappy',
    ),
    EmotionData(
      type: EmotionType.happy,
      emoji: '😊',
      labelKey: 'happy',
    ),
    EmotionData(
      type: EmotionType.neutral,
      emoji: '😐',
      labelKey: 'neutral',
    ),
    EmotionData(
      type: EmotionType.sad,
      emoji: '😢',
      labelKey: 'sad',
    ),
    EmotionData(
      type: EmotionType.verySad,
      emoji: '😭',
      labelKey: 'verySad',
    ),
  ];

  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'fr', 'name': 'Français'},
    {'code': 'es', 'name': 'Español'},
  ];
}