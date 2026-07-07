part of '../../../../click_connect_ai_crm_ui.dart';

class ManagerViewScreen extends StatefulWidget {
  final bool inShell;
  final int initialTab;
  const ManagerViewScreen({super.key, this.inShell = false, this.initialTab = 0});

  @override
  State<ManagerViewScreen> createState() => _ManagerViewScreenState();
}

class _ManagerViewScreenState extends State<ManagerViewScreen> with SingleTickerProviderStateMixin {
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
      title: 'Manager App View',
      showBack: !widget.inShell && Navigator.of(context).canPop(),
      actions: [IconButton(icon: const Icon(Icons.notifications_none_rounded), onPressed: () => context.open(const NotificationsOfflineSettingsScreen()))],
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TabBar(controller: tab, isScrollable: true, tabs: const [Tab(text: 'Dashboard'), Tab(text: 'Assign Leads'), Tab(text: 'Call Review')]),
        const SizedBox(height: 12),
        SizedBox(height: 800, child: TabBarView(controller: tab, children: const [_ManagerDashboardTab(), _LeadAssignmentTab(), _CallReviewTab()])),
      ]),
    );
  }
}


