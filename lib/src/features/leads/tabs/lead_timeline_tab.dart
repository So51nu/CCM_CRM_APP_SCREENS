part of '../../../../click_connect_ai_crm_ui.dart';

class _LeadTimeline extends StatelessWidget {
  const _LeadTimeline();

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('10:20 AM', Icons.call_rounded, CcColors.blue500, 'Outgoing Call', 'Connected • Duration 06:24\nDiscussed CRM requirements and pricing.'),
      ('10:35 AM', Icons.note_rounded, CcColors.purple, 'Note Added', 'Interested in automation & reports.'),
      ('11:00 AM', Icons.event_repeat_rounded, CcColors.amber, 'Follow-up Scheduled', 'Reminder set for today 11:00 AM.'),
      ('04:15 PM', Icons.chat_rounded, CcColors.green, 'WhatsApp', 'Delivered product brochure and case study.'),
      ('02:40 PM', Icons.groups_rounded, CcColors.purple, 'Meeting', 'Completed demo meeting with team.'),
      ('11:30 AM', Icons.picture_as_pdf_rounded, CcColors.red, 'Proposal Shared', 'CRM Pro Plan Proposal.pdf opened.'),
      ('03:20 PM', Icons.receipt_long_rounded, CcColors.blue500, 'Invoice Sent', 'INV-000256 • ₹24,999 • Paid'),
    ];
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: const [CcChip(label: 'All', filled: true), CcChip(label: 'Calls'), CcChip(label: 'Notes'), CcChip(label: 'Follow-ups'), CcChip(label: 'Meetings'), CcChip(label: 'WhatsApp'), CcChip(label: 'Proposals'), CcChip(label: 'Invoices')]),
        const SizedBox(height: 12),
        GlassCard(child: Column(children: items.map((e) => TimelineItem(time: e.$1, icon: e.$2, color: e.$3, title: e.$4, body: e.$5)).toList())),
      ]),
    );
  }
}


