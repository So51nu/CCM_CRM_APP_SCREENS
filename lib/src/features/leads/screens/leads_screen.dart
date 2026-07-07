part of '../../../../click_connect_ai_crm_ui.dart';

class LeadsScreen extends StatefulWidget {
  final String? filter;
  const LeadsScreen({super.key, this.filter});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  late String selected = widget.filter ?? 'All Leads';
  final filters = const ['All Leads', 'Hot', 'Warm', 'Cold', 'Follow-up Due', 'New Leads', 'Pending Calls', 'Not Connected', 'Meeting Fixed'];

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      title: 'My Leads',
      showBack: Navigator.of(context).canPop(),
      actions: [IconButton(icon: const Icon(Icons.tune_rounded), onPressed: () {})],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TextField(decoration: InputDecoration(hintText: 'Search leads by name, mobile, company...', prefixIcon: Icon(Icons.search_rounded), suffixIcon: Icon(Icons.filter_alt_outlined))),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CcChip(label: f, filled: selected == f, color: f == 'Hot' ? CcColors.red : f == 'Warm' ? CcColors.amber : CcColors.blue500, onTap: () => setState(() => selected = f)),
              )).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              CcChip(label: 'Follow-up Due 12', icon: Icons.event_repeat_rounded),
              CcChip(label: 'New Leads 28', icon: Icons.person_add_alt_rounded),
              CcChip(label: 'Pending Calls 15', icon: Icons.call_rounded),
              CcChip(label: 'Not Connected 22', icon: Icons.phone_disabled_rounded),
              CcChip(label: 'Meeting Fixed 8', icon: Icons.event_available_rounded),
            ],
          ),
          const SizedBox(height: 16),
          ...demoLeads.where((lead) => selected == 'All Leads' || lead.status == selected || selected.contains('Lead') || selected.contains('Call') || selected.contains('Follow')).map((lead) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LeadCard(lead: lead, onTap: () => context.open(LeadDetailScreen(lead: lead))),
          )),
        ],
      ),
    );
  }
}


