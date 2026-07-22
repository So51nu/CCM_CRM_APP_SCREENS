part of '../../../../click_connect_ai_crm_ui.dart';

class SmartCallingScreen extends StatelessWidget {
  final Lead? lead;
  const SmartCallingScreen({super.key, this.lead});

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    final activeLead = lead ?? (app.leads.isNotEmpty ? app.leads.first : demoLeads.first);
    return BrandedScaffold(
      title: 'Smart Calling',
      showBack: Navigator.of(context).canPop(),
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              child: Row(children: [
                CircleAvatar(radius: 30, backgroundColor: CcColors.blue500, child: Text(_initial(activeLead.name), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(activeLead.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    const CcChip(label: 'Verified Lead', color: CcColors.green, icon: Icons.verified_rounded, filled: true),
                    CcChip(label: 'Lead ID: ${activeLead.id > 0 ? activeLead.id : '-'}'),
                  ]),
                ])),
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(child: Row(children: [Expanded(child: KeyValueRow('Call Session ID', 'Auto from CRM / request API', icon: Icons.tag_rounded)), const Icon(Icons.copy_rounded, color: CcColors.textMuted)])),
            const SectionTitle('Choose a number to call'),
            CallingActionTile(icon: Icons.call_rounded, color: CcColors.blue500, title: 'Call Primary Number', subtitle: activeLead.mobile, onTap: () async {
              await app.callLead(activeLead);
              if (context.mounted) context.open(VerifiedCallTrackingScreen(lead: activeLead));
            }),
            CallingActionTile(icon: Icons.phone_forwarded_rounded, color: CcColors.blue500, title: 'Call Alternate Number', subtitle: activeLead.alternate.isEmpty ? 'No alternate number' : activeLead.alternate, disabled: activeLead.alternate.isEmpty, onTap: () async {
              await app.callLead(activeLead, alternate: true);
              if (context.mounted) context.open(VerifiedCallTrackingScreen(lead: activeLead));
            }),
            CallingActionTile(icon: Icons.chat_rounded, color: CcColors.green, title: 'WhatsApp', subtitle: activeLead.mobile, onTap: () => context.open(const WhatsAppProposalsDocsScreen())),
            const CallingActionTile(icon: Icons.content_copy_rounded, color: CcColors.textMuted, title: 'Copy Number', subtitle: 'Disabled by admin policy', disabled: true),
            const SizedBox(height: 12),
            GlassCard(child: Column(children: [
              KeyValueRow('Lead Source', activeLead.source, icon: Icons.campaign_outlined),
              KeyValueRow('Assigned To', app.userName, icon: Icons.person_outline_rounded),
              KeyValueRow('Lead Score', '${activeLead.score} / 100', icon: Icons.bolt_rounded, valueColor: CcColors.green),
              const KeyValueRow('Copy Number Policy', 'Controlled / Disabled', icon: Icons.security_rounded, valueColor: CcColors.amber),
            ])),
            const SizedBox(height: 12),
            const Text('All app-based calls are linked with lead ID, user ID, device ID, app version and sync status.', style: TextStyle(color: CcColors.textMuted, height: 1.45)),
          ],
        ),
      ),
    );
  }
}
