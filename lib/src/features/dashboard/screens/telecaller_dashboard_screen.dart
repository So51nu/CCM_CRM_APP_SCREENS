part of '../../../../click_connect_ai_crm_ui.dart';

class TelecallerDashboardScreen extends StatefulWidget {
  const TelecallerDashboardScreen({super.key});

  @override
  State<TelecallerDashboardScreen> createState() => _TelecallerDashboardScreenState();
}

class _TelecallerDashboardScreenState extends State<TelecallerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => CrmScope.of(context).refreshDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    return BrandedScaffold(
      title: 'Click Connect AI CRM',
      showBack: false,
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () => context.open(const NotificationsOfflineSettingsScreen(initialTab: 0))),
        IconButton(icon: const Icon(Icons.sync_rounded), onPressed: app.fullSync),
      ],
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) {
          final d = app.dashboard;
          final target = _dashboardValue(d, ['today_target', 'target', 'calls_target'], '100');
          final completed = _dashboardValue(d, ['calls_completed', 'completed_calls', 'completed', 'today_completed'], '0');
          final connected = _dashboardValue(d, ['connected_calls', 'connected', 'calls_connected'], '0');
          final followups = _dashboardValue(d, ['followups_due', 'follow_ups_due', 'today_followups', 'followups'], '${app.followups.length}');
          final meetings = _dashboardValue(d, ['meetings_fixed', 'meetings', 'today_meetings'], '0');
          final assigned = _dashboardValue(d, ['today_assigned_leads', 'assigned_leads', 'total_assigned_leads'], '${app.leads.length}');
          final pendingCalls = _dashboardValue(d, ['pending_calls', 'pending_call_requests', 'calls_pending'], '0');
          final hotLeads = _dashboardValue(d, ['hot_leads', 'hot'], '${app.leads.where((e) => e.status == 'Hot').length}');
          final conversion = _dashboardValue(d, ['conversion_percent', 'conversion', 'conversion_rate'], '0%');
          final userInitial = _initial(app.userName);

          return RefreshIndicator(
            onRefresh: app.refreshAll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (app.apiLoading) const LinearProgressIndicator(minHeight: 2),
                GlassCard(
                  gradient: const LinearGradient(colors: [CcColors.navy800, CcColors.card]),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 28, backgroundColor: CcColors.blue500, child: Text(userInitial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Good morning, ${app.userName}! 👋', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            CcChip(label: app.role, icon: Icons.headset_mic_rounded, filled: true),
                            const CcChip(label: 'Approved Device', color: CcColors.green, icon: Icons.verified_rounded, filled: true),
                          ]),
                        ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.18,
                  children: [
                    TargetRingCard(target: target, completed: completed),
                    MetricTile(label: 'Completed', value: completed, icon: Icons.check_circle_outline_rounded, color: CcColors.green, sub: 'API synced'),
                    MetricTile(label: 'Connected', value: connected, icon: Icons.call_rounded, color: CcColors.blue500, sub: 'Verified calls'),
                    MetricTile(label: 'Follow-ups', value: followups, icon: Icons.event_repeat_rounded, color: CcColors.amber, sub: 'Due today'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: MetricTile(label: 'Meetings', value: meetings, icon: Icons.groups_2_rounded, color: CcColors.purple)),
                  const SizedBox(width: 12),
                  Expanded(child: MetricTile(label: 'Conversion %', value: conversion, icon: Icons.trending_up_rounded, color: CcColors.green, sub: 'Live CRM')),
                ]),
                const SectionTitle('Today Work Summary'),
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.75,
                  children: [
                    WorkSummaryCard(title: 'Today Assigned Leads', value: assigned, icon: Icons.people_alt_rounded, color: CcColors.blue500, onTap: () => context.open(const LeadsScreen())),
                    WorkSummaryCard(title: 'Pending Calls', value: pendingCalls, icon: Icons.phone_callback_rounded, color: CcColors.orange, onTap: () => context.open(const CallingServiceScreen())),
                    WorkSummaryCard(title: 'Hot Leads', value: hotLeads, icon: Icons.local_fire_department_rounded, color: CcColors.red, onTap: () => context.open(const LeadsScreen(filter: 'Hot'))),
                    WorkSummaryCard(title: 'Meetings Fixed', value: meetings, icon: Icons.event_available_rounded, color: CcColors.purple, onTap: () => context.open(const FollowupsMeetingsScreen(initialTab: 1))),
                  ],
                ),
                const SectionTitle('Disposition Summary'),
                GlassCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      CcChip(label: 'Ringing ${_dashboardValue(d, ['ringing_calls', 'ringing'], '0')}', icon: Icons.phone_in_talk_rounded, color: CcColors.blue500, filled: true),
                      CcChip(label: 'Not Picked ${_dashboardValue(d, ['not_picked', 'not_picked_calls'], '0')}', icon: Icons.call_missed_rounded, color: CcColors.orange, filled: true),
                      CcChip(label: 'Busy ${_dashboardValue(d, ['busy_calls', 'busy'], '0')}', icon: Icons.phone_disabled_rounded, color: CcColors.purple, filled: true),
                      CcChip(label: 'Switched Off ${_dashboardValue(d, ['switched_off', 'switched_off_calls'], '0')}', icon: Icons.power_settings_new_rounded, color: CcColors.red, filled: true),
                      CcChip(label: 'Wrong Number ${_dashboardValue(d, ['wrong_number', 'wrong_numbers'], '0')}', icon: Icons.help_outline_rounded, color: CcColors.textMuted, filled: true),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GlassCard(
                  gradient: LinearGradient(colors: [CcColors.purple.withValues(alpha: .32), CcColors.blue600.withValues(alpha: .24)]),
                  child: Row(
                    children: [
                      const IconBadge(icon: Icons.auto_awesome_rounded, color: CcColors.purple),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('AI Performance Tip', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 5),
                        Text(_dashboardValue(d, ['ai_tip', 'performance_tip'], 'Use the Calling tab to keep service active and sync verified calls.'), style: const TextStyle(color: CcColors.textSoft, height: 1.35)),
                      ])),
                      IconButton(icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18), onPressed: () => context.open(const ReportsProofFraudScreen())),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
