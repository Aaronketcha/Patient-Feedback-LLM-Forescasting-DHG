class User {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final int totalChats;
  final int totalMessages;
  final int totalTimeSpent;



  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    required this.createdAt,
    this.lastLoginAt,
    required this.isEmailVerified,
    required this.totalChats,
    required this.totalMessages,
    required this.totalTimeSpent,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePicture,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    int? totalChats,
    int? totalMessages,
    int? totalTimeSpent,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      totalChats: totalChats ?? this.totalChats,
      totalMessages: totalMessages ?? this.totalMessages,
      totalTimeSpent: totalTimeSpent ?? this.totalTimeSpent,
    );
  }
}
