import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:word_explorer/data/word_repository.dart';
import 'package:word_explorer/screens/game_screen.dart';
import 'package:word_explorer/services/database_service.dart';
import 'package:word_explorer/theme/app_theme.dart';
import 'package:word_explorer/widgets/word_highlighter_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.instance.init();
    await DatabaseService.instance.setCoins(200);
  });

  Future<Rect> pumpGame(
    WidgetTester tester, {
    required Size size,
    String mode = 'english',
    int level = 1,
    bool dark = true,
    double scale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    final landscape = size.width > size.height;
    final padding = landscape
        ? const EdgeInsets.fromLTRB(24, 8, 12, 16)
        : const EdgeInsets.only(top: 24, bottom: 16);
    tester.view.padding = FakeViewPadding(
      left: padding.left,
      top: padding.top,
      right: padding.right,
      bottom: padding.bottom,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightThemeData,
        darkTheme: AppTheme.darkThemeData,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: GameScreen(
          key: ValueKey('$mode-$level'),
          mode: mode,
          level: level,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    return Rect.fromLTRB(
      padding.left,
      padding.top,
      size.width - padding.right,
      size.height - padding.bottom,
    );
  }

  void contained(Rect outer, Rect inner, String reason) {
    expect(
      outer.inflate(0.01).contains(inner.topLeft),
      isTrue,
      reason: '$reason: $inner outside $outer',
    );
    expect(
      outer.inflate(0.01).contains(inner.bottomRight),
      isTrue,
      reason: '$reason: $inner outside $outer',
    );
  }

  void verifyLayout(
    WidgetTester tester,
    Rect safeBounds,
    String mode,
    int level,
  ) {
    final clues = WordRepository.getClues(mode, level);
    final card = tester.getRect(find.byKey(const ValueKey('game-clues')));
    contained(safeBounds, card, 'clue card');
    expect(find.byType(Scrollable), findsNothing);
    for (var i = 0; i < clues.length; i++) {
      final chip = find.byKey(ValueKey('game-clue-$i'));
      final text = find.descendant(
        of: chip,
        matching: find.text(clues[i].display),
      );
      expect(text, findsOneWidget);
      final chipRect = tester.getRect(chip);
      contained(card, chipRect, 'clue $i chip');
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: text, matching: find.byType(RichText)),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
      final boxes = paragraph.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: clues[i].display.length),
      );
      expect(boxes, isNotEmpty);
      for (final box in boxes) {
        final glyphBounds = MatrixUtils.transformRect(
          paragraph.getTransformTo(null),
          box.toRect(),
        );
        contained(chipRect, glyphBounds, 'clue $i glyphs');
        contained(safeBounds, glyphBounds, 'clue $i visible');
        RenderObject child = paragraph;
        while (child.parent != null) {
          final parent = child.parent!;
          final clip = parent.describeApproximatePaintClip(child);
          if (clip != null) {
            contained(
              MatrixUtils.transformRect(parent.getTransformTo(null), clip),
              glyphBounds,
              'clue $i ancestor clip',
            );
          }
          child = parent;
        }
      }
    }
    final board = tester.getRect(find.byKey(const ValueKey('game-grid')));
    contained(safeBounds, board, 'board');
    expect(board.width, closeTo(board.height, 0.01));
    expect(
      board.width / 8,
      greaterThanOrEqualTo(20),
      reason: 'usable cell targets',
    );
    expect(board.overlaps(card), isFalse);
    for (final action in ['hint', 'clear', 'shuffle']) {
      final finder = find.byKey(ValueKey('game-action-$action'));
      final rect = tester.getRect(finder);
      contained(safeBounds, rect, action);
      expect(rect.width, greaterThanOrEqualTo(44));
      expect(rect.height, greaterThanOrEqualTo(44));
      expect(board.overlaps(rect), isFalse);
      expect(finder.hitTestable(), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  }

  const sizes = [
    Size(320, 480),
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(412, 915),
    Size(540, 1200),
    Size(480, 320),
    Size(640, 360),
    Size(844, 390),
  ];
  for (final size in sizes) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets('all clues fit $size dark=$dark scale=$scale', (
          tester,
        ) async {
          for (final entry in [
            ('english', 30),
            ('hindi', 20),
            ('master', 50),
          ]) {
            final bounds = await pumpGame(
              tester,
              size: size,
              mode: entry.$1,
              level: entry.$2,
              dark: dark,
              scale: scale,
            );
            verifyLayout(tester, bounds, entry.$1, entry.$2);
          }
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  }

  testWidgets('every level retains every clue on the smallest phone', (
    tester,
  ) async {
    for (final mode in ['english', 'hindi', 'master']) {
      for (var level = 1; level <= WordRepository.totalLevels; level++) {
        final bounds = await pumpGame(
          tester,
          size: const Size(320, 480),
          mode: mode,
          level: level,
          scale: 1.3,
        );
        verifyLayout(tester, bounds, mode, level);
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  WordHighlighterPainter painter(WidgetTester tester) {
    return tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((widget) => widget.painter)
        .whereType<WordHighlighterPainter>()
        .single;
  }

  List<Offset> wordPath(WidgetTester tester, String word) {
    final letters = List.generate(
      8,
      (row) => List.generate(8, (col) {
        final text = find.descendant(
          of: find.byKey(ValueKey('game-cell-$row-$col')),
          matching: find.byType(Text),
        );
        return tester.widget<Text>(text).data!;
      }),
    );
    for (var row = 0; row < 8; row++) {
      for (var col = 0; col < 8; col++) {
        for (final direction in [
          (0, 1),
          (1, 0),
          (-1, 0),
          (1, 1),
          (1, -1),
          (-1, 1),
          (-1, -1),
        ]) {
          final path = <Offset>[];
          for (var i = 0; i < word.length; i++) {
            final r = row + direction.$1 * i;
            final c = col + direction.$2 * i;
            if (r < 0 ||
                r >= 8 ||
                c < 0 ||
                c >= 8 ||
                letters[r][c] != word[i]) {
              break;
            }
            path.add(tester.getCenter(find.byKey(ValueKey('game-cell-$r-$c'))));
          }
          if (path.length == word.length) return path;
        }
      }
    }
    fail('No board path for $word');
  }

  testWidgets(
    'drag, clear, shuffle and hint preserve found words across rotation',
    (tester) async {
      var bounds = await pumpGame(tester, size: const Size(390, 844));
      final clues = WordRepository.getClues('english', 1);
      final path = wordPath(tester, clues.first.answer);
      final gesture = await tester.startGesture(path.first);
      await gesture.moveBy((path[1] - path.first) * 0.65);
      await tester.pump();
      for (final point in path.skip(1)) {
        await gesture.moveTo(point);
        await tester.pump();
      }
      expect(painter(tester).selectedCells, isNotEmpty);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 350));
      expect(painter(tester).highlights.single.word, clues.first.answer);
      expect(find.text('1/10'), findsOneWidget);
      verifyLayout(tester, bounds, 'english', 1);

      final boardWidget = tester.widget(
        find.byKey(const ValueKey('game-grid')),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(
        identical(
          boardWidget,
          tester.widget(find.byKey(const ValueKey('game-grid'))),
        ),
        isTrue,
      );
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('game-timer'))).data,
        isNot('00:00'),
      );

      await tester.tap(find.byKey(const ValueKey('game-action-hint')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Get a Word Hint'), findsOneWidget);
      await tester.tap(find.text('Use Hint (30 Coins)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(DatabaseService.instance.getCoins(), 170);
      expect(painter(tester).hintCells, isNotEmpty);
      await tester.tap(find.byKey(const ValueKey('game-action-clear')));
      await tester.pump();
      expect(painter(tester).hintCells, isEmpty);
      expect(painter(tester).selectedCells, isEmpty);
      expect(painter(tester).highlights.single.word, clues.first.answer);

      final paths = {
        for (final clue in clues) clue.answer: wordPath(tester, clue.answer),
      };
      await tester.tap(find.byKey(const ValueKey('game-action-shuffle')));
      await tester.pump();
      for (final clue in clues) {
        expect(wordPath(tester, clue.answer), paths[clue.answer]);
      }
      expect(painter(tester).highlights.single.word, clues.first.answer);
      await tester.pump(const Duration(seconds: 4));

      bounds = await pumpGame(
        tester,
        size: const Size(480, 320),
        scale: 1.3,
        dark: false,
      );
      expect(find.text('1/10'), findsOneWidget);
      expect(painter(tester).highlights.single.word, clues.first.answer);
      verifyLayout(tester, bounds, 'english', 1);
      final foundText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('game-clue-0')),
          matching: find.byType(Text),
        ),
      );
      expect(foundText.style!.decoration, TextDecoration.lineThrough);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
