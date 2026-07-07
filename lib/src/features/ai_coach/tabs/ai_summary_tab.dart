part of '../../../../click_connect_ai_crm_ui.dart';

class _AiSummaryTab extends StatelessWidget {
  const _AiSummaryTab();

  @override
  Widget build(BuildContext context) {
    final cards = const [
      (Icons.summarize_rounded, CcColors.blue500, 'Short Summary', 'Customer is interested in website development. Asked pricing and wants demo.'),
      (Icons.checklist_rounded, CcColors.purple, 'Customer Requirement', 'AI-powered CRM, calling integration, lead scoring, team dashboard, WhatsApp integration.'),
      (Icons.currency_rupee_rounded, CcColors.amber, 'Budget Mentioned', '₹15,000 – ₹20,000 per month'),
      (Icons.report_problem_outlined, CcColors.red, 'Objection', 'Budget low hai. Need to justify ROI.'),
      (Icons.next_plan_rounded, CcColors.green, 'Next Action', 'Share proposal and ROI case study. Follow up on May 25, 2025.'),
    ];
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GlassCard(child: Row(children: const [CircleAvatar(backgroundColor: CcColors.blue500, child: Text('R')), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Call with Rahul Verma', style: TextStyle(fontWeight: FontWeight.w900)), Text('May 22, 2025 • 10:32 AM • 12m 48s', style: TextStyle(color: CcColors.textMuted))])), CcChip(label: 'Completed', color: CcColors.green, filled: true)])),
      const SizedBox(height: 12),
      ...cards.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [IconBadge(icon: e.$1, color: e.$2, size: 42), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.$3, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(e.$4, style: const TextStyle(color: CcColors.textSoft, height: 1.35))]))])))),
      Row(children: const [Expanded(child: MetricTile(label: 'Lead Quality', value: 'High', icon: Icons.local_fire_department_rounded, color: CcColors.green)), SizedBox(width: 12), Expanded(child: MetricTile(label: 'Closing Chance', value: '70%', icon: Icons.track_changes_rounded, color: CcColors.amber))]),
      const SizedBox(height: 12),
      const GlassCard(child: Row(children: [Icon(Icons.event_repeat_rounded, color: CcColors.blue300), SizedBox(width: 12), Expanded(child: Text('Follow-up Recommendation: Send ROI case study and pricing comparison. Schedule demo for key stakeholders.', style: TextStyle(color: CcColors.textSoft, height: 1.35)))])),
    ]));
  }
}


