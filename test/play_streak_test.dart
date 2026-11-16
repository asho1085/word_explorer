import 'package:flutter_test/flutter_test.dart';
import 'package:word_explorer/models/play_streak.dart';

void main() {
  DateTime ist(int y, int m, int d, int h, [int min = 0]) =>
      DateTime.utc(y, m, d, h, min).subtract(const Duration(hours: 5, minutes: 30));

  test('first completion starts a one-day streak', () {
    final next = const PlayStreak().afterCompletion(ist(2026, 11, 12, 10));
    expect(next.current, 1);
    expect(next.best, 1);
  });

  test('same IST day never counts twice', () {
    final first = const PlayStreak().afterCompletion(ist(2026, 11, 12, 0, 5));
    final again = first.afterCompletion(ist(2026, 11, 12, 23, 55));
    expect(identical(first, again), isTrue);
    expect(again.current, 1);
  });

  test('consecutive IST days extend and update best', () {
    var streak = const PlayStreak().afterCompletion(ist(2026, 11, 10, 23, 50));
    streak = streak.afterCompletion(ist(2026, 11, 11, 0, 10));
    streak = streak.afterCompletion(ist(2026, 11, 12, 9));
    expect(streak.current, 3);
    expect(streak.best, 3);
  });

  test('missed day restarts current but keeps best', () {
    final streak = const PlayStreak(
      current: 4,
      best: 6,
    ).afterCompletion(ist(2026, 11, 1, 9));
    final previous = PlayStreak(
      current: 4,
      best: 6,
      lastPlayedAt: ist(2026, 11, 10, 9),
    );
    final restarted = previous.afterCompletion(ist(2026, 11, 12, 9));
    expect(streak.current, 1);
    expect(restarted.current, 1);
    expect(restarted.best, 6);
  });

  test('displayed streak expires after a missed IST day', () {
    final streak = PlayStreak(
      current: 5,
      best: 5,
      lastPlayedAt: ist(2026, 11, 10, 22),
    );
    expect(streak.currentAt(ist(2026, 11, 11, 23, 59)), 5);
    expect(streak.currentAt(ist(2026, 11, 12, 0, 1)), 0);
    expect(streak.playedToday(ist(2026, 11, 10, 23, 59)), isTrue);
  });
}
