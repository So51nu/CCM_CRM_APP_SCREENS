part of '../../../../click_connect_ai_crm_ui.dart';

class _FraudDetectionTab extends StatelessWidget {
  const _FraudDetectionTab();

  @override
  Widget build(BuildContext context) {
    final alerts = const [
      (Icons.timer_rounded, 'Too Many 5 Sec Calls', 'High number of calls under 5 seconds. Today: 18', CcColors.red, 'High'),
      (Icons.cancel_rounded, 'Too Many Wrong Numbers', 'Abnormally high wrong number ratio. Today: 23%', CcColors.red, 'High'),
      (Icons.edit_calendar_rounded, 'Feedback Edited Late', 'Feedback edited beyond allowed time. Today: 4', CcColors.amber, 'Medium'),
      (Icons.phone_android_rounded, 'Device Changed Frequently', 'Multiple device changes detected. Today: 3', CcColors.amber, 'Medium'),
      (Icons.mic_off_rounded, 'Recording Missing Repeatedly', 'Missing recordings above threshold. Today: 5', CcColors.red, 'High'),
      (Icons.link_off_rounded, 'Mismatch Found', 'Discrepancy in call data & feedback. Today: 2', CcColors.red, 'High'),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Row(
              children: const [
                Icon(Icons.speed_rounded, color: CcColors.red, size: 56),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Risk Score', style: TextStyle(color: CcColors.textMuted)),
                      Text('78', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900)),
                      Text('High Risk', style: TextStyle(color: CcColors.red, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                CcChip(label: 'View Details', color: CcColors.red, filled: true),
              ],
            ),
          ),
          const SectionTitle('Suspicious Alerts'),
          ...alerts.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Row(
                  children: [
                    IconBadge(icon: item.$1, color: item.$4, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text(item.$3, style: const TextStyle(color: CcColors.textMuted, height: 1.35)),
                        ],
                      ),
                    ),
                    CcChip(label: item.$5, color: item.$4, filled: true),
                    const Icon(Icons.chevron_right_rounded, color: CcColors.textMuted),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 10),
          GlassCard(
            gradient: LinearGradient(colors: [CcColors.purple.withValues(alpha: .24), CcColors.card]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Recommendation', style: TextStyle(fontWeight: FontWeight.w900, color: CcColors.purple)),
                const SizedBox(height: 6),
                const Text('High risk activity detected. Please review and take necessary action.', style: TextStyle(color: CcColors.textSoft)),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Review Now', icon: Icons.shield_rounded, color: CcColors.purple, onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
