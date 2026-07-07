part of '../../../../click_connect_ai_crm_ui.dart';

class AutoFeedbackScreen extends StatefulWidget {
  final Lead? lead;
  const AutoFeedbackScreen({super.key, this.lead});

  @override
  State<AutoFeedbackScreen> createState() => _AutoFeedbackScreenState();
}

class _AutoFeedbackScreenState extends State<AutoFeedbackScreen> {
  String selectedStatus = 'Interested';
  String leadQuality = 'High';
  String mood = 'Positive';

  final statuses = const ['Interested', 'Not Interested', 'Ringing', 'Not Picked', 'Busy', 'Switched Off', 'Wrong Number', 'Call Later', 'Meeting Fixed', 'Proposal Sent', 'Payment Pending', 'Won', 'Lost', 'Junk'];

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead ?? demoLeads.first;
    return BrandedScaffold(
      title: 'Auto Feedback',
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w900)))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        GlassCard(
          gradient: LinearGradient(colors: [CcColors.green.withValues(alpha: .22), CcColors.card]),
          child: const Row(children: [Icon(Icons.check_circle_rounded, color: CcColors.green), SizedBox(width: 10), Expanded(child: Text('Call ended • Auto feedback screen opened', style: TextStyle(fontWeight: FontWeight.w900))), Icon(Icons.chevron_right_rounded)]),
        ),
        const SizedBox(height: 12),
        GlassCard(child: Column(children: [
          KeyValueRow('Lead Name', lead.name),
          KeyValueRow('Mobile Number', lead.mobile),
          const KeyValueRow('Call Status', 'Connected', valueColor: CcColors.green),
          const KeyValueRow('Call Duration', '02:48'),
          const KeyValueRow('Call Time', '16 May 2025, 11:32 AM'),
          const KeyValueRow('Recording Status', 'Recorded', valueColor: CcColors.red),
          const KeyValueRow('Sync Status', 'Synced', valueColor: CcColors.green),
          const KeyValueRow('Device ID', 'DEV-5G-78245'),
        ])),
        const SectionTitle('Feedback'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: statuses.map((status) {
            final color = status == 'Won' ? CcColors.green : status == 'Lost' || status == 'Wrong Number' ? CcColors.red : status == 'Interested' || status == 'Meeting Fixed' ? CcColors.green : CcColors.blue500;
            return CcChip(label: status, color: color, filled: selectedStatus == status, onTap: () => setState(() => selectedStatus = status));
          }).toList(),
        ),
        const SizedBox(height: 14),
        const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Discussion Notes', hintText: 'Interested in premium plan. Wants demo.')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _dropdownField('Customer Mood', mood, ['Positive', 'Neutral', 'Negative'], (v) => setState(() => mood = v))),
          const SizedBox(width: 10),
          Expanded(child: _dropdownField('Lead Quality', leadQuality, ['Hot', 'Warm', 'Cold', 'High'], (v) => setState(() => leadQuality = v))),
        ]),
        const SizedBox(height: 12),
        const TextField(decoration: InputDecoration(labelText: 'Product Interested', prefixIcon: Icon(Icons.shopping_bag_outlined))),
        const SizedBox(height: 12),
        const TextField(decoration: InputDecoration(labelText: 'Budget', hintText: '₹50,000 – ₹1,00,000', prefixIcon: Icon(Icons.currency_rupee_rounded))),
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(child: TextField(decoration: InputDecoration(labelText: 'Next Follow-up', prefixIcon: Icon(Icons.event_repeat_rounded)))),
          SizedBox(width: 10),
          Expanded(child: TextField(decoration: InputDecoration(labelText: 'Meeting Date', prefixIcon: Icon(Icons.event_available_rounded)))),
        ]),
        const SizedBox(height: 12),
        Row(children: const [
          Expanded(child: TextField(decoration: InputDecoration(labelText: 'Proposal Required', hintText: 'Yes'))),
          SizedBox(width: 10),
          Expanded(child: TextField(decoration: InputDecoration(labelText: 'WhatsApp Send', hintText: 'Yes'))),
        ]),
        const SizedBox(height: 14),
        PrimaryButton(label: 'Save Feedback & Sync CRM', icon: Icons.cloud_done_rounded, onPressed: () => context.open(const AiCoachScreen(initialTab: 0))),
      ]),
    );
  }

  Widget _dropdownField(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      dropdownColor: CcColors.card,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}


