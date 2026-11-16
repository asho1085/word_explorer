import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/leaderboard_entry.dart';
import 'cloud_db.dart';

enum LeaderboardStatus { loading, ready, cached, error, unavailable }

class LeaderboardSnapshot {
  final List<LeaderboardEntry> entries;
  final bool isFromCache;

  const LeaderboardSnapshot(this.entries, {this.isFromCache = false});
}

class LeaderboardState {
  final List<LeaderboardEntry> entries;
  final LeaderboardStatus status;
  final String? currentUid;

  const LeaderboardState({
    this.entries = const [],
    this.status = LeaderboardStatus.loading,
    this.currentUid,
  });

  LeaderboardEntry? get currentPlayer {
    for (final entry in entries) {
      if (entry.uid == currentUid) return entry;
    }
    return null;
  }
}

class LeaderboardService {
  static const limit = 100;
  static final LeaderboardService instance = LeaderboardService();

  final Stream<LeaderboardSnapshot> Function()? _snapshots;
  final String? Function()? _currentUid;
  final Stream<String?> Function()? _authChanges;
  final Duration initialTimeout;
  List<LeaderboardEntry> _latestEntries = const [];

  LeaderboardService({
    Stream<LeaderboardSnapshot> Function()? snapshots,
    String? Function()? currentUid,
    Stream<String?> Function()? authChanges,
    this.initialTimeout = const Duration(seconds: 12),
  }) : _snapshots = snapshots,
       _currentUid = currentUid,
       _authChanges = authChanges;

  String? get currentUid {
    if (_currentUid != null) return _currentUid();
    if (Firebase.apps.isEmpty) return null;
    final user = FirebaseAuth.instance.currentUser;
    return user == null || user.isAnonymous ? null : user.uid;
  }

  List<LeaderboardEntry> getLeaderboard() {
    final uid = currentUid;
    return List.unmodifiable(
      _latestEntries.map(
        (entry) => entry.copyWith(isCurrentPlayer: entry.uid == uid),
      ),
    );
  }

  LeaderboardEntry? getCurrentPlayerEntry() {
    for (final entry in getLeaderboard()) {
      if (entry.isCurrentPlayer) return entry;
    }
    return null;
  }

  static List<LeaderboardEntry>? _cachedRemoteEntries;
  static DateTime? _lastLiveFetch;
  static const Duration cacheTtl = Duration(minutes: 5);

  /// Clears the in-memory cache so subsequent queries pull fresh data from Firestore.
  static void clearCache() {
    _cachedRemoteEntries = null;
    _lastLiveFetch = null;
  }

  Stream<LeaderboardSnapshot> _firestoreSnapshots() {
    late StreamController<LeaderboardSnapshot> controller;
    StreamSubscription? sub;
    var hasEmitted = false;

    Future<void> fetchOnce() async {
      final now = DateTime.now();
      if (_cachedRemoteEntries != null &&
          _lastLiveFetch != null &&
          now.difference(_lastLiveFetch!) < cacheTtl) {
        if (!controller.isClosed) {
          hasEmitted = true;
          controller.add(
            LeaderboardSnapshot(
              _cachedRemoteEntries!,
              isFromCache: true,
            ),
          );
        }
        return;
      }

      try {
        final snapshot = await cloudDb
            .collection('leaderboard')
            .orderBy('stars', descending: true)
            .limit(limit)
            .get();
        if (!controller.isClosed) {
          hasEmitted = true;
          final entries = snapshot.docs
              .map((doc) =>
                  LeaderboardEntry.fromDocument(doc.id, doc.data()))
              .toList();
          _cachedRemoteEntries = entries;
          _lastLiveFetch = DateTime.now();
          controller.add(
            LeaderboardSnapshot(
              entries,
              isFromCache: snapshot.metadata.isFromCache,
            ),
          );
        }
      } catch (err, stack) {
        if (!controller.isClosed && !hasEmitted) {
          controller.addError(err, stack);
        }
      }
    }

    controller = StreamController<LeaderboardSnapshot>(
      onListen: () {
        // Fetch via get() immediately in case real-time updates are disabled
        unawaited(fetchOnce());

        try {
          sub = cloudDb
              .collection('leaderboard')
              .orderBy('stars', descending: true)
              .limit(limit)
              .snapshots(includeMetadataChanges: true)
              .listen(
                (snapshot) {
                  if (!controller.isClosed) {
                    hasEmitted = true;
                    final entries = snapshot.docs
                        .map((doc) => LeaderboardEntry.fromDocument(
                            doc.id, doc.data()))
                        .toList();
                    _cachedRemoteEntries = entries;
                    _lastLiveFetch = DateTime.now();
                    controller.add(
                      LeaderboardSnapshot(
                        entries,
                        isFromCache:
                            snapshot.metadata.isFromCache ||
                            snapshot.metadata.hasPendingWrites,
                      ),
                    );
                  }
                },
                onError: (Object error, StackTrace stack) {
                  // Real-time updates may be disabled on Enterprise databases
                  // (REALTIME_UPDATES_MODE_DISABLED). We initiated fetchOnce();
                  // only propagate error if fetchOnce() also fails and nothing was received.
                  if (!hasEmitted) {
                    unawaited(fetchOnce());
                  }
                },
              );
        } catch (_) {
          // If snapshots() throws synchronously, fetchOnce is already active.
        }
      },
      onCancel: () async {
        await sub?.cancel();
      },
    );

    return controller.stream;
  }

