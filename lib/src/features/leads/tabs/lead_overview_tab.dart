part of '../../../../click_connect_ai_crm_ui.dart';

class _LeadOverview extends StatelessWidget {
  final Lead lead;
  const _LeadOverview({required this.lead});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Overview', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          KeyValueRow('Interest', lead.interest),
          KeyValueRow('Source', lead.source),
          KeyValueRow('City', lead.city),
          const KeyValueRow('Lead Owner', 'Arjun Sharma'),
          const KeyValueRow('Created On', '20 May 2025, 10:20 AM'),
          KeyValueRow('Next Follow-up', lead.followUp, valueColor: CcColors.amber),
        ])),
        const SizedBox(height: 12),
        GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Contact Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 8),
          KeyValueRow('Mobile', lead.mobile, icon: Icons.call_rounded),
          KeyValueRow('Alternate', lead.alternate, icon: Icons.phone_android_rounded),
          const KeyValueRow('Email', 'vikram.mehta@email.com', icon: Icons.email_outlined),
          KeyValueRow('Company', lead.company, icon: Icons.business_rounded),
          const KeyValueRow('Designation', 'CEO', icon: Icons.badge_outlined),
          const KeyValueRow('Address', 'Koramangala, Bengaluru, Karnataka', icon: Icons.location_on_outlined),
        ])),
        const SizedBox(height: 12),
        GlassCard(
          gradient: LinearGradient(colors: [CcColors.purple.withValues(alpha: .25), CcColors.blue600.withValues(alpha: .12)]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.auto_awesome_rounded, color: CcColors.purple), SizedBox(width: 10), Text('AI Recommendations', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))]),
            const SizedBox(height: 10),
            const Text('• Best time to call: 11 AM – 1 PM\n• Customer showed interest in CRM features\n• Share case study on similar businesses\n• High probability to convert', style: TextStyle(color: CcColors.textSoft, height: 1.5)),
            const SizedBox(height: 12),
            PrimaryButton(label: 'View AI Insights', icon: Icons.insights_rounded, onPressed: () => context.open(const AiCoachScreen()), color: CcColors.purple),
          ]),
        ),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _quickAction(context, 'Call', Icons.call_rounded, CcColors.blue500, () => context.open(SmartCallingScreen(lead: lead))),
          _quickAction(context, 'WhatsApp', Icons.chat_rounded, CcColors.green, () {}),
          _quickAction(context, 'Add Note', Icons.note_add_rounded, CcColors.purple, () {}),
          _quickAction(context, 'Follow-up', Icons.event_repeat_rounded, CcColors.amber, () => context.open(const FollowupsMeetingsScreen())),
          _quickAction(context, 'Meeting', Icons.event_available_rounded, CcColors.orange, () => context.open(const FollowupsMeetingsScreen(initialTab: 1))),
        ]),
      ]),
    );
  }

  Widget _quickAction(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: .18), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: .45))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18, color: color), const SizedBox(width: 7), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800))]),
    ),
  );
}


