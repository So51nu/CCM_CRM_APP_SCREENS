part of '../../../../click_connect_ai_crm_ui.dart';

class CallingServiceScreen extends StatefulWidget {
  const CallingServiceScreen({super.key});

  @override
  State<CallingServiceScreen> createState() => _CallingServiceScreenState();
}

class _CallingServiceScreenState extends State<CallingServiceScreen> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => CrmScope.of(context).refreshNativeStatus());
    timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) CrmScope.of(context).refreshNativeStatus();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    return BrandedScaffold(
      title: 'Calling Service',
      showBack: Navigator.of(context).canPop(),
      actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => app.refreshNativeStatus())],
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              gradient: LinearGradient(colors: [CcColors.navy800, app.serviceRunning ? CcColors.green.withValues(alpha: .16) : CcColors.amber.withValues(alpha: .13)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  IconBadge(icon: Icons.phone_in_talk_rounded, color: app.serviceRunning ? CcColors.green : CcColors.amber),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(app.serviceRunning ? 'Service Active' : 'Service Inactive', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(app.serviceRunning ? 'CRM call requests will auto-run on this phone.' : 'Start service to poll pending call requests.', style: const TextStyle(color: CcColors.textSoft)),
                  ])),
                  CcChip(label: app.serviceRunning ? 'Running' : 'Stopped', color: app.serviceRunning ? CcColors.green : CcColors.amber, filled: true),
                ]),
                const SizedBox(height: 14),
                KeyValueRow('CRM URL', app.baseUrl, icon: Icons.language_rounded),
                KeyValueRow('User', '${app.userName} (${app.userId})', icon: Icons.person_outline_rounded),
                KeyValueRow('Device ID', app.deviceId, icon: Icons.phone_android_rounded),
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(
              gradient: LinearGradient(colors: [CcColors.blue500.withValues(alpha: .16), CcColors.card]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: const [
                  Icon(Icons.sync_rounded, color: CcColors.cyan400),
                  SizedBox(width: 10),
                  Expanded(child: Text('Web → App Call Sync', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                ]),
                const SizedBox(height: 10),
                KeyValueRow('Sync Status', app.webCallSyncStatus, icon: Icons.bolt_rounded, valueColor: app.webCallSyncStatus.contains('failed') ? CcColors.red : CcColors.green),
                KeyValueRow('Active Request ID', app.activeCallRequestId > 0 ? '#${app.activeCallRequestId}' : '-', icon: Icons.tag_rounded),
                if (app.activeCallRequest != null) ...[
                  KeyValueRow('Lead', _text(app.activeCallRequest?['lead_name'], 'Lead'), icon: Icons.person_outline_rounded),
                  KeyValueRow('Phone', _text(app.activeCallRequest?['phone'], '-'), icon: Icons.call_rounded, valueColor: CcColors.blue300),
                ],
                const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Check Web Call Now',
                  icon: Icons.phone_callback_rounded,
                  onPressed: app.apiLoading ? null : () => app.checkWebCallRequestAndDial(force: true),
                ),
                const SizedBox(height: 8),
                const Text('Telecaller Workspace ', style: TextStyle(color: CcColors.textMuted, height: 1.4)),
              ]),
            ),
            const SizedBox(height: 12),
            GlassCard(child: Column(children: [
              SwitchListTile(
                value: app.autoCallEnabled,
                onChanged: app.setAutoCall,
                title: const Text('Direct Auto-Call', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Direct Auto Call', style: TextStyle(color: CcColors.textMuted)),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(color: CcColors.line),
              SwitchListTile(
                value: app.autoRecordingEnabled,
                onChanged: app.setAutoRecording,
                title: const Text('Auto Recording Upload', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text('Call Recording', style: TextStyle(color: CcColors.textMuted)),
                contentPadding: EdgeInsets.zero,
              ),
            ])),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: PrimaryButton(label: app.serviceRunning ? 'Running' : 'Start Service', icon: Icons.play_arrow_rounded, onPressed: app.serviceRunning || app.apiLoading ? null : app.startCallingService)),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: app.serviceRunning ? app.stopCallingService : null, icon: const Icon(Icons.stop_rounded), label: const Text('Stop'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: app.apiLoading ? null : app.testPendingCallApi, icon: const Icon(Icons.api_rounded), label: const Text('Test API'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: app.apiLoading ? null : () => app.native.openBatterySettings(), icon: const Icon(Icons.battery_saver_rounded), label: const Text('Battery'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))))),
            ]),
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: app.apiLoading ? null : () => app.native.callNow('+919999999999'), icon: const Icon(Icons.call_rounded), label: const Text('Manual Test Call'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))),
            const SectionTitle('Live Native Status'),
            GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              KeyValueRow('Status', app.statusMessage, icon: Icons.info_outline_rounded, valueColor: app.error == null ? CcColors.green : CcColors.red),
              KeyValueRow('Last Native Message', app.lastNativeMessage, icon: Icons.message_outlined),
              KeyValueRow('Last Recording Local Path', app.lastRecordingPath, icon: Icons.folder_outlined),
              KeyValueRow('Last Recording CRM URL', app.lastRecordingUrl, icon: Icons.link_rounded, valueColor: CcColors.blue300),
            ])),
            const SizedBox(height: 12),
            GlassCard(
              gradient: LinearGradient(colors: [CcColors.red.withValues(alpha: .12), CcColors.card]),
              child: const Text(
                'Calling App',
                style: TextStyle(color: CcColors.textSoft, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
