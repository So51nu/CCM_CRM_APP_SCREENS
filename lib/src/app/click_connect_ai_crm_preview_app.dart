part of '../../click_connect_ai_crm_ui.dart';

class ClickConnectAiCrmPreviewApp extends StatelessWidget {
  const ClickConnectAiCrmPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const LoginSecurityScreen(),
    );
  }
}


