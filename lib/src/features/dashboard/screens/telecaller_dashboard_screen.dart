part of '../../../../click_connect_ai_crm_ui.dart';

class TelecallerDashboardScreen extends StatelessWidget {
  const TelecallerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      title: 'Click Connect AI CRM',
      showBack: false,
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () => context.open(const NotificationsOfflineSettingsScreen(initialTab: 0))),
        IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            gradient: const LinearGradient(colors: [CcColors.navy800, CcColors.card]),
            child: Row(
              children: [
                const CircleAvatar(radius: 28, backgroundColor: CcColors.blue500, child: Text('A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Good morning, Arjun! 👋', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 8, children: [CcChip(label: 'Telecaller', icon: Icons.headset_mic_rounded, filled: true), CcChip(label: 'Approved Device', color: CcColors.green, icon: Icons.verified_rounded, filled: true)]),
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
            children: const [
              TargetRingCard(),
              MetricTile(label: 'Completed', value: '45', icon: Icons.check_circle_outline_rounded, color: CcColors.green, sub: '+12 today'),
              MetricTile(label: 'Connected', value: '28', icon: Icons.call_rounded, color: CcColors.blue500, sub: '62% connect'),
              MetricTile(label: 'Follow-ups', value: '12', icon: Icons.event_repeat_rounded, color: CcColors.amber, sub: 'Due today'),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: const [
            Expanded(child: MetricTile(label: 'Meetings', value: '3', icon: Icons.groups_2_rounded, color: CcColors.purple)),
            SizedBox(width: 12),
            Expanded(child: MetricTile(label: 'Conversion %', value: '32.5%', icon: Icons.trending_up_rounded, color: CcColors.green, sub: '↑ 8.4%')),
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
              WorkSummaryCard(title: 'Today Assigned Leads', value: '120', icon: Icons.people_alt_rounded, color: CcColors.blue500, onTap: () => context.open(const LeadsScreen())),
              WorkSummaryCard(title: 'Pending Calls', value: '15', icon: Icons.phone_callback_rounded, color: CcColors.orange, onTap: () => context.open(const SmartCallingScreen())),
              WorkSummaryCard(title: 'Hot Leads', value: '18', icon: Icons.local_fire_department_rounded, color: CcColors.red, onTap: () => context.open(const LeadsScreen(filter: 'Hot'))),
              WorkSummaryCard(title: 'Meetings Fixed', value: '3', icon: Icons.event_available_rounded, color: CcColors.purple, onTap: () => context.open(const FollowupsMeetingsScreen(initialTab: 1))),
            ],
          ),
          const SectionTitle('Disposition Summary'),
          GlassCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                CcChip(label: 'Ringing 22', icon: Icons.phone_in_talk_rounded, color: CcColors.blue500, filled: true),
                CcChip(label: 'Not Picked 18', icon: Icons.call_missed_rounded, color: CcColors.orange, filled: true),
                CcChip(label: 'Busy 9', icon: Icons.phone_disabled_rounded, color: CcColors.purple, filled: true),
                CcChip(label: 'Switched Off 6', icon: Icons.power_settings_new_rounded, color: CcColors.red, filled: true),
                CcChip(label: 'Wrong Number 4', icon: Icons.help_outline_rounded, color: CcColors.textMuted, filled: true),
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
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('AI Performance Tip', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  SizedBox(height: 5),
                  Text('You connect 23% more calls between 11 AM – 1 PM. Focus this time window.', style: TextStyle(color: CcColors.textSoft, height: 1.35)),
                ])),
                IconButton(icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18), onPressed: () => context.open(const ReportsProofFraudScreen())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


