part of '../../../click_connect_ai_crm_ui.dart';

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBadge({super.key, required this.icon, required this.color, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withValues(alpha: .95), color.withValues(alpha: .35)]),
        borderRadius: BorderRadius.circular(size / 3),
        boxShadow: [BoxShadow(color: color.withValues(alpha: .24), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Icon(icon, color: Colors.white, size: size * .52),
    );
  }
}


