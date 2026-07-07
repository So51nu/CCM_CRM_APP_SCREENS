part of '../../../../click_connect_ai_crm_ui.dart';

class MoreMenuScreen extends StatelessWidget {
  final String role;
  const MoreMenuScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.event_repeat_rounded, CcColors.amber, 'Follow-ups', 'Daily follow-up & reminders', const FollowupsMeetingsScreen()),
      (Icons.chat_rounded, CcColors.green, 'WhatsApp', 'Automation triggers', const WhatsAppProposalsDocsScreen(initialTab: 0)),
      (Icons.description_rounded, CcColors.blue500, 'Proposals', 'Quick view & share', const WhatsAppProposalsDocsScreen(initialTab: 1)),
      (Icons.folder_rounded, CcColors.purple, 'Documents', 'Brochure & files', const WhatsAppProposalsDocsScreen(initialTab: 2)),
      (Icons.insights_rounded, CcColors.blue500, 'Reports', 'Performance dashboard', const ReportsProofFraudScreen(initialTab: 0)),
      (Icons.verified_user_rounded, CcColors.green, 'Call Proof', 'Verified call engine', const ReportsProofFraudScreen(initialTab: 1)),
      (Icons.warning_amber_rounded, CcColors.red, 'Fraud Detection', 'Suspicious alerts', const ReportsProofFraudScreen(initialTab: 2)),
      (Icons.notifications_rounded, CcColors.orange, 'Notifications', 'Alerts & reminders', const NotificationsOfflineSettingsScreen(initialTab: 0)),
      (Icons.cloud_sync_rounded, CcColors.cyan400, 'Offline Sync', 'Cache & retry queue', const NotificationsOfflineSettingsScreen(initialTab: 1)),
      (Icons.settings_rounded, CcColors.textMuted, 'Profile Settings', 'Permissions & device', const NotificationsOfflineSettingsScreen(initialTab: 2)),
      (Icons.lock_rounded, CcColors.blue500, 'Login Security', 'Device binding & app lock', const LoginSecurityScreen()),
      if (role == 'Manager') (Icons.admin_panel_settings_rounded, CcColors.purple, 'Manager View', 'Team dashboard & review', const ManagerViewScreen()),
    ];
    return BrandedScaffold(
      title: 'More',
      showBack: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GlassCard(
          gradient: const LinearGradient(colors: [CcColors.navy800, CcColors.card]),
          child: Row(children: [
            const IconBadge(icon: Icons.hub_rounded, color: CcColors.blue500, size: 54),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Click Connect AI CRM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const Text('One Click Call → Proof → AI Summary → CRM Sync', style: TextStyle(color: CcColors.textMuted)),
              const SizedBox(height: 8),
              CcChip(label: role, icon: Icons.verified_rounded, filled: true),
            ])),
          ]),
        ),
        const SectionTitle('All App Screens'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: .98,
          children: items.map((e) => GlassCard(
            onTap: () => context.open(e.$5),
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconBadge(icon: e.$1, color: e.$2, size: 44),
              const Spacer(),
              Text(e.$3, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(e.$4, style: const TextStyle(color: CcColors.textMuted, fontSize: 12, height: 1.3)),
              const SizedBox(height: 8),
              const Align(alignment: Alignment.centerRight, child: Icon(Icons.arrow_forward_rounded, color: CcColors.textMuted)),
            ]),
          )).toList(),
        ),
      ]),
    );
  }
}

