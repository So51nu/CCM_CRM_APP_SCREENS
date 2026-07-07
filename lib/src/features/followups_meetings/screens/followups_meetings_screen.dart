part of '../../../../click_connect_ai_crm_ui.dart';

class FollowupsMeetingsScreen extends StatefulWidget {
  final int initialTab;
  const FollowupsMeetingsScreen({super.key, this.initialTab = 0});

  @override
  State<FollowupsMeetingsScreen> createState() => _FollowupsMeetingsScreenState();
}

class _FollowupsMeetingsScreenState extends State<FollowupsMeetingsScreen> with SingleTickerProviderStateMixin {
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
      title: 'Follow-ups & Meetings',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TabBar(controller: tab, tabs: const [Tab(text: 'Follow-ups'), Tab(text: 'Meetings'), Tab(text: 'Reminders')]),
        const SizedBox(height: 12),
        SizedBox(height: 760, child: TabBarView(controller: tab, children: const [_FollowupsTab(), _MeetingTab(), _RemindersTab()])),
      ]),
    );
  }
}


