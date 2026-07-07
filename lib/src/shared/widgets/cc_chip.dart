part of '../../../click_connect_ai_crm_ui.dart';

class CcChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;
  final IconData? icon;
  final VoidCallback? onTap;

  const CcChip({
    super.key,
    required this.label,
    this.color = CcColors.blue500,
    this.filled = false,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? color.withValues(alpha: .22) : CcColors.cardSoft.withValues(alpha: .68),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: filled ? .9 : .45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(color: filled ? color : CcColors.textSoft, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}


