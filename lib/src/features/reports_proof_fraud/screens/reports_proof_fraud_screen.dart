part of '../../../../click_connect_ai_crm_ui.dart';

class ReportsProofFraudScreen extends StatefulWidget {
  final int initialTab;
  const ReportsProofFraudScreen({super.key, this.initialTab = 0});

  @override
  State<ReportsProofFraudScreen> createState() => _ReportsProofFraudScreenState();
}

class _ReportsProofFraudScreenState extends State<ReportsProofFraudScreen> with SingleTickerProviderStateMixin {
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
      title: 'Reports & Proof',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TabBar(controller: tab, isScrollable: true, tabs: const [Tab(text: 'Performance'), Tab(text: 'Call Proof'), Tab(text: 'Fraud')]),
        const SizedBox(height: 12),
        SizedBox(height: 790, child: TabBarView(controller: tab, children: const [_PerformanceTab(), _CallProofTab(), _FraudDetectionTab()])),
      ]),
    );
  }
}


