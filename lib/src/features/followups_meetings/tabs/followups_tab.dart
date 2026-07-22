part of '../../../../click_connect_ai_crm_ui.dart';

class _FollowupsTab extends StatefulWidget {
  const _FollowupsTab();

  @override
  State<_FollowupsTab> createState() => _FollowupsTabState();
}

class _FollowupsTabState extends State<_FollowupsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => CrmScope.of(context).refreshFollowups());
  }

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    final live = app.followups;
    final followups = live.isNotEmpty
        ? live
        : const [
            {'title': 'Call back', 'lead_name': 'Rohit Sharma', 'company': 'TechNova Solutions', 'scheduled_at': '10:00 AM', 'status': 'Due Today'},
            {'title': 'Proposal follow-up', 'lead_name': 'Amit Verma', 'company': 'Verma Enterprises', 'scheduled_at': '02:00 PM', 'status': 'Overdue'},
          ];

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) => RefreshIndicator(
        onRefresh: app.refreshFollowups,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (app.apiLoading) const LinearProgressIndicator(minHeight: 2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const CcChip(label: 'Today', filled: true),
                  CcChip(label: 'Overdue ${followups.where((e) => _text(_asMap(e)['status']).toLowerCase().contains('overdue')).length}', color: CcColors.red),
                  CcChip(label: 'Upcoming ${followups.length}'),
                  const CcChip(label: 'Completed'),
                ],
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    return Column(
                      children: [
                        Text(['S', 'M', 'T', 'W', 'T', 'F', 'S'][index], style: const TextStyle(color: CcColors.textMuted)),
                        const SizedBox(height: 6),
                        CircleAvatar(radius: 16, backgroundColor: index == 3 ? CcColors.blue500 : Colors.transparent, child: Text('${11 + index}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              if (live.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: GlassCard(child: Text('Live followups API connected. Backend response empty hone par sample rows show honge.', style: TextStyle(color: CcColors.textMuted))),
                ),
              ...followups.map((raw) {
                final item = _asMap(raw);
                final status = _text(item['status'] ?? item['followup_status'], 'Pending');
                final color = status.toLowerCase().contains('overdue') ? CcColors.red : status.toLowerCase().contains('completed') ? CcColors.green : CcColors.blue500;
                final leadName = _text(item['lead_name'] ?? item['name'] ?? item['customer_name'], 'Lead');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: Row(
                      children: [
                        CircleAvatar(backgroundColor: color, child: Text(_initial(leadName))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(leadName, style: const TextStyle(fontWeight: FontWeight.w900)),
                            Text(_text(item['company'] ?? item['title'] ?? item['notes'], '-'), style: const TextStyle(color: CcColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 6),
                            CcChip(label: status, color: color, filled: true),
                          ]),
                        ),
                        Text(_prettyDate(item['scheduled_at'] ?? item['date'] ?? item['time']), style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                        const SizedBox(width: 8),
                        const Icon(Icons.call_rounded, color: CcColors.blue300),
                        const SizedBox(width: 8),
                        const Icon(Icons.notifications_none_rounded, color: CcColors.textMuted),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat('Total', '${followups.length}'),
                    _MiniStat('Completed', '${followups.where((e) => _text(_asMap(e)['status']).toLowerCase().contains('completed')).length}', CcColors.green),
                    _MiniStat('Overdue', '${followups.where((e) => _text(_asMap(e)['status']).toLowerCase().contains('overdue')).length}', CcColors.red),
                    _MiniStat('Due Today', '${followups.length}', CcColors.blue500),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
