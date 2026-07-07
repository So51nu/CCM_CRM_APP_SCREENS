part of '../../../../click_connect_ai_crm_ui.dart';

class _WhatsAppAutomationTab extends StatelessWidget {
  const _WhatsAppAutomationTab();

  @override
  Widget build(BuildContext context) {
    final actions = const [
      (Icons.chat_rounded, CcColors.green, 'Send Thank-you Message', 'Personalized thank-you message'),
      (Icons.business_rounded, CcColors.red, 'Send Company Profile', 'Share company profile document'),
      (Icons.description_rounded, CcColors.blue500, 'Send Brochure', 'Share product/service brochure'),
      (Icons.event_repeat_rounded, CcColors.amber, 'Create Follow-up', 'Schedule a follow-up task'),
      (Icons.notifications_active_rounded, CcColors.red, 'Notify Manager', 'Alert manager about the update'),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            gradient: LinearGradient(colors: [CcColors.green.withValues(alpha: .22), CcColors.card]),
            child: const Row(
              children: [
                Icon(Icons.chat_rounded, color: CcColors.green, size: 34),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Automate conversations. Nurture leads. Save time.',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const SectionTitle('When Lead Status Changes'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              CcChip(label: 'Interested', color: CcColors.green, filled: true),
              CcChip(label: 'Meeting Fixed', color: CcColors.amber, filled: true),
              CcChip(label: 'Proposal Sent', color: CcColors.purple, filled: true),
            ],
          ),
          const SectionTitle('Perform These Actions'),
          ...actions.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: SwitchListTile(
                  value: true,
                  onChanged: (_) {},
                  contentPadding: EdgeInsets.zero,
                  secondary: IconBadge(icon: item.$1, color: item.$2, size: 42),
                  title: Text(item.$3, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(item.$4, style: const TextStyle(color: CcColors.textMuted)),
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          const GlassCard(
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: CcColors.green),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Automation is Active • Last triggered: Today, 09:30 AM',
                    style: TextStyle(color: CcColors.textSoft),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
