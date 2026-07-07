part of '../../../../click_connect_ai_crm_ui.dart';

class VerifiedCallTrackingScreen extends StatelessWidget {
  final Lead? lead;
  const VerifiedCallTrackingScreen({super.key, this.lead});

  @override
  Widget build(BuildContext context) {
    final activeLead = lead ?? demoLeads.first;
    return BrandedScaffold(
      title: 'Verified Call Tracking',
      actions: [IconButton.filled(icon: const Icon(Icons.call_end_rounded), color: Colors.white, style: IconButton.styleFrom(backgroundColor: CcColors.red), onPressed: () => context.open(AutoFeedbackScreen(lead: activeLead)))],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: CcChip(label: 'Verified Call', color: CcColors.green, icon: Icons.verified_user_rounded, filled: true)),
          const SizedBox(height: 16),
          GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            CircleAvatar(radius: 34, backgroundColor: CcColors.blue500, child: Text(activeLead.name[0], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
            const SizedBox(height: 10),
            Text(activeLead.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            Text(activeLead.mobile, style: const TextStyle(color: CcColors.textMuted)),
            const SizedBox(height: 14),
            const CcChip(label: 'Call in Progress • Live', color: CcColors.green, filled: true),
            const SizedBox(height: 18),
            const Text('02:48', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
            const Text('Call started at 11:32 AM', style: TextStyle(color: CcColors.textMuted)),
          ])),
          const SizedBox(height: 12),
          GlassCard(child: Column(children: const [
            KeyValueRow('Telecaller ID', 'TC-10027 (Arjun)', icon: Icons.person_outline_rounded),
            KeyValueRow('Lead ID', 'LEAD-2025-78245', icon: Icons.badge_outlined),
            KeyValueRow('Mobile Number', '+91 98765 43210', icon: Icons.call_rounded),
            KeyValueRow('Device ID', 'DEV-5G-78245', icon: Icons.phone_android_rounded),
            KeyValueRow('App Version', '2.4.1 (205)', icon: Icons.system_update_alt_rounded),
            KeyValueRow('Network Status', 'Strong (5G)', icon: Icons.signal_cellular_alt_rounded, valueColor: CcColors.green),
            KeyValueRow('Recording Status', 'Recording', icon: Icons.fiber_manual_record_rounded, valueColor: CcColors.red),
            KeyValueRow('Sync Status', 'Synced', icon: Icons.sync_rounded, valueColor: CcColors.green),
            KeyValueRow('Call Via', 'Click Connect AI CRM', icon: Icons.verified_rounded, valueColor: CcColors.blue300),
            KeyValueRow('Call Start Time', '11:32 AM, 16 May 2025', icon: Icons.access_time_rounded),
          ])),
          const SizedBox(height: 12),
          GlassCard(
            gradient: LinearGradient(colors: [CcColors.blue600.withValues(alpha: .22), CcColors.green.withValues(alpha: .12)]),
            child: const Row(children: [Icon(Icons.shield_rounded, color: CcColors.green), SizedBox(width: 10), Expanded(child: Text('This call is being tracked and recorded as per company policy and compliance.', style: TextStyle(color: CcColors.textSoft, height: 1.35)))]),
          ),
          const SizedBox(height: 12),
          PrimaryButton(label: 'End Call & Open Feedback', icon: Icons.assignment_turned_in_rounded, color: CcColors.red, onPressed: () => context.open(AutoFeedbackScreen(lead: activeLead))),
        ],
      ),
    );
  }
}


