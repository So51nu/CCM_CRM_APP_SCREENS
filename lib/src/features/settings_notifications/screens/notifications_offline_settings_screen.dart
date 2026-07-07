part of '../../../../click_connect_ai_crm_ui.dart';

class NotificationsOfflineSettingsScreen extends StatefulWidget {
  final int initialTab;
  const NotificationsOfflineSettingsScreen({super.key, this.initialTab = 0});

  @override
  State<NotificationsOfflineSettingsScreen> createState() => _NotificationsOfflineSettingsScreenState();
}

class _NotificationsOfflineSettingsScreenState extends State<NotificationsOfflineSettingsScreen> with SingleTickerProviderStateMixin {
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
      title: 'Notifications & Settings',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TabBar(controller: tab, isScrollable: true, tabs: const [Tab(text: 'Notifications'), Tab(text: 'Offline Sync'), Tab(text: 'Profile')]),
        const SizedBox(height: 12),
        SizedBox(height: 790, child: TabBarView(controller: tab, children: const [_NotificationsTab(), _OfflineSyncTab(), _ProfileSettingsTab()])),
      ]),
    );
  }
}


