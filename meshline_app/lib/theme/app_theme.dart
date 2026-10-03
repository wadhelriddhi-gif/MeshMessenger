import 'package:flutter/material.dart';

class AppColors {
  static const bgTop = Color(0xFFEAFBF4);
  static const bgMid = Color(0xFFBFE3EF);
  static const bgBottom = Color(0xFF4E7096);
  static const brand = Color(0xFF3145CB);
  static const primary = Color(0xFF2A3FC4);
  static const textDark = Color(0xFF14171F);
  static const textGrey = Color(0xFF8B93A1);
  static const card = Color(0xFFF2F4F8);
  static const online = Color(0xFF22C55E);
  static const offline = Color(0xFF9AA5B1);
  static const danger = Color(0xFFDC2626);
}

class AppTextStyles {
  static const wordmark = TextStyle(
      color: AppColors.brand, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.2);
  static const heading = TextStyle(
      color: AppColors.textDark, fontSize: 26, fontWeight: FontWeight.w800);
  static const subheading = TextStyle(color: AppColors.textGrey, fontSize: 13);
}

// Wraps every screen's body in the mint-to-blue gradient background.
class AppGradient extends StatelessWidget {
  final Widget child;
  const AppGradient({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}

// The "MESHLINE" wordmark shown at the top-left of every screen.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Align(alignment: Alignment.centerLeft, child: Text('MESHLINE', style: AppTextStyles.wordmark)),
    );
  }
}

// Draws the triangle-of-connected-nodes logo entirely in code (no image file needed).
class MeshLogo extends StatelessWidget {
  final double size;
  const MeshLogo({super.key, this.size = 72});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _MeshLogoPainter()));
  }
}

class _MeshLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final top = Offset(size.width / 2, size.height * 0.12);
    final left = Offset(size.width * 0.22, size.height * 0.78);
    final right = Offset(size.width * 0.78, size.height * 0.78);

    final linePaint = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF3B5BFF), Color(0xFF7A5CFF)])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = size.width * 0.06
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(top, left, linePaint);
    canvas.drawLine(top, right, linePaint);
    canvas.drawLine(left, right, linePaint);

    final nodePaint = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6D5BFF)])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final r = size.width * 0.12;
    canvas.drawCircle(top, r, nodePaint);
    canvas.drawCircle(left, r * 0.85, nodePaint);
    canvas.drawCircle(right, r * 0.85, nodePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

InputDecoration meshInputDecoration(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: AppColors.textGrey),
  filled: true,
  fillColor: AppColors.card,
  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
);

ButtonStyle meshPrimaryButton() => ElevatedButton.styleFrom(
  backgroundColor: AppColors.primary,
  foregroundColor: Colors.white,
  minimumSize: const Size(double.infinity, 54),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
);