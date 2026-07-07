part of '../../../../click_connect_ai_crm_ui.dart';

class _TranscriptTab extends StatelessWidget {
  const _TranscriptTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Call with Rahul Verma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        SizedBox(height: 4),
        Text('May 22, 2025 • 10:32 AM • 12m 48s', style: TextStyle(color: CcColors.textMuted)),
        SizedBox(height: 14),
        Row(children: [Icon(Icons.play_circle_fill_rounded, color: CcColors.blue500, size: 38), SizedBox(width: 10), Expanded(child: LinearProgressIndicator(value: .35, color: CcColors.blue500, backgroundColor: CcColors.line)), SizedBox(width: 10), Text('12:48', style: TextStyle(color: CcColors.textMuted))]),
      ])),
      const SizedBox(height: 12),
      const TranscriptBubble(speaker: 'Arjun (You)', time: '00:15', text: 'Hi Rahul, this is Arjun from Click Connect. How are you doing today?'),
      const TranscriptBubble(speaker: 'Rahul Verma', time: '00:28', text: 'Hi Arjun, I am good. Tell me more about your CRM.'),
      const TranscriptBubble(speaker: 'Arjun (You)', time: '00:42', text: 'It is an AI-powered CRM with calling, automation, lead scoring and detailed reports.'),
      const TranscriptBubble(speaker: 'Rahul Verma', time: '01:05', text: 'Sounds good, but budget low hai.'),
      const SectionTitle('AI Insights'),
      Row(children: const [Expanded(child: MetricTile(label: 'Lead Score', value: '85/100', icon: Icons.bolt_rounded, color: CcColors.green)), SizedBox(width: 12), Expanded(child: MetricTile(label: 'Package', value: 'Pro Plan', icon: Icons.star_rounded, color: CcColors.amber))]),
      const SizedBox(height: 12),
      const GlassCard(child: Column(children: [
        KeyValueRow('Key Interest', 'AI CRM, Calling, Automation, Reports'),
        KeyValueRow('Top Objection', 'Budget low hai', valueColor: CcColors.amber),
        KeyValueRow('Next Best Action', 'Send proposal & ROI case study. Schedule demo.', valueColor: CcColors.green),
      ])),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: PrimaryButton(label: 'Send Proposal', icon: Icons.picture_as_pdf_rounded, onPressed: () {})), const SizedBox(width: 10), Expanded(child: PrimaryButton(label: 'WhatsApp', icon: Icons.chat_rounded, color: CcColors.green, onPressed: () {}))]),
    ]));
  }
}


