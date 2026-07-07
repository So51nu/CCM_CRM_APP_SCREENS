part of '../../../../click_connect_ai_crm_ui.dart';

class LoginSecurityScreen extends StatefulWidget {
  const LoginSecurityScreen({super.key});

  @override
  State<LoginSecurityScreen> createState() => _LoginSecurityScreenState();
}

class _LoginSecurityScreenState extends State<LoginSecurityScreen> {
  String selectedRole = 'Telecaller';

  @override
  Widget build(BuildContext context) {
    return BrandedScaffold(
      title: 'Click Connect AI CRM',
      showBack: false,
      actions: [IconButton(icon: const Icon(Icons.shield_outlined), onPressed: () {})],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Center(child: IconBadge(icon: Icons.hub_rounded, color: CcColors.blue500, size: 70)),
          const SizedBox(height: 14),
          const Text('Login & Security', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Role based login, secure device binding and app lock.', textAlign: TextAlign.center, style: TextStyle(color: CcColors.textMuted)),
          const SizedBox(height: 20),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select your role', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                RoleSelector(selectedRole: selectedRole, onChanged: (v) => setState(() => selectedRole = v)),
                const SizedBox(height: 16),
                const TextField(decoration: InputDecoration(labelText: 'Email or Mobile Number', prefixIcon: Icon(Icons.person_outline_rounded))),
                const SizedBox(height: 12),
                const TextField(obscureText: true, decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded), suffixIcon: Icon(Icons.visibility_off_outlined))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(value: true, onChanged: (_) {}),
                    const Text('Remember me', style: TextStyle(color: CcColors.textSoft)),
                    const Spacer(),
                    TextButton(onPressed: () => _showForgotPassword(context), child: const Text('Forgot Password?')),
                  ],
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Login Securely',
                  icon: Icons.login_rounded,
                  onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => CrmShell(role: selectedRole))),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.code_rounded),
                  label: const Text('Login with JWT / API Token'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            gradient: LinearGradient(colors: [CcColors.card.withValues(alpha: .95), CcColors.green.withValues(alpha: .12)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(children: [Icon(Icons.verified_user_rounded, color: CcColors.green), SizedBox(width: 10), Expanded(child: Text('Approved Device', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), CcChip(label: 'Trusted', color: CcColors.green, filled: true)]),
                SizedBox(height: 12),
                KeyValueRow('Device ID', 'AND-8F3A-22B7', icon: Icons.phone_android_rounded),
                KeyValueRow('Policy', 'One employee = one approved device', icon: Icons.policy_rounded),
                KeyValueRow('Unauthorized alert', 'Manager/Admin notified', icon: Icons.warning_amber_rounded, valueColor: CcColors.amber),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: true,
                  onChanged: (_) {},
                  contentPadding: EdgeInsets.zero,
                  title: const Text('App Lock PIN / Biometric', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Fingerprint / Face unlock enabled', style: TextStyle(color: CcColors.textMuted)),
                  secondary: const Icon(Icons.fingerprint_rounded, color: CcColors.blue300),
                ),
                const Divider(color: CcColors.line),
                const KeyValueRow('Session Security', 'Active and encrypted', icon: Icons.enhanced_encryption_rounded, valueColor: CcColors.green),
                const KeyValueRow('Logout', 'Available from Profile', icon: Icons.logout_rounded, valueColor: CcColors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPassword(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CcColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            Text('Forgot Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            SizedBox(height: 12),
            TextField(decoration: InputDecoration(labelText: 'Registered email or mobile', prefixIcon: Icon(Icons.email_outlined))),
            SizedBox(height: 14),
            PrimaryButton(label: 'Send Reset Link', icon: Icons.send_rounded),
          ],
        ),
      ),
    );
  }
}


