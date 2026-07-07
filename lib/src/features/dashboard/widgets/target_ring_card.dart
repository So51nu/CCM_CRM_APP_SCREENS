part of '../../../../click_connect_ai_crm_ui.dart';

class TargetRingCard extends StatelessWidget {
  const TargetRingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today Target', style: TextStyle(color: CcColors.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: CustomPaint(
                painter: RingPainter(progress: .45),
                child: const SizedBox(width: 82, height: 82, child: Center(child: Text('45%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))),
              ),
            ),
          ),
          const Center(child: Text('45 / 100', style: TextStyle(color: CcColors.textSoft, fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class RingPainter extends CustomPainter {
  final double progress;
  const RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 10.0;
    final rect = Offset.zero & size;
    final bg = Paint()..color = CcColors.cardLight..strokeWidth = stroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final fg = Paint()..shader = const LinearGradient(colors: [CcColors.blue500, CcColors.cyan400]).createShader(rect)..strokeWidth = stroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(rect.deflate(stroke / 2), -math.pi / 2, math.pi * 2, false, bg);
    canvas.drawArc(rect.deflate(stroke / 2), -math.pi / 2, math.pi * 2 * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) => oldDelegate.progress != progress;
}


