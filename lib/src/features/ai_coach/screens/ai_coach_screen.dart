part of '../../../../click_connect_ai_crm_ui.dart';

class AiCoachScreen extends StatefulWidget {
  final int initialTab;
  const AiCoachScreen({super.key, this.initialTab = 1});

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends State<AiCoachScreen> with SingleTickerProviderStateMixin {
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
      title: 'AI Coach',
      showBack: Navigator.of(context).canPop(),
      actions: [IconButton(icon: const Icon(Icons.call_rounded), onPressed: () => context.open(const SmartCallingScreen()))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TabBar(controller: tab, tabs: const [Tab(text: 'Summary'), Tab(text: 'Coach'), Tab(text: 'Transcript')]),
        const SizedBox(height: 12),
        SizedBox(height: 760, child: TabBarView(controller: tab, children: const [_AiSummaryTab(), _AiSalesCoachTab(), _TranscriptTab()])),
      ]),
    );
  }
}


