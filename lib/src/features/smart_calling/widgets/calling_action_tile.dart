part of '../../../../click_connect_ai_crm_ui.dart';

class CallingActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool disabled;
  final VoidCallback? onTap;

  const CallingActionTile({super.key, required this.icon, required this.color, required this.title, required this.subtitle, this.disabled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        onTap: disabled ? null : onTap,
        color: disabled ? CcColors.card.withValues(alpha: .48) : null,
        child: Row(children: [
          IconBadge(icon: icon, color: disabled ? CcColors.textMuted : color, size: 48),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: disabled ? CcColors.textMuted : CcColors.text)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(color: CcColors.textMuted)),
          ])),
          Icon(disabled ? Icons.lock_rounded : Icons.chevron_right_rounded, color: CcColors.textMuted),
        ]),
      ),
    );
  }
}


