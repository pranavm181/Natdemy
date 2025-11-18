import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// A custom loading indicator with glowing purple ring and animated diamond
class ThemeLoadingIndicator extends StatefulWidget {
  const ThemeLoadingIndicator({
    super.key,
    this.size = 50.0,
    this.strokeWidth = 6.0,
    this.message,
    this.messageStyle,
  });

  final double size;
  final double strokeWidth;
  final String? message;
  final TextStyle? messageStyle;

  @override
  State<ThemeLoadingIndicator> createState() => _ThemeLoadingIndicatorState();
}

class _ThemeLoadingIndicatorState extends State<ThemeLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GlowingRingPainter(
                  progress: _controller.value,
                  size: widget.size,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 20),
          Text(
            widget.message!,
            style: widget.messageStyle ??
                TextStyle(
                  color: const Color(0xFF582DB0),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _GlowingRingPainter extends CustomPainter {
  final double progress;
  final double size;
  final double strokeWidth;

  _GlowingRingPainter({
    required this.progress,
    required this.size,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw glowing background ring
    final backgroundPaint = Paint()
      ..color = const Color(0xFFE9D5FF).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw glow effect layers
    for (int i = 0; i < 3; i++) {
      final glowPaint = Paint()
        ..color = const Color(0xFF8B5CF6).withOpacity(0.2 - (i * 0.05))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + (i * 4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 + (i * 4));

      canvas.drawCircle(center, radius, glowPaint);
    }

    // Draw animated progress arc
    final progressPaint = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * 0.7; // 70% of circle
    final startAngle = -math.pi / 2 + (progress * 2 * math.pi);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );

    // Draw animated diamond/square on the ring
    final diamondAngle = startAngle + sweepAngle;
    final diamondX = center.dx + radius * math.cos(diamondAngle);
    final diamondY = center.dy + radius * math.sin(diamondAngle);
    final diamondCenter = Offset(diamondX, diamondY);

    // Draw diamond with glow
    final diamondGlowPaint = Paint()
      ..color = const Color(0xFF582DB0).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final diamondPaint = Paint()
      ..color = const Color(0xFF582DB0)
      ..style = PaintingStyle.fill;

    final diamondSize = strokeWidth * 0.8;
    final path = Path();
    path.moveTo(diamondCenter.dx, diamondCenter.dy - diamondSize);
    path.lineTo(diamondCenter.dx + diamondSize, diamondCenter.dy);
    path.lineTo(diamondCenter.dx, diamondCenter.dy + diamondSize);
    path.lineTo(diamondCenter.dx - diamondSize, diamondCenter.dy);
    path.close();

    // Draw glow first
    canvas.drawPath(path, diamondGlowPaint);
    // Draw diamond
    canvas.drawPath(path, diamondPaint);
  }

  @override
  bool shouldRepaint(_GlowingRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// A full-screen loading overlay with theme colors
class ThemeLoadingOverlay extends StatelessWidget {
  const ThemeLoadingOverlay({
    super.key,
    this.message,
    this.backgroundColor,
  });

  final String? message;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? Colors.white.withOpacity(0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const ThemeLoadingIndicator(
              size: 60.0,
              strokeWidth: 5.0,
            ),
            if (message != null) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message!,
                  style: TextStyle(
                    color: const Color(0xFF582DB0),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact loading indicator for buttons and small spaces
class ThemeLoadingIndicatorSmall extends StatefulWidget {
  const ThemeLoadingIndicatorSmall({
    super.key,
    this.size = 24.0,
    this.strokeWidth = 3.0,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  State<ThemeLoadingIndicatorSmall> createState() =>
      _ThemeLoadingIndicatorSmallState();
}

class _ThemeLoadingIndicatorSmallState
    extends State<ThemeLoadingIndicatorSmall>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _GlowingRingPainter(
              progress: _controller.value,
              size: widget.size,
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}

/// Pulsing dots loading indicator
class ThemePulsingDotsIndicator extends StatefulWidget {
  const ThemePulsingDotsIndicator({
    super.key,
    this.size = 8.0,
    this.spacing = 12.0,
    this.color,
  });

  final double size;
  final double spacing;
  final Color? color;

  @override
  State<ThemePulsingDotsIndicator> createState() =>
      _ThemePulsingDotsIndicatorState();
}

class _ThemePulsingDotsIndicatorState
    extends State<ThemePulsingDotsIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<Timer> _staggerTimers;

  @override
  void initState() {
    super.initState();
    _animations = [];
    _staggerTimers = [];
    _controllers = List.generate(3, (index) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      
      final animation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
      
      _animations.add(animation);
      
      // Stagger the animations
      final timer = Timer(Duration(milliseconds: index * 200), () {
        if (!mounted) return;
        controller.repeat(reverse: true);
      });
      _staggerTimers.add(timer);
      
      return controller;
    });
  }

  @override
  void dispose() {
    for (final timer in _staggerTimers) {
      timer.cancel();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (widget.color ?? const Color(0xFF582DB0))
                    .withOpacity(_animations[index].value),
                boxShadow: [
                  BoxShadow(
                    color: (widget.color ?? const Color(0xFF8B5CF6))
                        .withOpacity(_animations[index].value * 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

/// Shimmer loading effect
class ThemeShimmerLoader extends StatefulWidget {
  const ThemeShimmerLoader({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<ThemeShimmerLoader> createState() => _ThemeShimmerLoaderState();
}

class _ThemeShimmerLoaderState extends State<ThemeShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - _controller.value * 2, 0.0),
              end: Alignment(1.0 - _controller.value * 2, 0.0),
              colors: [
                widget.baseColor ?? const Color(0xFFE9D5FF),
                widget.highlightColor ?? const Color(0xFF8B5CF6),
                widget.baseColor ?? const Color(0xFFE9D5FF),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Animated bars loading indicator
class ThemeBarsIndicator extends StatefulWidget {
  const ThemeBarsIndicator({
    super.key,
    this.width = 4.0,
    this.height = 40.0,
    this.spacing = 6.0,
    this.color,
  });

  final double width;
  final double height;
  final double spacing;
  final Color? color;

  @override
  State<ThemeBarsIndicator> createState() => _ThemeBarsIndicatorState();
}

class _ThemeBarsIndicatorState extends State<ThemeBarsIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _animations = [];
    _controllers = List.generate(5, (index) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      
      final animation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
      
      _animations.add(animation);
      
      // Stagger the animations
      Future.delayed(Duration(milliseconds: index * 100), () {
        controller.repeat(reverse: true);
      });
      
      return controller;
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              width: widget.width,
              height: widget.height * _animations[index].value,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.width / 2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (widget.color ?? const Color(0xFF8B5CF6))
                        .withOpacity(_animations[index].value),
                    (widget.color ?? const Color(0xFF582DB0))
                        .withOpacity(_animations[index].value),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.color ?? const Color(0xFF8B5CF6))
                        .withOpacity(_animations[index].value * 0.3),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

/// Spinning squares/diamonds indicator
class ThemeSpinningSquaresIndicator extends StatefulWidget {
  const ThemeSpinningSquaresIndicator({
    super.key,
    this.size = 50.0,
    this.squareSize = 12.0,
    this.color,
  });

  final double size;
  final double squareSize;
  final Color? color;

  @override
  State<ThemeSpinningSquaresIndicator> createState() =>
      _ThemeSpinningSquaresIndicatorState();
}

class _ThemeSpinningSquaresIndicatorState
    extends State<ThemeSpinningSquaresIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Top square
              Transform.translate(
                offset: Offset(0, -widget.size / 3),
                child: Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: Container(
                    width: widget.squareSize,
                    height: widget.squareSize,
                    decoration: BoxDecoration(
                      color: widget.color ?? const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.color ?? const Color(0xFF8B5CF6))
                              .withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Right square
              Transform.translate(
                offset: Offset(widget.size / 3, 0),
                child: Transform.rotate(
                  angle: _controller.value * 2 * math.pi + math.pi / 2,
                  child: Container(
                    width: widget.squareSize,
                    height: widget.squareSize,
                    decoration: BoxDecoration(
                      color: widget.color ?? const Color(0xFF582DB0),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.color ?? const Color(0xFF582DB0))
                              .withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom square
              Transform.translate(
                offset: Offset(0, widget.size / 3),
                child: Transform.rotate(
                  angle: _controller.value * 2 * math.pi + math.pi,
                  child: Container(
                    width: widget.squareSize,
                    height: widget.squareSize,
                    decoration: BoxDecoration(
                      color: widget.color ?? const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.color ?? const Color(0xFF8B5CF6))
                              .withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Left square
              Transform.translate(
                offset: Offset(-widget.size / 3, 0),
                child: Transform.rotate(
                  angle: _controller.value * 2 * math.pi + 3 * math.pi / 2,
                  child: Container(
                    width: widget.squareSize,
                    height: widget.squareSize,
                    decoration: BoxDecoration(
                      color: widget.color ?? const Color(0xFF582DB0),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.color ?? const Color(0xFF582DB0))
                              .withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Wave loading indicator
class ThemeWaveIndicator extends StatefulWidget {
  const ThemeWaveIndicator({
    super.key,
    this.size = 50.0,
    this.color,
  });

  final double size;
  final Color? color;

  @override
  State<ThemeWaveIndicator> createState() => _ThemeWaveIndicatorState();
}

class _ThemeWaveIndicatorState extends State<ThemeWaveIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _animations = [];
    _controllers = List.generate(3, (index) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );
      
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        ),
      );
      
      _animations.add(animation);
      
      // Stagger the animations
      Future.delayed(Duration(milliseconds: index * 200), () {
        controller.repeat();
      });
      
      return controller;
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _WavePainter(
          animations: _animations,
          color: widget.color ?? const Color(0xFF582DB0),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final List<Animation<double>> animations;
  final Color color;

  _WavePainter({
    required this.animations,
    required this.color,
  }) : super(repaint: Listenable.merge(animations));

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < animations.length; i++) {
      final progress = animations[i].value;
      final waveRadius = radius * (0.3 + progress * 0.7);
      final opacity = 1.0 - progress;

      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      canvas.drawCircle(center, waveRadius, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => false;
}

/// Skeleton loader for cards/content
class ThemeSkeletonLoader extends StatelessWidget {
  const ThemeSkeletonLoader({
    super.key,
    this.width,
    this.height = 20.0,
    this.borderRadius = 8.0,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ThemeShimmerLoader(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFE9D5FF),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// A loading indicator with animated gradient rotation
class ThemeAnimatedLoadingIndicator extends StatefulWidget {
  const ThemeAnimatedLoadingIndicator({
    super.key,
    this.size = 50.0,
    this.strokeWidth = 4.0,
    this.message,
  });

  final double size;
  final double strokeWidth;
  final String? message;

  @override
  State<ThemeAnimatedLoadingIndicator> createState() =>
      _ThemeAnimatedLoadingIndicatorState();
}

class _ThemeAnimatedLoadingIndicatorState
    extends State<ThemeAnimatedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      const Color(0xFF8B5CF6),
                      const Color(0xFF582DB0),
                      const Color(0xFF8B5CF6),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(widget.strokeWidth),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (widget.message != null) ...[
                const SizedBox(height: 16),
                Text(
                  widget.message!,
                  style: TextStyle(
                    color: const Color(0xFF582DB0),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

