part of '../../../../click_connect_ai_crm_ui.dart';

class WorkSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const WorkSummaryCard({super.key, required this.title, required this.value, required this.icon, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 40),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CcColors.textSoft, fontSize: 12, fontWeight: FontWeight.w700)),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: CcColors.textMuted),
        ],
      ),
    );
  }
}


