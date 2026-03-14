import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

/// Custom painter that creates the signature growing tree visualization
/// This is the emotional heart of Booklify - every reading session grows the tree
class TreePainter extends CustomPainter {
  final double growthStage;
  final int completedDays;
  final int level;
  final Animation<double> animation;
  final List<Color> leafColors;
  final GardenWeather weather;

  TreePainter({
    required this.growthStage,
    required this.completedDays,
    required this.level,
    required this.animation,
    this.leafColors = const [
      Color(0xFF7AB87A), // Garden leaf
      Color(0xFF5A9A5A), // Darker leaf
      Color(0xFF4A7C59), // Garden moss
    ],
    this.weather = GardenWeather.sunny,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.8);

    // Draw sky gradient based on weather
    _drawSky(canvas, size, center);

    // Draw ground
    _drawGround(canvas, size);

    // Draw grass tufts
    _drawGrass(canvas, size, center);

    // Draw tree based on growth stage
    _drawTree(canvas, size, center);

    // Draw leaves
    _drawLeaves(canvas, size, center);

    // Draw flowers for achievements
    if (level > 1) {
      _drawFlowers(canvas, size, center);
    }

    // Draw level badges for higher levels
    if (level >= 5) {
      _drawLevelBadges(canvas, size, center);
    }

    // Draw weather effects
    _drawWeatherEffects(canvas, size, center);
  }

