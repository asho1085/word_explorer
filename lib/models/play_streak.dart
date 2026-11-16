class PlayStreak {
  final int current;
  final int best;
  final DateTime? lastPlayedAt;

  const PlayStreak({this.current = 0, this.best = 0, this.lastPlayedAt});

  static int dayIndex(DateTime instant) =>
      (instant.toUtc().millisecondsSinceEpoch + 19800000) ~/ 86400000;

  int currentAt(DateTime now) {
    final last = lastPlayedAt;
    if (last == null) return 0;
    final gap = dayIndex(now) - dayIndex(last);
    return gap > 1 ? 0 : current;
  }

  bool playedToday(DateTime now) =>
      lastPlayedAt != null && dayIndex(now) == dayIndex(lastPlayedAt!);

  PlayStreak afterCompletion(DateTime serverTime) {
    final last = lastPlayedAt;
    final gap = last == null ? null : dayIndex(serverTime) - dayIndex(last);
    if (gap != null && gap <= 0) return this;
    final next = gap == 1 ? current + 1 : 1;
    return PlayStreak(
      current: next,
      best: next > best ? next : best,
      lastPlayedAt: serverTime.toUtc(),
    );
  }
}
