part of '../../../../click_connect_ai_crm_ui.dart';

class _OfflineSyncTab extends StatelessWidget {
  const _OfflineSyncTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GlassCard(gradient: LinearGradient(colors: [CcColors.blue600.withValues(alpha: .22), CcColors.card]), child: const Row(children: [Icon(Icons.cloud_off_rounded, color: CcColors.blue300, size: 38), SizedBox(width: 12), Expanded(child: Text('You are in Offline Mode. Data will sync automatically when you are back online.', style: TextStyle(color: CcColors.textSoft, height: 1.35)))])),
      const SectionTitle('Offline Summary'),
      GridView.count(physics: const NeverScrollableScrollPhysics(), shrinkWrap: true, crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4, children: const [
        MetricTile(label: 'Cached Leads', value: '42', icon: Icons.people_alt_rounded),
        MetricTile(label: 'Saved Notes', value: '18', icon: Icons.note_alt_rounded, color: CcColors.amber),
        MetricTile(label: 'Pending Sync', value: '16', icon: Icons.sync_rounded, color: CcColors.amber),
        MetricTile(label: 'Failed Sync', value: '3', icon: Icons.error_outline_rounded, color: CcColors.red),
      ]),
      const SizedBox(height: 12),
      const GlassCard(child: Column(children: [
        KeyValueRow('Last Synced', 'May 15, 2025 09:30 AM', icon: Icons.cloud_done_rounded, valueColor: CcColors.green),
        KeyValueRow('Network Recovery', 'Online – Ready to sync', icon: Icons.wifi_rounded, valueColor: CcColors.blue300),
        KeyValueRow('Duplicate Sync Prevention', 'Enabled', icon: Icons.security_rounded, valueColor: CcColors.purple),
      ])),
      const SectionTitle('Pending Items'),
      const GlassCard(child: Column(children: [
        KeyValueRow('Leads', '12 items pending', icon: Icons.people_alt_outlined, valueColor: CcColors.amber),
        KeyValueRow('Notes', '4 items pending', icon: Icons.note_outlined, valueColor: CcColors.amber),
        KeyValueRow('Follow-ups', '0 items pending', icon: Icons.event_repeat_rounded, valueColor: CcColors.green),
      ])),
      const SizedBox(height: 14),
      PrimaryButton(label: 'Sync Now', icon: Icons.sync_rounded, onPressed: () {}),
    ]));
  }
}


