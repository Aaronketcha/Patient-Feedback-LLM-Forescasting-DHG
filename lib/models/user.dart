// models/user.dart
class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isPremium;
  final Map<String, dynamic> preferences;

  User({
    String? id,
    required this.name,
    required this.email,
    this.avatarUrl,
    DateTime? createdAt,
    this.isPremium = false,
    Map<String, dynamic>? preferences,
  }) : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        preferences = preferences ?? {};

  User copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    bool? isPremium,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      isPremium: isPremium ?? this.isPremium,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'isPremium': isPremium,
      'preferences': preferences,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatarUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      isPremium: json['isPremium'] ?? false,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }
}