class LeaderboardEntry {
  final String uid;
  final int rank;
  final String username;
  final int stars;
  final int levelsCompleted;
  final String avatar;
  final bool isCurrentPlayer;
  final String? badge;

  const LeaderboardEntry({
    required this.uid,
    required this.rank,
    required this.username,
    required this.stars,
    required this.levelsCompleted,
    required this.avatar,
    this.isCurrentPlayer = false,
    this.badge,
  });

  factory LeaderboardEntry.fromDocument(String uid, Map<String, dynamic> data) {
    int count(String key) {
      final value = data[key];
      return value is num && value.isFinite && value >= 0 ? value.toInt() : 0;
    }

    final name = data['username'];
    final avatar = data['avatar'];
    return LeaderboardEntry(
      uid: uid,
      rank: 0,
      username: name is String && name.trim().isNotEmpty ? name : 'Explorer',
      stars: count('stars'),
      levelsCompleted: count('levelsCompleted'),
      avatar: avatar is String ? avatar : '',
    );
  }

  LeaderboardEntry copyWith({
    int? rank,
    String? username,
    int? stars,
    int? levelsCompleted,
    String? avatar,
    bool? isCurrentPlayer,
    String? badge,
  }) {
    return LeaderboardEntry(
      uid: uid,
      rank: rank ?? this.rank,
      username: username ?? this.username,
      stars: stars ?? this.stars,
      levelsCompleted: levelsCompleted ?? this.levelsCompleted,
      avatar: avatar ?? this.avatar,
      isCurrentPlayer: isCurrentPlayer ?? this.isCurrentPlayer,
      badge: badge ?? this.badge,
    );
  }
}
