import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_explorer/models/leaderboard_entry.dart';
import 'package:word_explorer/services/leaderboard_service.dart';

LeaderboardEntry entry(String uid, {int stars = 10, int levels = 2}) =>
    LeaderboardEntry.fromDocument(uid, {
      'username': 'Same Name',
      'stars': stars,
      'levelsCompleted': levels,
      'avatar': '',
    });

void main() {
  test('unconfigured Firebase is unavailable, never fabricated', () async {
    final service = LeaderboardService();
    expect(service.getLeaderboard(), isEmpty);
    expect(service.getCurrentPlayerEntry(), isNull);
    expect(
      (await service.watchLeaderboard().first).status,
      LeaderboardStatus.unavailable,
    );
  });

  test('empty snapshots have no competitors or local current player', () async {
    final service = LeaderboardService(
      snapshots: () => Stream.value(const LeaderboardSnapshot([])),
      currentUid: () => 'me',
    );
    final state = await service.watchLeaderboard().firstWhere(
      (s) => s.status == LeaderboardStatus.ready,
    );
    expect(state.entries, isEmpty);
    expect(state.currentPlayer, isNull);
    expect(service.getCurrentPlayerEntry(), isNull);
  });

  test(
    'ties use stars, levels and UID; identity never uses username',
    () async {
      String? uid = 'b';
      final service = LeaderboardService(
        snapshots: () => Stream.value(
          LeaderboardSnapshot([
            entry('b'),
            entry('z', stars: 11),
            entry('c', levels: 3),
            entry('a'),
          ]),
        ),
        currentUid: () => uid,
      );
      final state = await service.watchLeaderboard().firstWhere(
        (s) => s.status == LeaderboardStatus.ready,
      );
      expect(state.entries.map((e) => e.uid), ['z', 'c', 'a', 'b']);
      expect(state.entries.map((e) => e.rank), [1, 2, 3, 4]);
      expect(state.entries.where((e) => e.isCurrentPlayer).single.uid, 'b');
      expect(service.getCurrentPlayerEntry()?.rank, 4);
      uid = 'missing';
      expect(service.getCurrentPlayerEntry(), isNull);
      uid = null;
      expect(service.getCurrentPlayerEntry(), isNull);
    },
  );

  test('bounded results never append an absent current player', () async {
    final service = LeaderboardService(
      snapshots: () => Stream.value(
        LeaderboardSnapshot([
          for (var i = 0; i < 100; i++) entry('user-$i', stars: 200 - i),
        ]),
      ),
      currentUid: () => 'outside',
    );
    final state = await service.watchLeaderboard().firstWhere(
      (s) => s.status == LeaderboardStatus.ready,
    );
    expect(state.entries.length, 100);
    expect(state.currentPlayer, isNull);
    expect(service.getCurrentPlayerEntry(), isNull);
  });

  test(
    'cached results and errors are explicit, preserving real scores',
    () async {
      final source = StreamController<LeaderboardSnapshot>();
      final states = <LeaderboardState>[];
      final service = LeaderboardService(
        snapshots: () => source.stream,
        currentUid: () => 'me',
      );
      final subscription = service.watchLeaderboard().listen(states.add);
      await Future<void>.delayed(Duration.zero);
      source.add(LeaderboardSnapshot([entry('me')], isFromCache: true));
      await Future<void>.delayed(Duration.zero);
      expect(states.last.status, LeaderboardStatus.cached);
      source.addError(StateError('offline'));
      await Future<void>.delayed(Duration.zero);
      expect(states.last.status, LeaderboardStatus.error);
      expect(states.last.currentPlayer?.uid, 'me');
      source.add(LeaderboardSnapshot([entry('me', stars: 50)]));
      await Future<void>.delayed(Duration.zero);
      expect(states.last.status, LeaderboardStatus.ready);
      expect(service.getCurrentPlayerEntry()?.stars, 50);
      await subscription.cancel();
      await source.close();
    },
  );

  test('errors and stalled sources do not remain loading', () async {
    final failed = LeaderboardService(
      snapshots: () => Stream.error(StateError('permission denied')),
      currentUid: () => null,
    );
    expect(
      (await failed.watchLeaderboard().firstWhere(
        (s) => s.status == LeaderboardStatus.error,
      )).entries,
      isEmpty,
    );
    final source = StreamController<LeaderboardSnapshot>();
    final stalled = LeaderboardService(
      snapshots: () => source.stream,
      currentUid: () => null,
      initialTimeout: const Duration(milliseconds: 5),
    );
    expect(
      (await stalled.watchLeaderboard().firstWhere(
        (s) => s.status == LeaderboardStatus.error,
      )).entries,
      isEmpty,
    );
    expect(source.hasListener, isFalse);
    await source.close();
  });

  test(
    'auth changes cancel old query and reset UID; dispose cancels all',
    () async {
      String? uid = 'a';
      final auth = StreamController<String?>();
      final sources = <StreamController<LeaderboardSnapshot>>[];
      final states = <LeaderboardState>[];
      final service = LeaderboardService(
        snapshots: () {
          final source = StreamController<LeaderboardSnapshot>();
          sources.add(source);
          return source.stream;
        },
        currentUid: () => uid,
        authChanges: () => auth.stream,
      );
      final subscription = service.watchLeaderboard().listen(states.add);
      await Future<void>.delayed(Duration.zero);
      sources.first.add(LeaderboardSnapshot([entry('a'), entry('b')]));
      await Future<void>.delayed(Duration.zero);
      expect(states.last.currentPlayer?.uid, 'a');
      uid = 'b';
      auth.add(uid);
      await Future<void>.delayed(Duration.zero);
      expect(sources.first.hasListener, isFalse);
      expect(states.last.entries, isEmpty);
      expect(service.getCurrentPlayerEntry(), isNull);
      sources.last.add(LeaderboardSnapshot([entry('a'), entry('b')]));
      await Future<void>.delayed(Duration.zero);
      expect(states.last.currentPlayer?.uid, 'b');
      uid = null;
      auth.add(null);
      await Future<void>.delayed(Duration.zero);
      sources.last.add(LeaderboardSnapshot([entry('a'), entry('b')]));
      await Future<void>.delayed(Duration.zero);
      expect(states.last.currentPlayer, isNull);
      expect(states.last.entries.where((e) => e.isCurrentPlayer), isEmpty);
      await subscription.cancel();
      expect(auth.hasListener, isFalse);
      expect(sources.every((source) => !source.hasListener), isTrue);
      for (final source in sources) {
        await source.close();
      }
      await auth.close();
    },
  );

  test('document parsing tolerates missing and malformed public fields', () {
    final parsed = LeaderboardEntry.fromDocument('real-uid', {
      'username': null,
      'stars': -1,
      'levelsCompleted': 'bad',
      'avatar': 7,
    });
    expect(parsed.uid, 'real-uid');
    expect(parsed.stars, 0);
    expect(parsed.levelsCompleted, 0);
    expect(parsed.avatar, isEmpty);
  });
}
