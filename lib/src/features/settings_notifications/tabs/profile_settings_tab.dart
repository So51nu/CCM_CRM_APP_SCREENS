part of '../../../../click_connect_ai_crm_ui.dart';

class _ProfileSettingsTab extends StatelessWidget {
  const _ProfileSettingsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GlassCard(child: Row(children: const [CircleAvatar(radius: 28, backgroundColor: CcColors.blue500, child: Text('A')), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Arjun Sharma', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text('Sales Manager', style: TextStyle(color: CcColors.textMuted)), Text('arjun.sharma@clickconnect.com', style: TextStyle(color: CcColors.textMuted, fontSize: 12))])), Icon(Icons.chevron_right_rounded)])),
      const SectionTitle('Preferences'),
      const GlassCard(child: Column(children: [
        KeyValueRow('Notification Preferences', 'Manage notifications', icon: Icons.notifications_none_rounded),
        KeyValueRow('Call Permission', 'Allowed', icon: Icons.call_rounded, valueColor: CcColors.green),
        KeyValueRow('Recording Permission', 'Allowed', icon: Icons.fiber_manual_record_rounded, valueColor: CcColors.green),
        KeyValueRow('Sync Status', 'All data synced', icon: Icons.cloud_done_rounded, valueColor: CcColors.green),
      ])),
      const SectionTitle('App & Device'),
      GlassCard(child: Column(children: [
        const KeyValueRow('App Version', '2.4.1 (Build 245)', icon: Icons.info_outline_rounded),
        const KeyValueRow('Device Binding', 'This device is bound', icon: Icons.phone_android_rounded, valueColor: CcColors.green),
        SwitchListTile(value: true, onChanged: (_) {}, contentPadding: EdgeInsets.zero, secondary: const Icon(Icons.fingerprint_rounded, color: CcColors.blue300), title: const Text('Biometric Login', style: TextStyle(fontWeight: FontWeight.w900)), subtitle: const Text('Use fingerprint to login', style: TextStyle(color: CcColors.textMuted))),
      ])),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginSecurityScreen()), (_) => false), icon: const Icon(Icons.logout_rounded, color: CcColors.red), label: const Text('Logout', style: TextStyle(color: CcColors.red)), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), side: const BorderSide(color: CcColors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)))),
    ]));
  }
}


