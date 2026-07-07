part of '../../../../click_connect_ai_crm_ui.dart';

class _MeetingTab extends StatelessWidget {
  const _MeetingTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Meeting Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        SizedBox(height: 12),
        TextField(decoration: InputDecoration(labelText: 'Lead / Contact', hintText: 'Rohit Sharma - TechNova Solutions', prefixIcon: Icon(Icons.person_outline_rounded))),
        SizedBox(height: 12),
        TextField(decoration: InputDecoration(labelText: 'Title', hintText: 'Product Demo & Requirement Discussion', prefixIcon: Icon(Icons.title_rounded))),
        SizedBox(height: 12),
        Row(children: [Expanded(child: TextField(decoration: InputDecoration(labelText: 'Date', hintText: 'May 15, 2025', prefixIcon: Icon(Icons.calendar_month_rounded)))), SizedBox(width: 10), Expanded(child: TextField(decoration: InputDecoration(labelText: 'Time', hintText: '11:00 AM', prefixIcon: Icon(Icons.access_time_rounded))))]),
        SizedBox(height: 12),
        TextField(decoration: InputDecoration(labelText: 'Duration', hintText: '60 Minutes', prefixIcon: Icon(Icons.timer_outlined))),
        SizedBox(height: 12),
        TextField(decoration: InputDecoration(labelText: 'Location', hintText: 'TechNova Office, Bengaluru', prefixIcon: Icon(Icons.location_on_outlined))),
      ])),
      const SizedBox(height: 12),
      GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Meeting Link', style: TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Row(children: const [Expanded(child: CcChip(label: 'Google Meet', icon: Icons.video_call_rounded, color: CcColors.green, filled: true)), SizedBox(width: 10), Expanded(child: CcChip(label: 'Zoom', icon: Icons.videocam_rounded, color: CcColors.blue500, filled: true))]),
        const SizedBox(height: 12),
        const KeyValueRow('Customer Confirmation', 'Confirmed', valueColor: CcColors.green),
        const KeyValueRow('Manager Notification', 'Notified', valueColor: CcColors.blue300),
      ])),
      const SectionTitle('Meeting Status'),
      Wrap(spacing: 8, runSpacing: 8, children: const [CcChip(label: 'Scheduled', filled: true), CcChip(label: 'Confirmed', color: CcColors.green), CcChip(label: 'Completed', color: CcColors.green), CcChip(label: 'Cancelled', color: CcColors.red), CcChip(label: 'Rescheduled', color: CcColors.amber), CcChip(label: 'No Show', color: CcColors.purple)]),
      const SizedBox(height: 14),
      const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Notes', hintText: 'Prepare demo for AI CRM module and pricing discussion.')),
      const SizedBox(height: 14),
      PrimaryButton(label: 'Save Meeting', icon: Icons.save_rounded, onPressed: () {}),
    ]));
  }
}


