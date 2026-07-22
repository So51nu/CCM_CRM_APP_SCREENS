part of '../../../../click_connect_ai_crm_ui.dart';

class VerifiedCallTrackingScreen extends StatelessWidget {
  final Lead? lead;
  const VerifiedCallTrackingScreen({super.key, this.lead});

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    final activeLead = lead ?? (app.leads.isNotEmpty ? app.leads.first : demoLeads.first);
    return BrandedScaffold(
      title: 'Verified Call Tracking',
      actions: [IconButton.filled(icon: const Icon(Icons.call_end_rounded), color: Colors.white, style: IconButton.styleFrom(backgroundColor: CcColors.red), onPressed: () => context.open(AutoFeedbackScreen(lead: activeLead)))],
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: CcChip(label: app.serviceRunning ? 'Verified Call Service Active' : 'Manual App Call', color: CcColors.green, icon: Icons.verified_user_rounded, filled: true)),
            const SizedBox(height: 16),
            GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              CircleAvatar(radius: 34, backgroundColor: CcColors.blue500, child: Text(_initial(activeLead.name), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
              const SizedBox(height: 10),
              Text(activeLead.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              Text(activeLead.mobile, style: const TextStyle(color: CcColors.textMuted)),
              const SizedBox(height: 14),
              const CcChip(label: 'Call in Progress / Recent Call', color: CcColors.green, filled: true),
              const SizedBox(height: 18),
              const Text('Live', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
              const Text('Native service will update call proof after call end', style: TextStyle(color: CcColors.textMuted)),
            ])),
            const SizedBox(height: 12),
            GlassCard(child: Column(children: [
              KeyValueRow('Telecaller ID', '${app.userId} (${app.userName})', icon: Icons.person_outline_rounded),
              KeyValueRow('Lead ID', '${activeLead.id > 0 ? activeLead.id : '-'}', icon: Icons.badge_outlined),
              KeyValueRow('Mobile Number', activeLead.mobile, icon: Icons.call_rounded),
              KeyValueRow('Device ID', app.deviceId, icon: Icons.phone_android_rounded),
              const KeyValueRow('App Version', 'Flutter APK', icon: Icons.system_update_alt_rounded),
              const KeyValueRow('Network Status', 'Online / API ready', icon: Icons.signal_cellular_alt_rounded, valueColor: CcColors.green),
              KeyValueRow('Recording Status', app.autoRecordingEnabled ? 'Enabled / pending upload' : 'Disabled', icon: Icons.fiber_manual_record_rounded, valueColor: app.autoRecordingEnabled ? CcColors.red : CcColors.amber),
              KeyValueRow('Sync Status', app.statusMessage, icon: Icons.sync_rounded, valueColor: CcColors.green),
              const KeyValueRow('Call Via', 'Click Connect AI CRM', icon: Icons.verified_rounded, valueColor: CcColors.blue300),
              KeyValueRow('CRM URL', app.baseUrl, icon: Icons.language_rounded),
            ])),
            const SizedBox(height: 12),
            GlassCard(
              gradient: LinearGradient(colors: [CcColors.blue600.withValues(alpha: .22), CcColors.green.withValues(alpha: .12)]),
              child: const Row(children: [Icon(Icons.shield_rounded, color: CcColors.green), SizedBox(width: 10), Expanded(child: Text('This app call will be tracked by native call service and submitted to CRM using user token and device ID.', style: TextStyle(color: CcColors.textSoft, height: 1.35)))]),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Open Feedback', icon: Icons.assignment_turned_in_rounded, color: CcColors.red, onPressed: () => context.open(AutoFeedbackScreen(lead: activeLead))),
          ],
        ),
      ),
    );
  }
}
