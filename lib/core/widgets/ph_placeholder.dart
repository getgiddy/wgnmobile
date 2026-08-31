import 'package:flutter/material.dart';

import '../theme/wgn_colors.dart';
import '../theme/wgn_theme.dart';

/// Diagonal-striped placeholder block matching the design's `.ph-img`
/// (used wherever artwork/imagery hasn't been uploaded yet).
class PhPlaceholder extends StatelessWidget {
  const PhPlaceholder({
    super.key,
    this.width,
    this.height,
    this.radius = 0,
    this.label,
    this.child,
  });

  final double? width;
  final double? height;
  final double radius;
  final String? label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.wgn;
    final painted = CustomPaint(
      painter: _StripesPainter(c.ph1, c.ph2),
      // The stripes are dozens of paths and never change once laid out. These
      // two flags let the raster cache keep the result instead of replaying
      // every path on each frame a list or page transition touches.
      isComplex: true,
      willChange: false,
      child: SizedBox(
        width: width,
        height: height,
        child: child ??
            (label == null
                ? null
                : Center(
                    child: Text(
                      label!,
                      textAlign: TextAlign.center,
                      style: WgnText.mono(
                        8,
                        color: Colors.white.withValues(alpha: .6),
                        letterSpacing: 0.9,
                        height: 1.4,
                      ),
                    ),
                  )),
      ),
    );
    // An antialiased clip layer is not free, and at radius 0 there is nothing
    // to round off — the painter clips its own bands to the box.
    return RepaintBoundary(
      child: radius == 0
          ? painted
          : ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: painted,
            ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  const _StripesPainter(this.a, this.b);
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    final paintA = Paint()..color = a;
    final paintB = Paint()..color = b;
    // The bands below are drawn as full diagonals and overhang the box on both
    // sides; keep them inside it here rather than paying for a clip layer in
    // the widget tree.
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paintA);
    // 7px stripes at 135°: iterate diagonal bands.
    const band = 7.0;
    final max = size.width + size.height;
    var i = 0;
    for (double d = -size.height; d < max; d += band, i++) {
      if (i.isEven) continue;
      final path = Path()
        ..moveTo(d, 0)
        ..lineTo(d + band, 0)
        ..lineTo(d + band - size.height, size.height)
        ..lineTo(d - size.height, size.height)
        ..close();
      canvas.drawPath(path, paintB);
    }
  }

  @override
  bool shouldRepaint(_StripesPainter old) => old.a != a || old.b != b;
}
