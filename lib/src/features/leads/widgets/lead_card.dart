part of '../../../../click_connect_ai_crm_ui.dart';

class LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback? onTap;
  const LeadCard({super.key, required this.lead, this.onTap});

  Color get statusColor => lead.status == 'Hot' ? CcColors.red : lead.status == 'Warm' ? CcColors.amber : CcColors.blue500;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 24, backgroundColor: statusColor, child: Text(lead.name.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.w900))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(lead.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), CcChip(label: lead.status, color: statusColor, filled: true)]),
                const SizedBox(height: 3),
                Text(lead.company, style: const TextStyle(color: CcColors.textMuted)),
                const SizedBox(height: 4),
                Text('${lead.mobile}  |  ${lead.alternate}', style: const TextStyle(color: CcColors.textSoft, fontSize: 12)),
              ])),
              IconButton.filledTonal(icon: const Icon(Icons.call_rounded), onPressed: () => context.open(SmartCallingScreen(lead: lead))),
              IconButton.filledTonal(icon: const Icon(Icons.chat_rounded, color: CcColors.green), onPressed: () {}),
            ],
          ),
          const Divider(color: CcColors.line, height: 22),
          Row(children: [
            Expanded(child: _smallInfo('Source', lead.source)),
            Expanded(child: _smallInfo('City', lead.city)),
            Expanded(child: _smallInfo('Interest', lead.interest)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            CcChip(label: 'AI Score ${lead.score}', color: CcColors.green, icon: Icons.bolt_rounded, filled: true),
            const SizedBox(width: 8),
            CcChip(label: 'Priority ${lead.priority}', color: lead.priority == 'High' ? CcColors.red : lead.priority == 'Medium' ? CcColors.amber : CcColors.blue500, filled: true),
            const Spacer(),
            Flexible(child: Text(lead.followUp, textAlign: TextAlign.right, style: const TextStyle(color: CcColors.textSoft, fontWeight: FontWeight.w800, fontSize: 12))),
          ]),
        ],
      ),
    );
  }

  Widget _smallInfo(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: CcColors.textMuted, fontSize: 11)),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
  ]);
}


