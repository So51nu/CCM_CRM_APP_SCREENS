part of '../../../../click_connect_ai_crm_ui.dart';

class AutoFeedbackScreen extends StatefulWidget {
  final Lead? lead;
  const AutoFeedbackScreen({super.key, this.lead});

  @override
  State<AutoFeedbackScreen> createState() => _AutoFeedbackScreenState();
}

class _AutoFeedbackScreenState extends State<AutoFeedbackScreen> {
  final notes = TextEditingController(text: 'Client asked for proposal');
  final duration = TextEditingController(text: '00:02:15');
  final budget = TextEditingController();
  final product = TextEditingController();
  String selectedStatus = 'Interested';
  String leadQuality = 'Hot';
  String mood = 'Positive';

  final statuses = const ['Interested', 'Not Interested', 'Ringing', 'Not Picked', 'Busy', 'Switched Off', 'Wrong Number', 'Call Later', 'Meeting Fixed', 'Proposal Sent', 'Payment Pending', 'Won', 'Lost', 'Junk'];

  @override
  void dispose() {
    notes.dispose();
    duration.dispose();
    budget.dispose();
    product.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    final lead = widget.lead ?? (app.leads.isNotEmpty ? app.leads.first : demoLeads.first);
    return BrandedScaffold(
      title: 'Auto Feedback',
      actions: [TextButton(onPressed: app.apiLoading ? null : () => _save(context, lead), child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w900)))],
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (app.apiLoading) const LinearProgressIndicator(minHeight: 2),
          GlassCard(
            gradient: LinearGradient(colors: [CcColors.green.withValues(alpha: .22), CcColors.card]),
            child: const Row(children: [Icon(Icons.check_circle_rounded, color: CcColors.green), SizedBox(width: 10), Expanded(child: Text('Call ended • feedback will sync to CRM', style: TextStyle(fontWeight: FontWeight.w900))), Icon(Icons.chevron_right_rounded)]),
          ),
          const SizedBox(height: 12),
          GlassCard(child: Column(children: [
            KeyValueRow('Lead Name', lead.name),
            KeyValueRow('Mobile Number', lead.mobile),
            KeyValueRow('Call Status', selectedStatus, valueColor: CcColors.green),
            TextField(controller: duration, decoration: const InputDecoration(labelText: 'Call Duration', prefixIcon: Icon(Icons.timer_outlined))),
            const SizedBox(height: 10),
            KeyValueRow('Call Time', DateTime.now().toString().substring(0, 16)),
            KeyValueRow('Recording Status', app.autoRecordingEnabled ? 'Enabled / upload by native service' : 'Disabled', valueColor: app.autoRecordingEnabled ? CcColors.green : CcColors.amber),
            KeyValueRow('Sync Status', app.statusMessage, valueColor: CcColors.green),
            KeyValueRow('Device ID', app.deviceId),
            KeyValueRow('Linked Web Request', app.activeCallRequestId > 0 ? '#${app.activeCallRequestId}' : 'No active web request', valueColor: app.activeCallRequestId > 0 ? CcColors.green : CcColors.amber),
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
          TextField(controller: notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Discussion Notes', hintText: 'Client asked for proposal')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _dropdownField('Customer Mood', mood, ['Positive', 'Neutral', 'Negative'], (v) => setState(() => mood = v))),
            const SizedBox(width: 10),
            Expanded(child: _dropdownField('Lead Quality', leadQuality, ['Hot', 'Warm', 'Cold', 'High'], (v) => setState(() => leadQuality = v))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: product, decoration: InputDecoration(labelText: 'Product Interested', hintText: lead.interest, prefixIcon: const Icon(Icons.shopping_bag_outlined))),
          const SizedBox(height: 12),
          TextField(controller: budget, decoration: const InputDecoration(labelText: 'Budget', hintText: '₹50,000 – ₹1,00,000', prefixIcon: Icon(Icons.currency_rupee_rounded))),
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
          PrimaryButton(label: app.apiLoading ? 'Saving...' : 'Save Feedback & Sync CRM', icon: Icons.cloud_done_rounded, onPressed: app.apiLoading ? null : () => _save(context, lead)),
        ]),
      ),
    );
  }

  Future<void> _save(BuildContext context, Lead lead) async {
    final app = CrmScope.of(context);
    try {
      await app.submitFeedback(lead: lead, requestId: app.activeCallRequestId, status: selectedStatus, duration: duration.text, notes: '${notes.text}\nMood: $mood\nQuality: $leadQuality\nProduct: ${product.text}\nBudget: ${budget.text}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback synced with CRM')));
        context.open(const AiCoachScreen(initialTab: 0));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Feedback failed: $e')));
    }
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
