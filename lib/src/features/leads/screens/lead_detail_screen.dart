part of '../../../../click_connect_ai_crm_ui.dart';

class LeadDetailScreen extends StatefulWidget {
  final Lead? lead;
  const LeadDetailScreen({super.key, this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController tab;

  @override
  void initState() {
    super.initState();
    tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead ?? demoLeads.first;
    return BrandedScaffold(
      title: 'Lead Details',
      actions: [IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}), IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {})],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 28, backgroundColor: CcColors.blue500, child: Text(lead.name[0], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text(lead.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), CcChip(label: lead.status, color: lead.status == 'Hot' ? CcColors.red : CcColors.amber, filled: true)]),
                  Text(lead.company, style: const TextStyle(color: CcColors.textMuted)),
                ])),
              ]),
              const SizedBox(height: 14),
              Wrap(spacing: 8, runSpacing: 8, children: [
                CcChip(label: 'AI Score ${lead.score}', color: CcColors.green, icon: Icons.bolt_rounded, filled: true),
                CcChip(label: 'Priority ${lead.priority}', color: CcColors.red, icon: Icons.flag_rounded, filled: true),
                const CcChip(label: 'Status New Lead', color: CcColors.blue500, filled: true),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          TabBar(controller: tab, isScrollable: true, tabs: const [Tab(text: 'Overview'), Tab(text: 'Timeline'), Tab(text: 'Files'), Tab(text: 'Invoices')]),
          const SizedBox(height: 12),
          SizedBox(
            height: 720,
            child: TabBarView(controller: tab, children: [
              _LeadOverview(lead: lead),
              const _LeadTimeline(),
              const _LeadFiles(),
              const _LeadInvoices(),
            ]),
          ),
        ],
      ),
    );
  }
}


