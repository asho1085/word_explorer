import 'dart:convert';

/// Represents a player profile in Shabdkhoj: Word Search Puzzle
class UserModel {
  final String uid;
  final String username;
  final String email;
  final String avatar; // Predefined avatar emoji (🦊, 🦁, 🦉, 🐯, 🐼, 👑, 🚀, 💎)
  final String? photoUrl;
  final bool isGuest;
  final String provider; // 'password' | 'google' | 'guest'
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.avatar = '🦊',
    this.photoUrl,
    this.isGuest = false,
    this.provider = 'password',
    required this.createdAt,
  });

  UserModel copyWith({
    String? uid,
    String? username,
    String? email,
    String? avatar,
    String? photoUrl,
    bool? isGuest,
    String? provider,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      photoUrl: photoUrl ?? this.photoUrl,
      isGuest: isGuest ?? this.isGuest,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'avatar': avatar,
      'photoUrl': photoUrl,
      'isGuest': isGuest,
      'provider': provider,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? '',
      username: map['username'] as String? ?? 'Player',
      email: map['email'] as String? ?? '',
      avatar: map['avatar'] as String? ?? '🦊',
      photoUrl: map['photoUrl'] as String?,
      isGuest: map['isGuest'] as bool? ?? false,
      provider: map['provider'] as String? ?? 'password',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

