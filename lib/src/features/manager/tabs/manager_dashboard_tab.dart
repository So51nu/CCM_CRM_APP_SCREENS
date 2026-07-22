part of '../../../../click_connect_ai_crm_ui.dart';

class _ManagerDashboardTab extends StatelessWidget {
  const _ManagerDashboardTab();

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        final d = app.dashboard;
        final metrics = [
          ('Team Calls Today', _dashboardValue(d, ['team_calls_today', 'calls_completed', 'completed_calls'], '0'), Icons.call_rounded, CcColors.blue500),
          ('Connected Calls', _dashboardValue(d, ['team_connected_calls', 'connected_calls', 'connected'], '0'), Icons.phone_in_talk_rounded, CcColors.green),
          ('Pending Calls', _dashboardValue(d, ['pending_calls', 'calls_pending'], '0'), Icons.call_missed_rounded, CcColors.amber),
          ('Follow-up Overdue', _dashboardValue(d, ['followup_overdue', 'overdue_followups'], '0'), Icons.event_busy_rounded, CcColors.red),
          ('Hot Leads', _dashboardValue(d, ['hot_leads', 'hot'], '${app.leads.where((e) => e.status == 'Hot').length}'), Icons.local_fire_department_rounded, CcColors.red),
          ('Meeting Fixed', _dashboardValue(d, ['meetings_fixed', 'meetings'], '0'), Icons.groups_2_rounded, CcColors.purple),
          ('Deals Won', _dashboardValue(d, ['deals_won', 'won'], '0'), Icons.emoji_events_rounded, CcColors.green),
          ('Revenue', _dashboardValue(d, ['revenue', 'revenue_generated'], '0'), Icons.currency_rupee_rounded, CcColors.green),
        ];
        final callers = _firstList(d, ['telecallers', 'team', 'users']);
        return RefreshIndicator(
          onRefresh: app.refreshDashboard,
          child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            GlassCard(child: Row(children: [CircleAvatar(backgroundColor: CcColors.blue500, child: Text(_initial(app.userName))), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Good morning, ${app.userName} 👋', style: const TextStyle(fontWeight: FontWeight.w900)), const CcChip(label: 'Approved Device', color: CcColors.green, icon: Icons.verified_rounded, filled: true)]))])),
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
            GlassCard(child: Column(children: (callers.isNotEmpty ? callers : const [
              {'name': 'Team data', 'calls': '0', 'connected': '0', 'pending': '0', 'conversion': '0%'},
            ]).map((raw) {
              final c = _asMap(raw);
              final name = _text(c['name'] ?? c['user_name'], 'Telecaller');
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(children: [CircleAvatar(backgroundColor: CcColors.blue500, child: Text(_initial(name))), const SizedBox(width: 10), Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w900))), _managerMini('Calls', _text(c['calls'] ?? c['total_calls'], '0')), _managerMini('Connected', _text(c['connected'] ?? c['connected_calls'], '0')), _managerMini('Pending', _text(c['pending'] ?? c['pending_calls'], '0')), Text(_text(c['conversion'] ?? c['conversion_percent'], '0%'), style: const TextStyle(color: CcColors.green, fontWeight: FontWeight.w900))]),
              );
            }).toList())),
          ])),
        );
      },
    );
  }

  Widget _managerMini(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: CcColors.textMuted, fontSize: 10))]),
  );
}
