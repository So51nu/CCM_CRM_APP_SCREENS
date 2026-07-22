part of '../../../../click_connect_ai_crm_ui.dart';

class LeadsScreen extends StatefulWidget {
  final String? filter;
  const LeadsScreen({super.key, this.filter});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  late String selected = widget.filter ?? 'All Leads';
  final search = TextEditingController();
  final filters = const ['All Leads', 'Hot', 'Warm', 'Cold', 'Follow-up Due', 'New Leads', 'Pending Calls', 'Not Connected', 'Meeting Fixed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => CrmScope.of(context).refreshLeads());
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    return BrandedScaffold(
      title: 'My Leads',
      showBack: Navigator.of(context).canPop(),
      actions: [IconButton(icon: const Icon(Icons.sync_rounded), onPressed: app.refreshLeads), IconButton(icon: const Icon(Icons.tune_rounded), onPressed: () {})],
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) {
          final query = search.text.trim().toLowerCase();
          final sourceLeads = app.leads.isNotEmpty ? app.leads : demoLeads;
          final filtered = sourceLeads.where((lead) {
            final matchesFilter = selected == 'All Leads' || lead.status == selected || selected.contains('Lead') || selected.contains('Call') || selected.contains('Follow') || selected == 'Meeting Fixed';
            final matchesSearch = query.isEmpty || '${lead.name} ${lead.company} ${lead.mobile} ${lead.city} ${lead.interest}'.toLowerCase().contains(query);
            return matchesFilter && matchesSearch;
          }).toList();
          return RefreshIndicator(
            onRefresh: app.refreshLeads,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (app.apiLoading) const LinearProgressIndicator(minHeight: 2),
                TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'Search leads by name, mobile, company...', prefixIcon: Icon(Icons.search_rounded), suffixIcon: Icon(Icons.filter_alt_outlined))),
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
                  children: [
                    CcChip(label: 'Total ${sourceLeads.length}', icon: Icons.people_alt_rounded),
                    CcChip(label: 'Hot ${sourceLeads.where((e) => e.status == 'Hot').length}', icon: Icons.local_fire_department_rounded, color: CcColors.red),
                    CcChip(label: 'Warm ${sourceLeads.where((e) => e.status == 'Warm').length}', icon: Icons.thermostat_rounded, color: CcColors.amber),
                    CcChip(label: 'Cold ${sourceLeads.where((e) => e.status == 'Cold').length}', icon: Icons.ac_unit_rounded, color: CcColors.blue500),
                  ],
                ),
                const SizedBox(height: 16),
                if (app.leads.isEmpty)
                  GlassCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                      Text('No live leads received yet', style: TextStyle(fontWeight: FontWeight.w900)),
                      SizedBox(height: 6),
                      Text('API connected hai. Agar backend empty response dega to yaha demo fallback dikhega. Assigned Leads API me user wise leads aate hi list live ho jayegi.', style: TextStyle(color: CcColors.textMuted, height: 1.4)),
                    ]),
                  ),
                ...filtered.map((lead) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LeadCard(lead: lead, onTap: () => context.open(LeadDetailScreen(lead: lead))),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}
