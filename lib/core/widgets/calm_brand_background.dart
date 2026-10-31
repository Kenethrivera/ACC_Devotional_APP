import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'faith_decorations.dart';

class CalmBrandBackground extends StatelessWidget {
  final bool dark;
  final bool showCrossHero;
  final bool compact;

  const CalmBrandBackground({
    super.key,
    this.dark = false,
    this.showCrossHero = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? const [
                    Color(0xFF123754),
                    Color(0xFF1D5B85),
                    Color(0xFF102E49),
                  ]
                : const [
                    Color(0xFFF0F7FC),
                    AppColors.ivory,
                    Color(0xFFF8F3EE),
                  ],
            stops: const [0, 0.52, 1],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _OrganicLinesPainter(dark: dark),
              ),
            ),
            Positioned(
              top: -170,
              right: -110,
              child: _Glow(
                size: 430,
                color: dark
                    ? const Color(0x334AA4D1)
                    : const Color(0x325BA7E1),
              ),
            ),
            Positioned(
              top: compact ? -150 : -190,
              left: compact ? -130 : viewport.width * 0.10,
              child: _Glow(
                size: compact ? 360 : 560,
                color: dark
                    ? const Color(0x14F3D28F)
                    : const Color(0x2EF3D28F),
              ),
            ),
            Positioned(
              left: -190,
              top: 280,
              child: _Glow(
                size: 460,
                color: dark
                    ? const Color(0x1FC8A66B)
                    : const Color(0x66DCEADF),
              ),
            ),
            Positioned(
              right: -130,
              bottom: -190,
              child: _Glow(
                size: 420,
                color: dark
                    ? const Color(0x1FFFFFFF)
                    : const Color(0x55E9E4F5),
              ),
            ),
            Positioned(
              left: -120,
              top: 118,
              child: _SoftShape(
                width: 390,
                height: 142,
                angle: -0.16,
                color: dark
                    ? const Color(0x0FFFFFFF)
                    : const Color(0x42DCEADF),
              ),
            ),
            Positioned(
              right: -92,
              top: 430,
              child: _SoftShape(
                width: 320,
                height: 126,
                angle: 0.20,
                color: dark
                    ? const Color(0x0AFFFFFF)
                    : const Color(0x38E9E4F5),
              ),
            ),
            if (showCrossHero)
              Positioned.fill(
                child: CrossHeroArtwork(
                  alignment: compact
                      ? const Alignment(0.72, -0.10)
                      : Alignment.centerRight,
                  opacity: compact ? 0.30 : 0.48,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withAlpha(0)],
          stops: const [0, 1],
        ),
      ),
    );
  }
}

class _SoftShape extends StatelessWidget {
  final double width;
  final double height;
  final double angle;
  final Color color;

  const _SoftShape({
    required this.width,
    required this.height,
    required this.angle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.all(Radius.elliptical(width, height)),
        ),
      ),
    );
  }
}

class _OrganicLinesPainter extends CustomPainter {
  final bool dark;

  const _OrganicLinesPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final skyLine = Paint()
      ..color = dark ? const Color(0x18FFFFFF) : const Color(0x245BA7E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final sageLine = Paint()
      ..color = dark ? const Color(0x14FFFFFF) : const Color(0x38416F55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final upperPath = Path()
      ..moveTo(-30, size.height * 0.22)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.08,
        size.width * 0.36,
        size.height * 0.36,
        size.width * 0.62,
        size.height * 0.20,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.10,
        size.width * 0.91,
        size.height * 0.18,
        size.width + 30,
        size.height * 0.08,
      );
    canvas.drawPath(upperPath, skyLine);

    final lowerPath = Path()
      ..moveTo(-40, size.height * 0.75)
      ..cubicTo(
        size.width * 0.19,
        size.height * 0.61,
        size.width * 0.40,
        size.height * 0.88,
        size.width * 0.63,
        size.height * 0.70,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.56,
        size.width * 0.91,
        size.height * 0.82,
        size.width + 40,
        size.height * 0.68,
      );
    canvas.drawPath(lowerPath, sageLine);

    final dotPaint = Paint()
      ..color = dark ? const Color(0x12FFFFFF) : const Color(0x235BA7E1);
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 8; column++) {
        canvas.drawCircle(
          Offset(
            size.width * 0.08 + column * 13,
            size.height * 0.48 + row * 13,
          ),
          1.2,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicLinesPainter oldDelegate) {
    return oldDelegate.dark != dark;
  }
}
