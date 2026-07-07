part of '../../../../click_connect_ai_crm_ui.dart';

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(this.label, this.value, [this.color = CcColors.text]);

  @override
  Widget build(BuildContext context) => Column(children: [Text(label, style: const TextStyle(color: CcColors.textMuted, fontSize: 11)), const SizedBox(height: 4), Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900))]);
}


