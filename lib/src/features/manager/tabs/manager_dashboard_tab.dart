part of '../../../../click_connect_ai_crm_ui.dart';

class _ManagerDashboardTab extends StatelessWidget {
  const _ManagerDashboardTab();

  @override
  Widget build(BuildContext context) {
    final metrics = const [
      ('Team Calls Today', '320', Icons.call_rounded, CcColors.blue500),
      ('Connected Calls', '182', Icons.phone_in_talk_rounded, CcColors.green),
      ('Pending Calls', '86', Icons.call_missed_rounded, CcColors.amber),
      ('Follow-up Overdue', '24', Icons.event_busy_rounded, CcColors.red),
      ('Hot Leads', '56', Icons.local_fire_department_rounded, CcColors.red),
      ('Meeting Fixed', '19', Icons.groups_2_rounded, CcColors.purple),
      ('Deals Won', '11', Icons.emoji_events_rounded, CcColors.green),
      ('Revenue', '₹8.45L', Icons.currency_rupee_rounded, CcColors.green),
    ];
    final callers = const [
      ('Arjun Sharma', '32', '24', '8', '75%'),
      ('Priya Singh', '28', '19', '9', '68%'),
      ('Rohan Mehta', '26', '16', '10', '62%'),
      ('Neha Verma', '22', '14', '8', '64%'),
    ];
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GlassCard(child: Row(children: const [CircleAvatar(backgroundColor: CcColors.blue500, child: Text('M')), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Good morning, Manager 👋', style: TextStyle(fontWeight: FontWeight.w900)), CcChip(label: 'Approved Device', color: CcColors.green, icon: Icons.verified_rounded, filled: true)]))])),
      const SectionTitle('Team Overview'),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: metrics.map((e) => MetricTile(label: e.$1, value: e.$2, icon: e.$3, color: e.$4)).toList(),
      ),
      const SectionTitle('Telecaller Performance'),
      GlassCard(child: Column(children: callers.map((c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [CircleAvatar(backgroundColor: CcColors.blue500, child: Text(c.$1[0])), const SizedBox(width: 10), Expanded(child: Text(c.$1, style: const TextStyle(fontWeight: FontWeight.w900))), _managerMini('Calls', c.$2), _managerMini('Connected', c.$3), _managerMini('Pending', c.$4), Text(c.$5, style: const TextStyle(color: CcColors.green, fontWeight: FontWeight.w900))]),
      )).toList())),
    ]));
  }

  Widget _managerMini(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: CcColors.textMuted, fontSize: 10))]),
  );
}


