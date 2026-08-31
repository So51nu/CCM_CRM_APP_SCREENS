part of '../../../../click_connect_ai_crm_ui.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    return BrandedScaffold(
      title: 'Profile',
      showBack: false,
      actions: [
        IconButton(
          tooltip: 'Refresh profile/session',
          onPressed: app.apiLoading ? null : () => app.refreshAll(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              gradient: LinearGradient(colors: [CcColors.blue500.withValues(alpha: .20), CcColors.card]),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: CcColors.blue500,
                    child: Text(_initial(app.userName), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        CcChip(label: app.role, color: CcColors.blue500, filled: true),
                        const SizedBox(height: 6),
                        Text(app.userEmail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CcColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  KeyValueRow('User ID', '#${app.userId}', icon: Icons.badge_outlined),
                  KeyValueRow('Name', app.userName, icon: Icons.person_outline_rounded),
                  KeyValueRow('Email', app.userEmail.isEmpty ? '-' : app.userEmail, icon: Icons.email_outlined),
                  KeyValueRow('Role', app.role, icon: Icons.manage_accounts_outlined, valueColor: CcColors.blue300),
                  KeyValueRow('CRM URL', app.baseUrl, icon: Icons.language_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Device & Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  KeyValueRow('Device ID', app.deviceId, icon: Icons.phone_android_rounded, valueColor: CcColors.green),
                  KeyValueRow('Calling Service', app.serviceRunning ? 'Active' : 'Inactive', icon: Icons.phone_in_talk_rounded, valueColor: app.serviceRunning ? CcColors.green : CcColors.amber),
                  KeyValueRow('Auto Call', app.autoCallEnabled ? 'ON' : 'OFF', icon: Icons.sync_rounded, valueColor: app.autoCallEnabled ? CcColors.green : CcColors.amber),
                  KeyValueRow('Recording Upload', app.autoRecordingEnabled ? 'ON' : 'OFF', icon: Icons.mic_external_on_rounded, valueColor: app.autoRecordingEnabled ? CcColors.green : CcColors.amber),
                  KeyValueRow('Last Status', app.statusMessage, icon: Icons.info_outline_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: app.loading ? null : () => _confirmLogout(context, app),
                    icon: const Icon(Icons.logout_rounded, color: CcColors.red),
                    label: const Text('Logout', style: TextStyle(color: CcColors.red, fontWeight: FontWeight.w900)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(color: CcColors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('', style: TextStyle(color: CcColors.textMuted, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, CrmAppState app) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: CcColors.card,
        title: const Text('Logout?'),
        content: const Text('Are You Sure to want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton.icon(onPressed: () => Navigator.pop(dialogContext, true), icon: const Icon(Icons.logout_rounded), label: const Text('Logout')),
        ],
      ),
    );
    if (ok != true) return;
    await app.logout();
  }
}
