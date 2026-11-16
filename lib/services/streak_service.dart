import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/play_streak.dart';
import 'cloud_db.dart';

class StreakService extends ChangeNotifier {
  static final instance = StreakService._();
  StreakService._();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;
  String? _uid;
  PlayStreak _streak = const PlayStreak();
  bool _cached = false;
  bool _loading = false;
  bool _syncFailed = false;
  final Set<String> _recording = {};

  PlayStreak get streak => _streak;
  bool get signedIn => _uid != null;
  int get current => _streak.currentAt(DateTime.now());
  String get message {
    if (!signedIn) return 'Sign in to save your daily play streak.';
    if (_loading) return 'Loading your saved streak...';
    if (_syncFailed) return 'Connect and complete a level to sync your streak.';
    if (_cached) return 'Saved streak offline. Play online to update it.';
    if (_streak.playedToday(DateTime.now())) {
      return 'Today completed. Play again tomorrow!';
    }
    return 'Complete a level today to keep your streak going.';
  }

  void setUser(String? uid) {
    unawaited(_subscription?.cancel());
    _subscription = null;
    final user = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;
    _uid = user != null && !user.isAnonymous && user.uid == uid ? uid : null;
    _streak = const PlayStreak();
    _cached = false;
    _syncFailed = false;
    _loading = _uid != null;
    notifyListeners();
    if (_uid == null) return;
    final active = _uid!;
    var hasData = false;

    Future<void> fetchOnce() async {
      try {
        final doc = await cloudDb.collection('streaks').doc(active).get();
        if (_uid != active) return;
        hasData = true;
        _streak = _decode(doc.data());
        _cached = doc.metadata.isFromCache;
        _loading = false;
        _syncFailed = false;
        notifyListeners();
      } catch (error) {
        if (_uid != active || hasData) return;
        _loading = false;
        _syncFailed = true;
        notifyListeners();
        debugPrint('[StreakService] Streak read failed: $error');
      }
    }

    unawaited(fetchOnce());

    try {
      _subscription = cloudDb
          .collection('streaks')
          .doc(active)
          .snapshots(includeMetadataChanges: true)
          .listen(
            (snapshot) {
              if (_uid != active || snapshot.metadata.hasPendingWrites) return;
              hasData = true;
              _streak = _decode(snapshot.data());
              _cached = snapshot.metadata.isFromCache;
              _loading = false;
              _syncFailed = false;
              notifyListeners();
            },
            onError: (Object error) {
              if (_uid != active || hasData) return;
              unawaited(fetchOnce());
            },
          );
    } catch (_) {
      // Sync failure starting snapshots; fetchOnce handles it.
    }
  }

  PlayStreak _decode(Map<String, dynamic>? data) {
    if (data == null) return const PlayStreak();
    final last = data['lastPlayedAt'];
    final current = data['current'];
    final best = data['best'];
    if (last is! Timestamp ||
        current is! int ||
        best is! int ||
        current < 1 ||
        best < current) {
      return const PlayStreak();
    }
    return PlayStreak(
      current: current,
      best: best,
      lastPlayedAt: last.toDate(),
    );
  }

  Future<void> recordCompletion(String? uid) async {
    if (uid == null || uid != _uid || !_recording.add(uid)) return;
    final store = cloudDb;
    final activity = store.collection('playActivity').doc(uid);
    final streakRef = store.collection('streaks').doc(uid);
    try {
      // Transactions fail offline instead of crediting a queued play on a later day.
      await store.runTransaction((transaction) async {
        if (_uid != uid) throw StateError('Account changed');
        transaction.set(activity, {
          'uid': uid,
          'completedAt': FieldValue.serverTimestamp(),
        });
      }, timeout: const Duration(seconds: 10));
      if (_uid != uid) return;
      final result = await store.runTransaction((transaction) async {
        final event = await transaction.get(activity);
        final previous = await transaction.get(streakRef);
        if (_uid != uid) throw StateError('Account changed');
        final time = event.data()?['completedAt'];
        if (time is! Timestamp) throw StateError('Missing server play time');
        final before = _decode(previous.data());
        final next = before.afterCompletion(time.toDate());
        if (!identical(before, next)) {
          transaction.set(streakRef, {
            'uid': uid,
            'current': next.current,
            'best': next.best,
            'lastPlayedAt': time,
          });
        }
        return next;
      }, timeout: const Duration(seconds: 10));
      if (_uid != uid) return;
      _streak = result;
      _cached = false;
      _loading = false;
      _syncFailed = false;
      notifyListeners();
    } catch (error) {
      if (_uid == uid) {
        _loading = false;
        _syncFailed = true;
        notifyListeners();
      }
      debugPrint('[StreakService] Streak not credited: $error');
    } finally {
      _recording.remove(uid);
    }
  }
}
