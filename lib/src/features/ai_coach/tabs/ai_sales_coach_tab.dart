part of '../../../../click_connect_ai_crm_ui.dart';

class _AiSalesCoachTab extends StatelessWidget {
  const _AiSalesCoachTab();

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.reply_rounded, CcColors.blue500, 'Suggested Reply', 'Sir, hum starter package se begin kar sakte hain. Initially essential website launch karke later SEO/Ads add kar sakte ho.'),
      (Icons.workspace_premium_rounded, CcColors.purple, 'Package Recommendation', 'Pro Plan – ₹17,999/month. Best fit for a team of 8 with calling & automation.'),
      (Icons.handshake_rounded, CcColors.green, 'Closing Script', 'If this solves your challenge and fits your budget, shall we get started this week?'),
      (Icons.event_repeat_rounded, CcColors.amber, 'Follow-up Script', 'Just checking if you had a chance to review the proposal. Happy to help!'),
      (Icons.chat_rounded, CcColors.green, 'WhatsApp Message', 'Hi Rahul, sharing the proposal and ROI case study as discussed. Let me know your thoughts.'),
      (Icons.email_outlined, CcColors.blue500, 'Email Draft', 'Subject: Proposal for Click Connect AI CRM. Please find the attached proposal and ROI case study.'),
    ];
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GlassCard(gradient: LinearGradient(colors: [CcColors.purple.withValues(alpha: .22), CcColors.card]), child: const Row(children: [Icon(Icons.person_rounded, color: CcColors.purple), SizedBox(width: 10), Expanded(child: Text('Customer Objection: “Budget low hai.”', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)))])),
      const SizedBox(height: 12),
      ...items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassCard(child: Row(children: [IconBadge(icon: e.$1, color: e.$2, size: 42), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.$3, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 5), Text(e.$4, style: const TextStyle(color: CcColors.textSoft, height: 1.35))])), const Icon(Icons.chevron_right_rounded, color: CcColors.textMuted)])))),
    ]));
  }
}


