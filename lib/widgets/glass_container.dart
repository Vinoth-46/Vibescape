import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color color;
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.2,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color = Colors.white,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02), // Reduced shadow opacity for performance
              blurRadius: 10, // Reduced blur for faster rendering
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: color.withOpacity(opacity),
                borderRadius: borderRadius ?? BorderRadius.circular(20),
                border: border ??
                    Border.all(
                      color: Colors.white.withOpacity(0.2), // Reduced opacity
                      width: 1.0, // Reduced width
                    ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
