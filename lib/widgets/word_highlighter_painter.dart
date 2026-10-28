import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_models.dart';

class WordHighlightItem {
  final String word;
  final GridCellCoord start;
  final GridCellCoord end;
  final Color color;
  double progress;

  WordHighlightItem({
    required this.word,
    required this.start,
    required this.end,
    required this.color,
    this.progress = 1.0,
  });
}

class WordHighlighterPainter extends CustomPainter {
  final int gridDim;
  final List<WordHighlightItem> highlights;
  final List<GridCellCoord> selectedCells;
  final Set<GridCellCoord> hintCells;
  final double animationValue;

  const WordHighlighterPainter({
    required this.gridDim,
    required this.highlights,
    required this.selectedCells,
    required this.hintCells,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (gridDim <= 0) return;

    final cellWidth = size.width / gridDim;
    final cellHeight = size.height / gridDim;
    // Optimal capsule width matching reference image: generous coverage with clean gap between rows
    final strokeWidth = min(cellWidth, cellHeight) * 0.76;

    Offset cellCenter(GridCellCoord coord) {
      return Offset(
        (coord.col + 0.5) * cellWidth,
        (coord.row + 0.5) * cellHeight,
      );
    }

    // 1. Draw Hint Pulsing highlights
    if (hintCells.isNotEmpty) {
      final hintPaint = Paint()
        ..color = const Color(0xFFF59E0B).withAlpha((110 + (animationValue * 90).toInt()).clamp(0, 255))
        ..style = PaintingStyle.fill;

      for (final cell in hintCells) {
        canvas.drawCircle(
          cellCenter(cell),
          min(cellWidth, cellHeight) * 0.42,
          hintPaint,
        );
      }
    }

    // 2. Draw Found Word Highlighter Capsules (Clean, simple, perfectly accurate)
    for (final h in highlights) {
      final p1 = cellCenter(h.start);
      final p2 = cellCenter(h.end);
      final currentEnd = Offset.lerp(p1, p2, h.progress.clamp(0.0, 1.0)) ?? p2;

      final capsulePaint = Paint()
        ..color = h.color.withAlpha(160) // Clean translucent highlighter
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;

      if (p1 == currentEnd) {
        canvas.drawCircle(
          p1,
          strokeWidth / 2,
          Paint()
            ..color = h.color.withAlpha(160)
            ..style = PaintingStyle.fill,
        );
      } else {
        canvas.drawLine(p1, currentEnd, capsulePaint);
      }
    }

    // 3. Draw Active Selection Dragging Capsule
    if (selectedCells.isNotEmpty) {
      const activeColor = Color(0xFF10B981); // Emerald selection

      if (selectedCells.length == 1) {
        canvas.drawCircle(
          cellCenter(selectedCells.first),
          strokeWidth / 2,
          Paint()
            ..color = activeColor.withAlpha(150)
            ..style = PaintingStyle.fill,
        );
      } else {
        final p1 = cellCenter(selectedCells.first);
        final p2 = cellCenter(selectedCells.last);

        final dragPaint = Paint()
          ..color = activeColor.withAlpha(160)
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

        canvas.drawLine(p1, p2, dragPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant WordHighlighterPainter oldDelegate) {
    return true;
  }
}
