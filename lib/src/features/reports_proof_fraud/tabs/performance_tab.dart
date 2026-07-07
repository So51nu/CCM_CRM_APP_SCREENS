part of '../../../../click_connect_ai_crm_ui.dart';

class _PerformanceTab extends StatelessWidget {
  const _PerformanceTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('My Performance Overview'),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: const [
            MetricTile(label: 'Assigned Leads', value: '120', icon: Icons.people_alt_rounded),
            MetricTile(label: 'Calls Completed', value: '86', icon: Icons.call_rounded, color: CcColors.green),
            MetricTile(label: 'Connected Calls', value: '28', icon: Icons.phone_in_talk_rounded),
            MetricTile(label: 'Avg Duration', value: '02:48', icon: Icons.timer_outlined, color: CcColors.amber),
            MetricTile(label: 'Follow-ups Done', value: '12', icon: Icons.event_repeat_rounded, color: CcColors.purple),
            MetricTile(label: 'Meetings Fixed', value: '3', icon: Icons.groups_2_rounded, color: CcColors.orange),
            MetricTile(label: 'Proposals Sent', value: '8', icon: Icons.description_rounded, color: CcColors.amber),
            MetricTile(label: 'Deals Won', value: '5', icon: Icons.emoji_events_rounded, color: CcColors.green),
            MetricTile(label: 'Revenue', value: '₹45,600', icon: Icons.currency_rupee_rounded, color: CcColors.green),
            MetricTile(label: 'Call Quality', value: '4.6/5', icon: Icons.star_half_rounded, color: CcColors.purple),
          ],
        ),
        const SizedBox(height: 12),
        const GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Target Achievement', style: TextStyle(fontWeight: FontWeight.w900)),
          SizedBox(height: 12),
          LinearProgressIndicator(value: .45, color: CcColors.blue500, backgroundColor: CcColors.line, minHeight: 10),
          SizedBox(height: 8),
          Row(children: [Text('45 Completed'), Spacer(), Text('55 Remaining'), Spacer(), Text('45%', style: TextStyle(color: CcColors.blue300, fontWeight: FontWeight.w900))]),
        ])),
        const SizedBox(height: 12),
        const GlassCard(child: Row(children: [Icon(Icons.leaderboard_rounded, color: CcColors.amber, size: 42), SizedBox(width: 12), Expanded(child: Text('Leaderboard Rank #7 • Top 10% of your team', style: TextStyle(fontWeight: FontWeight.w900)))])),
      ]),
    );
  }
}


