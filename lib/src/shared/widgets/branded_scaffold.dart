part of '../../../click_connect_ai_crm_ui.dart';

class BrandedScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showBack;
  final EdgeInsetsGeometry padding;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  const BrandedScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showBack = true,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 20),
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CcColors.navy950, CcColors.navy900, CcColors.navy950],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: showBack ? null : IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () {}),
          titleSpacing: showBack ? 0 : 8,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: CcColors.text)),
          actions: actions ?? [IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {})],
        ),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}


