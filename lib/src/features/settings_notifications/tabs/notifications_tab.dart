part of '../../../../click_connect_ai_crm_ui.dart';

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.person_add_alt_rounded, CcColors.blue500, 'New Lead Assigned', 'Rahul Mehta has been assigned to you.', '10:30 AM'),
      (Icons.event_repeat_rounded, CcColors.amber, 'Follow-up Due', 'You have 12 follow-ups due today.', '09:15 AM'),
      (Icons.event_available_rounded, CcColors.purple, 'Meeting Reminder', 'Product Demo with Acme Corp at 11:00 AM.', 'Yesterday'),
      (Icons.chat_rounded, CcColors.green, 'Manager Message', 'Great progress this week! Keep it up. 👏', 'Yesterday'),
      (Icons.description_rounded, CcColors.red, 'Proposal Follow-up', 'Follow up with Globex Corp proposal.', 'May 14'),
      (Icons.currency_rupee_rounded, CcColors.green, 'Payment Reminder', 'Payment of ₹45,000 is due from TechNova.', 'May 14'),
      (Icons.warning_amber_rounded, CcColors.red, 'Overdue Follow-up', '5 follow-ups are overdue.', 'May 13'),
      (Icons.track_changes_rounded, CcColors.orange, 'Target Pending Alert', 'You are behind on your monthly target by 15%.', 'May 13'),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              CcChip(label: 'All', filled: true),
              CcChip(label: 'Unread 8'),
              CcChip(label: 'Important'),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Row(
                  children: [
                    IconBadge(icon: item.$1, color: item.$2, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$3, style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text(item.$4, style: const TextStyle(color: CcColors.textMuted, height: 1.35)),
                        ],
                      ),
                    ),
                    Text(item.$5, style: const TextStyle(color: CcColors.textMuted, fontSize: 12)),
                    const SizedBox(width: 6),
                    const CircleAvatar(radius: 4, backgroundColor: CcColors.blue500),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
