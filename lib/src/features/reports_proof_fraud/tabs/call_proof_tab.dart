part of '../../../../click_connect_ai_crm_ui.dart';

class _CallProofTab extends StatelessWidget {
  const _CallProofTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 8, children: const [
          CcChip(label: 'Verified Call', color: CcColors.green, icon: Icons.verified_rounded, filled: true),
          CcChip(label: 'Recording Available', icon: Icons.play_circle_outline_rounded, filled: true),
          CcChip(label: 'AI Summary Available', color: CcColors.purple, icon: Icons.auto_awesome_rounded, filled: true),
          CcChip(label: 'Manager Reviewed', color: CcColors.amber, icon: Icons.admin_panel_settings_rounded, filled: true),
        ]),
        const SizedBox(height: 12),
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Text('Call Information', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          SizedBox(height: 10),
          KeyValueRow('Call ID', 'CC-2024-05-24-000987', icon: Icons.tag_rounded),
          KeyValueRow('Lead ID', 'LD-2024-05-24-0456', icon: Icons.badge_outlined),
          KeyValueRow('User ID', 'USR-10234 (Arjun)', icon: Icons.person_outline_rounded),
          KeyValueRow('Device ID', 'AND-8F3A-22B7', icon: Icons.phone_android_rounded, valueColor: CcColors.green),
          KeyValueRow('Start Time', '24 May 2024, 10:15 AM', icon: Icons.play_arrow_rounded),
          KeyValueRow('End Time', '24 May 2024, 10:18 AM', icon: Icons.stop_rounded),
          KeyValueRow('Duration', '02:48 mins', icon: Icons.timer_outlined),
          KeyValueRow('Recording Status', 'Available • Verified', icon: Icons.mic_rounded, valueColor: CcColors.green),
          KeyValueRow('Transcript Status', 'Available • Verified', icon: Icons.article_outlined, valueColor: CcColors.green),
          KeyValueRow('Feedback Status', 'Submitted • Verified', icon: Icons.assignment_turned_in_outlined, valueColor: CcColors.green),
          KeyValueRow('App-Based Verified Status', 'Verified', icon: Icons.verified_user_outlined, valueColor: CcColors.green),
        ])),
        const SizedBox(height: 12),
        GlassCard(gradient: LinearGradient(colors: [CcColors.purple.withValues(alpha: .24), CcColors.card]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AI Summary (Brief)', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Agent connected with prospect, understood pricing and demo requirements. Follow-up scheduled for product demo.', style: TextStyle(color: CcColors.textSoft, height: 1.4)),
          const SizedBox(height: 12),
          PrimaryButton(label: 'View Full Summary', icon: Icons.auto_awesome_rounded, color: CcColors.purple, onPressed: () => context.open(const AiCoachScreen(initialTab: 0))),
        ])),
      ]),
    );
  }
}


