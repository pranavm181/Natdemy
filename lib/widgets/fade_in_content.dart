import 'package:flutter/material.dart';

/// Widget that smoothly fades in content after loading/shimmer states
/// Prevents harsh appearance of content after loading indicators
class FadeInContent extends StatefulWidget {
  const FadeInContent({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.delay = const Duration(milliseconds: 100),
    this.slideOffset = 20.0,
    this.enableSlide = true,
  });

  final Widget child;
  final Duration duration;
  final Curve curve;
  final Duration delay;
  final double slideOffset;
  final bool enableSlide;

  @override
  State<FadeInContent> createState() => _FadeInContentState();
}

class _FadeInContentState extends State<FadeInContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: widget.curve,
      ),
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.enableSlide
          ? SlideTransition(
              position: _slideAnimation,
              child: widget.child,
            )
          : widget.child,
    );
  }
}

/// Wrapper for content that appears after shimmer loading
class SmoothContentTransition extends StatelessWidget {
  const SmoothContentTransition({
    super.key,
    required this.isLoading,
    required this.loadingWidget,
    required this.content,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
  });

  final bool isLoading;
  final Widget loadingWidget;
  final Widget content;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget;
    }

    return FadeInContent(
      duration: duration,
      curve: curve,
      child: content,
    );
  }
}
