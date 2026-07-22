part of '../../../../click_connect_ai_crm_ui.dart';

class RecordingSaveScreen extends StatelessWidget {
  const RecordingSaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    return BrandedScaffold(
      title: 'Recording Save',
      showBack: false,
      actions: [
        IconButton(
          tooltip: 'Refresh status',
          onPressed: () => app.refreshNativeStatus(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              gradient: LinearGradient(colors: [CcColors.blue500.withValues(alpha: .16), CcColors.card]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    IconBadge(icon: Icons.mic_external_on_rounded, color: app.autoRecordingEnabled ? CcColors.green : CcColors.amber),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(app.autoRecordingEnabled ? 'Auto Recording ON' : 'Auto Recording OFF', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          const Text('Call end hone ke baad recording CRM me upload hogi.', style: TextStyle(color: CcColors.textSoft)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    value: app.autoRecordingEnabled,
                    onChanged: app.setAutoRecording,
                    title: const Text('Auto Recording Upload', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: const Text('Recording file /api/upload-call-recording.php par save hogi', style: TextStyle(color: CcColors.textMuted)),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(color: CcColors.line),
                  KeyValueRow('Service', app.serviceRunning ? 'Running' : 'Stopped', icon: Icons.cloud_sync_rounded, valueColor: app.serviceRunning ? CcColors.green : CcColors.amber),
                  KeyValueRow('Last Native Message', app.lastNativeMessage, icon: Icons.message_outlined),
                  KeyValueRow('Phone Folder', app.recordingFolderPath, icon: Icons.folder_special_outlined, valueColor: CcColors.blue300),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Last Recording Result', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  KeyValueRow('Recording Folder', app.recordingFolderPath, icon: Icons.folder_special_outlined, valueColor: CcColors.blue300),
                  KeyValueRow('Local File Path', app.lastRecordingPath, icon: Icons.folder_outlined),
                  KeyValueRow('CRM Recording URL', app.lastRecordingUrl, icon: Icons.link_rounded, valueColor: app.lastRecordingUrl == '-' || app.lastRecordingUrl.isEmpty ? CcColors.amber : CcColors.green),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: app.refreshNativeStatus,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Refresh'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => app.native.openBatterySettings(),
                        icon: const Icon(Icons.battery_saver_rounded),
                        label: const Text('Battery'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              gradient: LinearGradient(colors: [CcColors.amber.withValues(alpha: .14), CcColors.card]),
              child: const Text(
                'Important: Login ke baad app real phone storage ke app-specific Music/call_recordings folder ko ready karta hai. Har connected call ki .m4a file yahin local save hogi, call cut hote hi CRM upload hoga. Upload fail hua to file local rahegi aur service auto-retry karegi. Android me call recording device policy par depend karta hai; is app me microphone recording fallback hai. Phone, Microphone, Phone State permission allow rakho aur battery restriction Unrestricted rakho.',
                style: TextStyle(color: CcColors.textSoft, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
