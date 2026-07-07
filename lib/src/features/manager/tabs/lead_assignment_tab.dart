part of '../../../../click_connect_ai_crm_ui.dart';

class _LeadAssignmentTab extends StatelessWidget {
  const _LeadAssignmentTab();

  @override
  Widget build(BuildContext context) {
    final workload = const [
      ('Arjun Sharma', '32 / 40', .80, 'High', CcColors.red),
      ('Priya Singh', '24 / 40', .60, 'Medium', CcColors.amber),
      ('Rohan Mehta', '18 / 40', .45, 'Low', CcColors.blue500),
      ('Neha Verma', '14 / 40', .35, 'Low', CcColors.blue500),
      ('Vikram Patel', '10 / 40', .25, 'Low', CcColors.blue500),
    ];
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: const [Expanded(child: MetricTile(label: 'Unassigned Leads', value: '120', icon: Icons.group_add_rounded)), SizedBox(width: 10), Expanded(child: MetricTile(label: 'Avg Leads/Telecaller', value: '18', icon: Icons.balance_rounded, color: CcColors.amber))]),
      const SectionTitle('Telecaller Workload'),
      GlassCard(child: Column(children: workload.map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [Expanded(flex: 2, child: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w800))), Expanded(flex: 2, child: LinearProgressIndicator(value: e.$3, color: e.$5, backgroundColor: CcColors.line, minHeight: 8)), const SizedBox(width: 8), Text(e.$2, style: const TextStyle(color: CcColors.textSoft)), const SizedBox(width: 8), CcChip(label: e.$4, color: e.$5, filled: true)]),
      )).toList())),
      const SectionTitle('Assign Leads'),
      const TextField(decoration: InputDecoration(labelText: 'Assign To', hintText: 'Select Telecaller', prefixIcon: Icon(Icons.person_add_alt_rounded))),
      const SizedBox(height: 12),
      const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Notes', hintText: 'Add a note...')),
      const SizedBox(height: 14),
      PrimaryButton(label: 'Assign Leads', icon: Icons.send_rounded, onPressed: () {}),
      const SectionTitle('Team Availability'),
      const GlassCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_MiniStat('High Load', '2', CcColors.red), _MiniStat('Medium Load', '1', CcColors.amber), _MiniStat('Available', '3', CcColors.green)])),
    ]));
  }
}


