part of '../../../../click_connect_ai_crm_ui.dart';

class WhatsAppProposalsDocsScreen extends StatefulWidget {
  final int initialTab;
  const WhatsAppProposalsDocsScreen({super.key, this.initialTab = 0});

  @override
  State<WhatsAppProposalsDocsScreen> createState() => _WhatsAppProposalsDocsScreenState();
}

class _WhatsAppProposalsDocsScreenState extends State<WhatsAppProposalsDocsScreen> with SingleTickerProviderStateMixin {
  late final TabController tab;

  @override
  void initState() {
    super.initState();
    tab = TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      title: 'WhatsApp & Docs',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TabBar(controller: tab, isScrollable: true, tabs: const [Tab(text: 'WhatsApp'), Tab(text: 'Proposals'), Tab(text: 'Documents')]),
        const SizedBox(height: 12),
        SizedBox(height: 760, child: TabBarView(controller: tab, children: const [_WhatsAppAutomationTab(), ProposalInvoiceBlock(), ClientDocumentsBlock()])),
      ]),
    );
  }
}


