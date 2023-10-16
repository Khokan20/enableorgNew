import 'package:flutter/material.dart';

class CustomSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final double thumbHeight;
  final double thumbBorderWidth;
  final Color thumbColor;

  CustomSliderThumbShape({
    this.thumbRadius = 14.0,
    this.thumbHeight = 13.0,
    this.thumbBorderWidth = 3.0,
    this.thumbColor = Colors.white,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(thumbRadius * 2, thumbHeight);
  }

  @override
void  paint(
  PaintingContext context,
  Offset center, {
  required Animation<double> activationAnimation,
  required Animation<double> enableAnimation,
  bool? isDiscrete,
  bool isOnTop = false,
  required TextPainter labelPainter,
  required RenderBox parentBox,
  required SliderThemeData sliderTheme,
  TextDirection? textDirection,
  Thumb? thumb,
  double? value,
  double? textScaleFactor,
  Size? sizeWithOverflow,
})  {
    final canvas = context.canvas;
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill
      ..strokeWidth = thumbBorderWidth;

    final centerOffset = Offset(center.dx, center.dy - thumbHeight / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(
          Offset(centerOffset.dx - thumbRadius, centerOffset.dy),
          Offset(centerOffset.dx + thumbRadius, centerOffset.dy + thumbHeight),
        ),
        Radius.circular(thumbRadius),
      ),
      paint,
    );
  }
}
