part of '../../../../click_connect_ai_crm_ui.dart';

class _RemindersTab extends StatelessWidget {
  const _RemindersTab();

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('15 Minutes Before', 'Follow-up with Rohit Sharma', '09:45 AM', CcColors.green),
      ('1 Hour Before', 'Follow-up with Amit Verma', '02:00 PM', CcColors.amber),
      ('Same Day Morning', 'Follow-up with Sneha Iyer', '09:00 AM', CcColors.blue500),
      ('15 Minutes Before', 'Meeting with Rohit Sharma', '10:45 AM', CcColors.green),
      ('1 Hour Before', 'Meeting with Neha Patel', '01:00 PM', CcColors.amber),
      ('Same Day Morning', 'Meeting with Karan Mehta', '08:30 AM', CcColors.blue500),
    ];
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionTitle('Upcoming Reminders'),
      ...items.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassCard(child: Row(children: [IconBadge(icon: Icons.notifications_active_rounded, color: e.$4, size: 42), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w900)), Text(e.$2, style: const TextStyle(color: CcColors.textMuted))])), Text(e.$3, style: TextStyle(color: e.$4, fontWeight: FontWeight.w900))])))),
      const SectionTitle('Alerts'),
      const GlassCard(gradient: LinearGradient(colors: [Color(0x663F121D), CcColors.card]), child: Row(children: [Icon(Icons.warning_amber_rounded, color: CcColors.red), SizedBox(width: 12), Expanded(child: Text('Overdue Follow-up: You have 3 overdue follow-ups. Tap to view and take action.', style: TextStyle(color: CcColors.textSoft))), Icon(Icons.chevron_right_rounded)])),
      const SizedBox(height: 10),
      const GlassCard(child: Row(children: [Icon(Icons.event_busy_rounded, color: CcColors.purple), SizedBox(width: 12), Expanded(child: Text('Pending Confirmations: 2 meetings awaiting customer confirmation.', style: TextStyle(color: CcColors.textSoft))), Icon(Icons.chevron_right_rounded)])),
    ]));
  }
}