  void _drawSky(Canvas canvas, Size size, Offset center) {
    Color skyColor1;
    Color skyColor2;

    switch (weather) {
      case GardenWeather.sunny:
        skyColor1 = Color(0xFF87CEEB); // Sky blue
        skyColor2 = Color(0xFFE0F7FA); // Light cyan
        break;
      case GardenWeather.cloudy:
        skyColor1 = Color(0xFFB0BEC5); // Blue grey
        skyColor2 = Color(0xFFCFD8DC); // Light grey
        break;
      case GardenWeather.stormy:
        skyColor1 = Color(0xFF546E7A); // Dark blue grey
        skyColor2 = Color(0xFF78909C); // Medium grey
        break;
    }

    final skyGradient = RadialGradient(
      colors: [
        skyColor1.withOpacity(0.3),
        skyColor2.withOpacity(0.1),
      ],
    );

    final skyPaint = Paint()
      ..shader = skyGradient.createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.6),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      skyPaint,
    );
  }

  void _drawGround(Canvas canvas, Size size) {
    final groundPaint = Paint()
      ..color = Color(0xFF5D4E37); // Garden soil

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, size.height * 0.85, size.width, size.height * 0.15),
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      groundPaint,
    );
  }

  void _drawGrass(Canvas canvas, Size size, Offset center) {
    final grassPaint = Paint()
      ..color = Color(0xFF6B8E23) // Grass green
      ..strokeWidth = 2.0;

    // Animated grass that sways with the weather
    final swayOffset = math.sin(animation.value * 2 * math.pi) * 5.0;

    for (int i = 0; i < 20; i++) {
      final x = (i * size.width / 20) + (size.width / 40);
      final height = 8.0 + (i % 3) * 4.0;

      final path = Path();
      final tipX = x + swayOffset * ((i % 3 - 1) * 0.3);

      path.moveTo(x, size.height * 0.85);
      path.quadraticBezierTo(
        x - 3 + swayOffset * 0.2,
        size.height * 0.85 - height / 2,
        tipX,
        size.height * 0.85 - height,
      );
      path.quadraticBezierTo(
        x + 3 + swayOffset * 0.2,
        size.height * 0.85 - height / 2,
        x,
        size.height * 0.85,
      );

      canvas.drawPath(path, grassPaint);
    }
  }

  void _drawTree(Canvas canvas, Size size, Offset center) {
    final trunkHeight = size.height * 0.4 * growthStage * animation.value;
    final trunkWidth = 20.0 + (30.0 * growthStage * animation.value);

    // Draw trunk with gradient
    final trunkGradient = LinearGradient(
      colors: [
        Color(0xFF8B4513), // Saddle brown
        Color(0xFFA0522D), // Sienna
        Color(0xFF6B3E26), // Dark brown
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(
      Rect.fromCircle(center: center, radius: trunkWidth),
    );

    final trunkPaint = Paint()
      ..shader = trunkGradient
      ..style = PaintingStyle.stroke
      ..strokeWidth = trunkWidth
      ..strokeCap = StrokeCap.round;

    final trunkPath = Path();
    trunkPath.moveTo(center.dx, size.height * 0.85);
    trunkPath.quadraticBezierTo(
      center.dx,
      size.height * 0.85 - trunkHeight / 2,
      center.dx,
      size.height * 0.85 - trunkHeight,
    );

    canvas.drawPath(trunkPath, trunkPaint);

    // Draw branches if growth is sufficient
    if (growthStage > 0.3) {
      _drawBranches(canvas, size, center, trunkHeight, growthStage);
    }
  }

  void _drawBranches(Canvas canvas, Size size, Offset center, double trunkHeight, double growth) {
    final branchPaint = Paint()
      ..color = Color(0xFF8B4513)
      ..strokeWidth = 8.0 * growth
      ..strokeCap = StrokeCap.round;

    // Left main branch
    final leftBranch = Path();
    leftBranch.moveTo(center.dx, size.height * 0.85 - trunkHeight * 0.7);
    leftBranch.quadraticBezierTo(
      center.dx - 40 * growth,
      size.height * 0.85 - trunkHeight * 0.6,
      center.dx - 60 * growth,
      size.height * 0.85 - trunkHeight * 0.5,
    );
    canvas.drawPath(leftBranch, branchPaint);

    // Right main branch
    final rightBranch = Path();
    rightBranch.moveTo(center.dx, size.height * 0.85 - trunkHeight * 0.6);
    rightBranch.quadraticBezierTo(
      center.dx + 50 * growth,
      size.height * 0.85 - trunkHeight * 0.5,
      center.dx + 70 * growth,
      size.height * 0.85 - trunkHeight * 0.4,
    );
    canvas.drawPath(rightBranch, branchPaint);

    // Sub-branches for more mature trees
    if (growth > 0.6) {
      _drawSubBranches(canvas, size, center, trunkHeight, growth);
    }
  }

  void _drawSubBranches(Canvas canvas, Size size, Offset center, double trunkHeight, double growth) {
    final branchPaint = Paint()
      ..color = Color(0xFF8B4513)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Left sub-branches
    for (int i = 0; i < 3; i++) {
      final subBranch = Path();
      final startX = center.dx - 30 * growth - (i * 15);
      final startY = size.height * 0.85 - trunkHeight * 0.5;

      subBranch.moveTo(startX, startY);
      subBranch.quadraticBezierTo(
        startX - 20,
        startY - 20,
        startX - 25,
        startY - 35,
      );

      canvas.drawPath(subBranch, branchPaint);
    }

    // Right sub-branches
    for (int i = 0; i < 3; i++) {
      final subBranch = Path();
      final startX = center.dx + 40 * growth + (i * 15);
      final startY = size.height * 0.85 - trunkHeight * 0.4;

      subBranch.moveTo(startX, startY);
      subBranch.quadraticBezierTo(
        startX + 20,
        startY - 20,
        startX + 25,
        startY - 35,
      );

      canvas.drawPath(subBranch, branchPaint);
    }
  }

  void _drawLeaves(Canvas canvas, Size size, Offset center) {
    final trunkHeight = size.height * 0.4 * growthStage;

    for (int i = 0; i < completedDays; i++) {
      final leafPaint = Paint()
        ..color = leafColors[i % leafColors.length].withOpacity(0.8)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);

      // Position leaves around the canopy with animation delays
      final angle = (i / completedDays) * 2 * math.pi;
      final radius = 40.0 + (i % 5) * 15.0;
      final leafX = center.dx + radius * math.cos(angle) * growthStage;
      final leafY = (size.height * 0.85 - trunkHeight * 0.8) + radius * math.sin(angle) * 0.5;

      // Animate leaf growth
      final delay = (i / math.max(1, completedDays)) * 0.5;
      final animatedValue = ((animation.value - delay).clamp(0.0, 0.5) * 2).clamp(0.0, 1.0);

      if (animatedValue > 0) {
        canvas.drawCircle(
          Offset(leafX, leafY),
          8.0 * animatedValue + (i % 3) * 2.0,
          leafPaint,
        );
      }
    }
  }

  void _drawFlowers(Canvas canvas, Size size, Offset center) {
    final flowerColors = [
      Color(0xFFF48FB1), // Pink
      Color(0xFFFFE082), // Yellow
      Color(0xFFCE93D8), // Purple
      Color(0xFFFFAB91), // Orange
    ];

    final trunkHeight = size.height * 0.4 * growthStage;

    for (int i = 0; i < level; i++) {
      final flowerPaint = Paint()
        ..color = flowerColors[i % flowerColors.length]
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.0);

      // Position flowers in upper canopy
      final angle = (i / level) * 2 * math.pi + (animation.value * 2 * math.pi);
      final radius = 30.0 + (i % 4) * 12.0;
      final flowerX = center.dx + radius * math.cos(angle) * growthStage;
      final flowerY = (size.height * 0.85 - trunkHeight * 0.9) + radius * math.sin(angle) * 0.4;

      // Animate flowers
      final delay = (i / level) * 0.3;
      final animatedValue = ((animation.value - delay).clamp(0.0, 0.3) * 3.33).clamp(0.0, 1.0);

      if (animatedValue > 0) {
        // Draw flower petals
        for (int j = 0; j < 5; j++) {
          final petalAngle = (j / 5) * 2 * math.pi;
          final petalX = flowerX + 5 * math.cos(petalAngle) * animatedValue;
          final petalY = flowerY + 5 * math.sin(petalAngle) * animatedValue;

          canvas.drawCircle(
            Offset(petalX, petalY),
            4.0 * animatedValue,
            flowerPaint,
          );
        }

        // Draw flower center
        canvas.drawCircle(
          Offset(flowerX, flowerY),
          2.5 * animatedValue,
          Paint()..color = Color(0xFFFFEB3B), // Gold center
        );
      }
    }
  }

  void _drawLevelBadges(Canvas canvas, Size size, Offset center) {
    final badgePaint = Paint()
      ..color = Color(0xFFFFD700) // Gold
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);

    final badgeCount = (level / 5).floor();

    for (int i = 0; i < badgeCount; i++) {
      final angle = (i / math.max(1, badgeCount)) * 2 * math.pi + (animation.value * 2 * math.pi);
      final radius = 90.0 + (i * 10);
      final badgeX = center.dx + radius * math.cos(angle);
      final badgeY = size.height * 0.3 + radius * math.sin(angle) * 0.3;

      // Draw star badge
      _drawStar(canvas, Offset(badgeX, badgeY), 8.0, badgePaint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const points = 5;
    const innerRadius = radius * 0.4;

    for (int i = 0; i < points * 2; i++) {
      final r = i % 2 == 0 ? radius : innerRadius;
      final angle = (i / (points * 2)) * math.pi * 2 - math.pi / 2;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawWeatherEffects(Canvas canvas, Size size, Offset center) {
    switch (weather) {
      case GardenWeather.sunny:
        _drawSun(canvas, size);
        break;
      case GardenWeather.cloudy:
        _drawClouds(canvas, size);
        break;
      case GardenWeather.stormy:
        _drawRain(canvas, size);
        break;
    }
  }

  void _drawSun(Canvas canvas, Size size) {
    final sunPaint = Paint()
      ..color = Color(0xFFFFF176).withOpacity(0.8)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0);

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      30.0,
      sunPaint,
    );
  }

  void _drawClouds(Canvas canvas, Size size) {
    final cloudPaint = Paint()
      ..color = Color(0xFFFFFFFF).withOpacity(0.7)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0);

    for (int i = 0; i < 3; i++) {
      final x = size.width * 0.2 + (i * size.width * 0.3);
      final y = size.height * 0.1 + (i * 20.0);

      canvas.drawCircle(Offset(x, y), 25.0, cloudPaint);
      canvas.drawCircle(Offset(x + 20, y + 5), 20.0, cloudPaint);
      canvas.drawCircle(Offset(x - 15, y + 8), 18.0, cloudPaint);
    }
  }

  void _drawRain(Canvas canvas, Size size) {
    final rainPaint = Paint()
      ..color = Color(0xFF64B5F6).withOpacity(0.5)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 20; i++) {
      final x = (i * size.width / 20) + (animation.value * 10) % size.width;
      final y = (i * size.height / 20 + animation.value * 100) % size.height;

      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + 10),
        rainPaint,
      );
    }
  }

  @override
  bool shouldRepaint(TreePainter oldDelegate) {
    return oldDelegate.growthStage != growthStage ||
        oldDelegate.completedDays != completedDays ||
        oldDelegate.level != level ||
        oldDelegate.weather != weather;
  }
}

enum GardenWeather { sunny, cloudy, stormy }