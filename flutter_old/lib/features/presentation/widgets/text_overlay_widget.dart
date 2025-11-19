import 'package:flutter/material.dart';
import 'package:tv_monitor/features/domain/entities/websocket_message_entity.dart';

class TextOverlayWidget extends StatefulWidget {
  final TextOverlayConfig config;

  const TextOverlayWidget({super.key, required this.config});

  @override
  State<TextOverlayWidget> createState() => _TextOverlayWidgetState();
}

class _TextOverlayWidgetState extends State<TextOverlayWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(TextOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    if (widget.config.animation == TextOverlayAnimation.scroll) {
      // Calculate duration based on speed (pixels per second)
      // We want the text to scroll completely across the screen
      final screenWidth = MediaQuery.of(context).size.width;
      final duration = Duration(milliseconds: ((screenWidth / widget.config.speed) * 1000).toInt());

      _controller = AnimationController(duration: duration, vsync: this)..repeat();

      // Determine animation direction based on position
      Offset begin;
      Offset end;

      switch (widget.config.position) {
        case TextOverlayPosition.top:
        case TextOverlayPosition.bottom:
          // Scroll horizontally (right to left)
          begin = const Offset(1.0, 0.0);
          end = const Offset(-1.0, 0.0);
          break;
        case TextOverlayPosition.left:
        case TextOverlayPosition.right:
          // Scroll vertically (bottom to top)
          begin = const Offset(0.0, 1.0);
          end = const Offset(0.0, -1.0);
          break;
      }

      _animation = Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _parseColor(String? colorStr, Color defaultColor) {
    if (colorStr == null) return defaultColor;

    try {
      // Support hex colors like "#FF5733" or "FF5733"
      String hexColor = colorStr.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // Add alpha if not present
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return defaultColor;
    }
  }

  Widget _buildTextContent() {
    final textColor = _parseColor(widget.config.textColor, Colors.white);
    final fontSize = widget.config.fontSize?.toDouble() ?? 24.0;

    final textWidget = Text(
      widget.config.text,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(blurRadius: 4.0, color: Colors.black.withValues(alpha: 0.8), offset: const Offset(2.0, 2.0))],
      ),
      maxLines: 1,
      overflow: TextOverflow.visible,
    );

    if (widget.config.animation == TextOverlayAnimation.scroll) {
      return SlideTransition(position: _animation, child: textWidget);
    } else {
      return textWidget;
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _parseColor(widget.config.backgroundColor, Colors.black.withValues(alpha: 0.6));

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: backgroundColor),
      child: _buildTextContent(),
    );

    // Position the overlay based on config
    switch (widget.config.position) {
      case TextOverlayPosition.top:
        return Positioned(top: 0, left: 0, right: 0, child: content);
      case TextOverlayPosition.bottom:
        return Positioned(bottom: 0, left: 0, right: 0, child: content);
      case TextOverlayPosition.left:
        return Positioned(left: 0, top: 0, bottom: 0, child: RotatedBox(quarterTurns: 3, child: content));
      case TextOverlayPosition.right:
        return Positioned(right: 0, top: 0, bottom: 0, child: RotatedBox(quarterTurns: 1, child: content));
    }
  }
}
