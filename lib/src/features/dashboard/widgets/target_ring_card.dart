part of '../../../../click_connect_ai_crm_ui.dart';

class TargetRingCard extends StatelessWidget {
  final String target;
  final String completed;
  const TargetRingCard({super.key, this.target = '100', this.completed = '0'});

  @override
  Widget build(BuildContext context) {
    final targetNum = math.max(1, _int(target, 100));
    final completedNum = math.max(0, _int(completed, 0));
    final progress = (completedNum / targetNum).clamp(0.0, 1.0);
    final percent = (progress * 100).round();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Today Target', style: TextStyle(color: CcColors.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: CustomPaint(
                painter: RingPainter(progress: progress),
                child: SizedBox(width: 82, height: 82, child: Center(child: Text('$percent%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))),
              ),
            ),
          ),
          Center(child: Text('$completedNum / $targetNum', style: const TextStyle(color: CcColors.textSoft, fontWeight: FontWeight.w800))),
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
