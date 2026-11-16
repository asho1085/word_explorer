import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:word_explorer/models/leaderboard_entry.dart';
import 'package:word_explorer/screens/leaderboard_screen.dart';
import 'package:word_explorer/services/leaderboard_service.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpScreen(
    WidgetTester tester,
    LeaderboardService service, {
    double width = 320,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: LeaderboardScreen(service: service),
      ),
    );
    await tester.pump();
  }

  List<LeaderboardEntry> entries(int count) => [
    for (var i = 0; i < count; i++)
      LeaderboardEntry.fromDocument('uid-$i', {
        'username': 'An exceptionally long shared explorer name',
        'stars': 1000000 - i,
        'levelsCompleted': 42,
      }),
  ];

  testWidgets('unconfigured service has a finite unavailable state', (
    tester,
  ) async {
    await pumpScreen(tester, LeaderboardService());
    await tester.pumpAndSettle();
    expect(
      find.text('Leaderboard unavailable. Firebase is not configured.'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('AaravWordKing'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirmed empty rankings are honest and unranked', (
    tester,
  ) async {
    final source = StreamController<LeaderboardSnapshot>();
    final service = LeaderboardService(
      snapshots: () => source.stream,
      currentUid: () => 'me',
    );
    await pumpScreen(tester, service);
    source.add(const LeaderboardSnapshot([]));
    await tester.pumpAndSettle();
    expect(find.text('No public rankings yet.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('player-standing')),
      150,
    );
    expect(find.text('Unranked'), findsOneWidget);
    expect(service.getCurrentPlayerEntry(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    expect(source.hasListener, isFalse);
    await tester.runAsync(() => source.close());
  });

  testWidgets('query error shows retry and retry opens a new subscription', (
    tester,
  ) async {
    final sources = <StreamController<LeaderboardSnapshot>>[];
    final service = LeaderboardService(
      snapshots: () {
        final source = StreamController<LeaderboardSnapshot>();
        sources.add(source);
        return source.stream;
      },
      currentUid: () => null,
    );
    await pumpScreen(tester, service);
    sources.first.addError(StateError('permission denied'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load rankings. Check your connection and retry.'),
      findsOneWidget,
    );
    await tester.runAsync(() => tester.tap(find.text('Retry')));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(sources.length, 2);
    expect(sources.first.hasListener, isFalse);
    await tester.runAsync(() async {
      sources.last.add(const LeaderboardSnapshot([]));
    });
    await tester.pumpAndSettle();
    expect(find.text('No public rankings yet.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    for (final source in sources) {
      expect(source.hasListener, isFalse);
      await tester.runAsync(() => source.close());
    }
  });

  testWidgets('empty cache does not claim the global leaderboard is empty', (
    tester,
  ) async {
    final source = StreamController<LeaderboardSnapshot>();
    await pumpScreen(
      tester,
      LeaderboardService(
        snapshots: () => source.stream,
        currentUid: () => null,
      ),
    );
    source.add(const LeaderboardSnapshot([], isFromCache: true));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Offline or awaiting server confirmation. No cached rankings available.',
      ),
      findsOneWidget,
    );
    expect(find.text('No public rankings yet.'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(() => source.close());
  });

  for (final count in [1, 2, 3]) {
    for (final width in [320.0, 390.0]) {
      for (final textScale in [1.0, 2.0]) {
        testWidgets(
          '$count entries fit width=$width textScale=$textScale with UID identity',
          (tester) async {
            final source = StreamController<LeaderboardSnapshot>();
            final service = LeaderboardService(
              snapshots: () => source.stream,
              currentUid: () => 'uid-0',
            );
            await pumpScreen(
              tester,
              service,
              width: width,
              textScale: textScale,
            );
            source.add(LeaderboardSnapshot(entries(count)));
            await tester.pumpAndSettle();
            expect(find.text('YOU'), findsOneWidget);
            expect(service.getLeaderboard().length, count);
            expect(
              service
                  .getLeaderboard()
                  .where((entry) => entry.isCurrentPlayer)
                  .length,
              1,
            );
            expect(tester.takeException(), isNull);
            await tester.scrollUntilVisible(
              find.byKey(const ValueKey('player-standing')),
              150,
            );
            await tester.pumpAndSettle();
            expect(find.textContaining('Your Standing: #1'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(milliseconds: 1));
            expect(source.hasListener, isFalse);
            await tester.runAsync(() => source.close());
          },
        );
      }
    }
  }

  testWidgets('absent current player has no invented rank outside top 100', (
    tester,
  ) async {
    final source = StreamController<LeaderboardSnapshot>();
    await pumpScreen(
      tester,
      LeaderboardService(
        snapshots: () => source.stream,
        currentUid: () => 'outside',
      ),
    );
    source.add(LeaderboardSnapshot(entries(100)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('player-standing')),
      1800,
      maxScrolls: 30,
    );
    expect(find.text('Not in top 100'), findsOneWidget);
    expect(find.textContaining('#101'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(() => source.close());
  });
}
