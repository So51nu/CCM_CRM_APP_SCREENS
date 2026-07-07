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
  Widget build(BuildContext context) {
    final isManager = widget.role == 'Manager';
    final pages = <Widget>[
      isManager ? const ManagerViewScreen(inShell: true) : const TelecallerDashboardScreen(),
      const LeadsScreen(),
      const SmartCallingScreen(),
      const AiCoachScreen(),
      MoreMenuScreen(role: widget.role),
    ];
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
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt_rounded), label: 'My Leads'),
              NavigationDestination(icon: Icon(Icons.phone_in_talk_outlined), selectedIcon: Icon(Icons.phone_in_talk_rounded), label: 'Smart Calling'),
              NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome_rounded), label: 'AI Coach'),
              NavigationDestination(icon: Icon(Icons.more_horiz_rounded), selectedIcon: Icon(Icons.more_rounded), label: 'More'),
            ],
          ),
        ),
      ),
    );
  }
}


