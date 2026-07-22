part of '../../../../click_connect_ai_crm_ui.dart';

class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => CrmScope.of(context).refreshNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    final fallback = const [
      {'type': 'lead', 'title': 'New Lead Assigned', 'message': 'Assigned leads API/notifications connected.', 'created_at': 'Now'},
      {'type': 'followup', 'title': 'Follow-up Due', 'message': 'Followups will appear from CRM API.', 'created_at': 'Today'},
    ];
    final items = app.notifications.isNotEmpty ? app.notifications : fallback;

    return AnimatedBuilder(
      animation: app,
      builder: (context, _) => RefreshIndicator(
        onRefresh: app.refreshNotifications,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: [
                const CcChip(label: 'All', filled: true),
                CcChip(label: 'Unread ${items.length}'),
                const CcChip(label: 'Important'),
              ]),
              const SizedBox(height: 12),
              ...items.map((raw) {
                final item = _asMap(raw);
                final type = _text(item['type'] ?? item['category'], 'info').toLowerCase();
                final icon = type.contains('lead') ? Icons.person_add_alt_rounded : type.contains('follow') ? Icons.event_repeat_rounded : type.contains('meeting') ? Icons.event_available_rounded : type.contains('payment') ? Icons.currency_rupee_rounded : Icons.notifications_rounded;
                final color = type.contains('lead') ? CcColors.blue500 : type.contains('follow') ? CcColors.amber : type.contains('meeting') ? CcColors.purple : type.contains('payment') ? CcColors.green : CcColors.orange;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: Row(
                      children: [
                        IconBadge(icon: icon, color: color, size: 42),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_text(item['title'] ?? item['subject'], 'Notification'), style: const TextStyle(fontWeight: FontWeight.w900)),
                          Text(_text(item['message'] ?? item['body'] ?? item['description'], '-'), style: const TextStyle(color: CcColors.textMuted, height: 1.35)),
                        ])),
                        Text(_prettyDate(item['created_at'] ?? item['time'] ?? item['date']), style: const TextStyle(color: CcColors.textMuted, fontSize: 12)),
                        const SizedBox(width: 6),
                        const CircleAvatar(radius: 4, backgroundColor: CcColors.blue500),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
