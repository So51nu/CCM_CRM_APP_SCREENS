part of '../../../../click_connect_ai_crm_ui.dart';

class _ProfileSettingsTab extends StatelessWidget {
  const _ProfileSettingsTab();

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) => SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GlassCard(child: Row(children: [CircleAvatar(radius: 28, backgroundColor: CcColors.blue500, child: Text(_initial(app.userName))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(app.userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(app.role, style: const TextStyle(color: CcColors.textMuted)), Text(app.userEmail, style: const TextStyle(color: CcColors.textMuted, fontSize: 12))])), const Icon(Icons.chevron_right_rounded)])),
        const SectionTitle('Preferences'),
        GlassCard(child: Column(children: [
          const KeyValueRow('Notification Preferences', 'Manage notifications', icon: Icons.notifications_none_rounded),
          const KeyValueRow('Call Permission', 'Native permission check on login', icon: Icons.call_rounded, valueColor: CcColors.green),
          KeyValueRow('Recording Permission', app.autoRecordingEnabled ? 'Allowed / Enabled' : 'Disabled', icon: Icons.fiber_manual_record_rounded, valueColor: app.autoRecordingEnabled ? CcColors.green : CcColors.amber),
          KeyValueRow('Sync Status', app.statusMessage, icon: Icons.cloud_done_rounded, valueColor: CcColors.green),
        ])),
        const SectionTitle('App & Device'),
        GlassCard(child: Column(children: [
          const KeyValueRow('App Version', 'Flutter APK', icon: Icons.info_outline_rounded),
          KeyValueRow('Device Binding', app.deviceId, icon: Icons.phone_android_rounded, valueColor: CcColors.green),
          SwitchListTile(value: true, onChanged: (_) {}, contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.fingerprint_rounded, color: CcColors.blue300), title: const Text('Biometric Login', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('UI ready: connect local auth package if needed', style: TextStyle(color: CcColors.textMuted))),
        ])),
        const SizedBox(height: 14),
        OutlinedButton.icon(onPressed: app.loading ? null : app.logout, icon: const Icon(Icons.logout_rounded, color: CcColors.red), label: const Text('Logout', style: TextStyle(color: CcColors.red)), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), side: const BorderSide(color: CcColors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)))),
      ])),
    );
  }
}
