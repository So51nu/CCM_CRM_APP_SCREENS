part of '../../../click_connect_ai_crm_ui.dart';

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? sub;

  const MetricTile({super.key, required this.label, required this.value, required this.icon, this.color = CcColors.blue500, this.sub});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, size: 38),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: CcColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: CcColors.text)),
          if (sub != null) ...[
            const SizedBox(height: 4),
            Text(sub!, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }
}


