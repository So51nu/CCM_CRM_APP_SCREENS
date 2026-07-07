part of '../../../click_connect_ai_crm_ui.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.gradient,
    this.onTap,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? CcColors.card.withValues(alpha: .86),
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: CcColors.line.withValues(alpha: .8)),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 10))],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: box);
  }
}