  Stream<LeaderboardState> watchLeaderboard() {
    late StreamController<LeaderboardState> controller;
    StreamSubscription<LeaderboardSnapshot>? query;
    StreamSubscription<String?>? auth;
    Timer? timer;
    var generation = 0;
    var cancelled = false;
    String? uid;
    var entries = <LeaderboardEntry>[];

    void emit(LeaderboardStatus status) {
      if (!cancelled) {
        controller.add(
          LeaderboardState(
            entries: List.unmodifiable(entries),
            status: status,
            currentUid: uid,
          ),
        );
      }
    }

    Future<void> restart() async {
      final token = ++generation;
      timer?.cancel();
      final previous = query;
      query = null;
      entries = [];
      _latestEntries = const [];
      emit(LeaderboardStatus.loading);
      await previous?.cancel();
      if (cancelled || token != generation) return;
      var received = false;
      try {
        timer = Timer(initialTimeout, () {
          if (token == generation) emit(LeaderboardStatus.error);
        });
        query = (_snapshots ?? _firestoreSnapshots)().listen(
          (snapshot) {
            if (cancelled || token != generation) return;
            received = true;
            timer?.cancel();
            final sorted = snapshot.entries.toList()
              ..sort((a, b) {
                final stars = b.stars.compareTo(a.stars);
                if (stars != 0) return stars;
                final levels = b.levelsCompleted.compareTo(a.levelsCompleted);
                return levels != 0 ? levels : a.uid.compareTo(b.uid);
              });
            entries = [
              for (var i = 0; i < sorted.length && i < limit; i++)
                sorted[i].copyWith(
                  rank: i + 1,
                  isCurrentPlayer: sorted[i].uid == uid,
                ),
            ];
            _latestEntries = List.unmodifiable(entries);
            emit(
              snapshot.isFromCache
                  ? LeaderboardStatus.cached
                  : LeaderboardStatus.ready,
            );
          },
          onError: (Object error, StackTrace stack) {
            if (cancelled || token != generation) return;
            timer?.cancel();
            emit(LeaderboardStatus.error);
          },
          onDone: () {
            if (cancelled || token != generation) return;
            timer?.cancel();
            emit(received ? LeaderboardStatus.cached : LeaderboardStatus.error);
          },
        );
      } catch (_) {
        timer?.cancel();
        emit(LeaderboardStatus.error);
      }
    }

    controller = StreamController<LeaderboardState>(
      onListen: () {
        if (_snapshots == null && Firebase.apps.isEmpty) {
          _latestEntries = const [];
          emit(LeaderboardStatus.unavailable);
          return;
        }
        try {
          uid = currentUid;
          final changes =
              _authChanges?.call() ??
              (_snapshots != null
                  ? const Stream<String?>.empty()
                  : FirebaseAuth.instance.authStateChanges().map(
                      (user) =>
                          user == null || user.isAnonymous ? null : user.uid,
                    ));
          auth = changes.distinct().listen(
            (nextUid) {
              if (nextUid == uid) return;
              uid = nextUid;
              unawaited(restart());
            },
            onError: (Object error, StackTrace stack) {
              uid = null;
              ++generation;
              timer?.cancel();
              unawaited(query?.cancel());
              entries = [];
              _latestEntries = const [];
              emit(LeaderboardStatus.error);
            },
          );
          unawaited(restart());
        } catch (_) {
          emit(LeaderboardStatus.unavailable);
        }
      },
      onCancel: () async {
        cancelled = true;
        ++generation;
        timer?.cancel();
        await Future.wait([
          if (auth != null) auth!.cancel(),
          if (query != null) query!.cancel(),
        ]);
      },
    );
    return controller.stream;
  }
}
