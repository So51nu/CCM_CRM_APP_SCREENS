part of '../../../click_connect_ai_crm_ui.dart';

class CrmShell extends StatefulWidget {
  final String role;

  const CrmShell({super.key, required this.role});

  @override
  State<CrmShell> createState() => _CrmShellState();
}

class _CrmShellState extends State<CrmShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = CrmScope.of(context);
      unawaited(app.refreshLeads(silent: true));
      unawaited(app.ensureRealtimeCallSync(reason: 'shell_start'));
    });
  }
  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    final pages = <Widget>[
      const CallingServiceScreen(),
      const RecordingSaveScreen(),
      const ProfileScreen(),
    ];
    return AnimatedBuilder(
      animation: app,
      builder: (context, _) {
        return Scaffold(
        backgroundColor: CcColors.navy950,
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: CcColors.navy900,
            border: Border(top: BorderSide(color: CcColors.line)),
          ),
          child: SafeArea(
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              indicatorColor: CcColors.blue500.withValues(alpha: .24),
              selectedIndex: index,
              onDestinationSelected: (v) => setState(() => index = v),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.phone_in_talk_outlined),
                  selectedIcon: Icon(Icons.phone_in_talk_rounded),
                  label: 'Calling',
                ),
                NavigationDestination(
                  icon: Icon(Icons.mic_external_on_outlined),
                  selectedIcon: Icon(Icons.mic_external_on_rounded),
                  label: 'Recording',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}
