import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NatureLeafBackground extends StatelessWidget {
  final Widget child;

  const NatureLeafBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: AppTheme.getBg(context))),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _NatureAtmospherePainter(
                isDark: AppTheme.isDark(context),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _NatureAtmospherePainter extends CustomPainter {
  final bool isDark;

  const _NatureAtmospherePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final alpha = isDark ? 1.0 : .35;
    for (final glow in [
      (const Alignment(-1.1, -.9), AppTheme.emerald, .16),
      (const Alignment(1.1, -.5), AppTheme.blue, .11),
      (const Alignment(.55, 1.2), AppTheme.emerald, .12),
    ]) {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = RadialGradient(
            center: glow.$1,
            radius: .8,
            colors: [
              glow.$2.withValues(alpha: glow.$3 * alpha),
              Colors.transparent,
            ],
          ).createShader(bounds),
      );
    }
    final wave = Path()
      ..moveTo(0, size.height - 53)
      ..cubicTo(
        size.width * .25,
        size.height - 33,
        size.width * .31,
        size.height + 23,
        size.width * .61,
        size.height - 13,
      )
      ..cubicTo(
        size.width * .78,
        size.height - 37,
        size.width * .92,
        size.height - 57,
        size.width,
        size.height - 51,
      );
    final waveBounds = Rect.fromLTWH(0, size.height - 65, size.width, 90);
    final shader = LinearGradient(
      colors: [
        AppTheme.royalBlue.withValues(alpha: .55 * alpha),
        const Color(0xFF125DFF).withValues(alpha: .4 * alpha),
        AppTheme.emerald.withValues(alpha: .6 * alpha),
        AppTheme.blue.withValues(alpha: .3 * alpha),
      ],
    ).createShader(waveBounds);
    canvas.drawPath(
      wave,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 17),
    );
    canvas.drawPath(
      wave,
      Paint()
        ..shader = shader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final fill = Path.from(wave)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.blue.withValues(alpha: .09 * alpha),
            Colors.transparent,
          ],
        ).createShader(waveBounds),
    );
  }

  @override
  bool shouldRepaint(covariant _NatureAtmospherePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
