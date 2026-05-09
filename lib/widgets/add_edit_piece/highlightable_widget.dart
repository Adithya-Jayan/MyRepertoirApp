import 'package:flutter/material.dart';

class HighlightableWidget extends StatefulWidget {
  final Widget child;
  final bool isHighlighted;
  final VoidCallback? onHighlightComplete;

  const HighlightableWidget({
    super.key,
    required this.child,
    this.isHighlighted = false,
    this.onHighlightComplete,
  });

  @override
  State<HighlightableWidget> createState() => _HighlightableWidgetState();
}

class _HighlightableWidgetState extends State<HighlightableWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: Colors.amber.withValues(alpha: 0.3),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isHighlighted) {
      _startHighlight();
    }
  }

  @override
  void didUpdateWidget(HighlightableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _startHighlight();
    }
  }

  void _startHighlight() {
    _controller.forward().then((_) {
      _controller.reverse().then((_) {
        if (widget.onHighlightComplete != null) {
          widget.onHighlightComplete!();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
