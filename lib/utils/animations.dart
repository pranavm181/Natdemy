import 'package:flutter/material.dart';

/// Minimalistic animation utilities for the app
class AppAnimations {
  // Animation durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);

  // Animation curves
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve smoothCurve = Curves.easeInOutCubic;

  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: delay),
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide in from bottom animation
  static Widget slideInBottom({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double offset = 20.0,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0.0),
      duration: duration + Duration(milliseconds: delay),
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide in from right animation
  static Widget slideInRight({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double offset = 20.0,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0.0),
      duration: duration + Duration(milliseconds: delay),
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Scale animation
  static Widget scaleIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = bounceCurve,
    double begin = 0.8,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: begin, end: 1.0),
      duration: duration + Duration(milliseconds: delay),
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Combined fade and slide animation
  static Widget fadeSlideIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double offset = 20.0,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: delay),
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Staggered animation for list items
  static Widget staggeredAnimation({
    required Widget child,
    required int index,
    Duration duration = normal,
    Curve curve = defaultCurve,
    int staggerDelay = 50,
  }) {
    return fadeSlideIn(
      child: child,
      duration: duration,
      curve: curve,
      delay: index * staggerDelay,
    );
  }

  /// Slide in from left animation
  static Widget slideInLeft({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double offset = 20.0,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -offset, end: 0.0),
      duration: duration + Duration(milliseconds: delay),
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value, 0),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Subtle pulse animation (for icons, badges, etc.)
  static Widget pulse({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
    double minScale = 0.95,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: minScale, end: 1.0),
      duration: duration + Duration(milliseconds: delay),
      curve: Curves.easeInOut,
      onEnd: () {
        // This will restart automatically due to TweenAnimationBuilder
      },
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Fade and scale combined (gentle entrance)
  static Widget fadeScaleIn({
    required Widget child,
    Duration duration = normal,
    Curve curve = defaultCurve,
    double beginScale = 0.9,
    int delay = 0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration + Duration(milliseconds: delay),
      curve: curve,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: beginScale + (1.0 - beginScale) * value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Custom page route with fade transition
class FadePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  FadePageRoute({required this.builder});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => AppAnimations.normal;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

/// Custom page route with slide transition
class SlidePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final SlideDirection direction;

  SlidePageRoute({
    required this.builder,
    this.direction = SlideDirection.right,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => AppAnimations.normal;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    Offset begin;
    switch (direction) {
      case SlideDirection.right:
        begin = const Offset(1.0, 0.0);
        break;
      case SlideDirection.left:
        begin = const Offset(-1.0, 0.0);
        break;
      case SlideDirection.top:
        begin = const Offset(0.0, -1.0);
        break;
      case SlideDirection.bottom:
        begin = const Offset(0.0, 1.0);
        break;
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: AppAnimations.defaultCurve,
      )),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

enum SlideDirection { right, left, top, bottom }

/// Animated list item wrapper
class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.duration = AppAnimations.normal,
    this.staggerDelay = 50,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final int staggerDelay;

  @override
  Widget build(BuildContext context) {
    return AppAnimations.staggeredAnimation(
      child: child,
      index: index,
      duration: duration,
      staggerDelay: staggerDelay,
    );
  }
}

/// Animated card wrapper
class AnimatedCard extends StatelessWidget {
  const AnimatedCard({
    super.key,
    required this.child,
    this.duration = AppAnimations.normal,
    this.delay = 0,
  });

  final Widget child;
  final Duration duration;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return AppAnimations.fadeSlideIn(
      child: child,
      duration: duration,
      delay: delay,
    );
  }
}

/// Animated button wrapper
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.duration = AppAnimations.fast,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppAnimations.defaultCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    if (widget.onPressed != null) {
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

