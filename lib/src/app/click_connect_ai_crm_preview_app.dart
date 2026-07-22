part of '../../click_connect_ai_crm_ui.dart';

class ClickConnectAiCrmPreviewApp extends StatefulWidget {
  const ClickConnectAiCrmPreviewApp({super.key});

  @override
  State<ClickConnectAiCrmPreviewApp> createState() => _ClickConnectAiCrmPreviewAppState();
}

class _ClickConnectAiCrmPreviewAppState extends State<ClickConnectAiCrmPreviewApp> with WidgetsBindingObserver {
  late final CrmAppState appState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    appState = CrmAppState(api: const ApiClient(), store: SessionStore(), native: NativeCallBridge());
    unawaited(appState.init());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(appState.ensureRealtimeCallSync(reason: 'app_resumed'));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CrmScope(
      state: appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Click Connect AI CRM',
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: CcColors.navy950,
          colorScheme: ColorScheme.fromSeed(
            seedColor: CcColors.blue500,
            brightness: Brightness.dark,
            primary: CcColors.blue500,
            secondary: CcColors.cyan400,
            surface: CcColors.card,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: false,
            systemOverlayStyle: SystemUiOverlayStyle.light,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: CcColors.cardSoft,
            hintStyle: const TextStyle(color: CcColors.textMuted),
            labelStyle: const TextStyle(color: CcColors.textMuted),
            prefixIconColor: CcColors.textMuted,
            suffixIconColor: CcColors.textMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: CcColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: CcColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: CcColors.blue500, width: 1.5),
            ),
          ),
        ),
        home: AnimatedBuilder(
          animation: appState,
          builder: (context, _) {
            if (!appState.initialized) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (!appState.isLoggedIn) {
              return const LoginSecurityScreen();
            }
            return CrmShell(role: appState.role);
          },
        ),
      ),
    );
  }
}
