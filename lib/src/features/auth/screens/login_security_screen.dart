part of '../../../../click_connect_ai_crm_ui.dart';

class LoginSecurityScreen extends StatefulWidget {
  const LoginSecurityScreen({super.key});

  @override
  State<LoginSecurityScreen> createState() => _LoginSecurityScreenState();
}

class _LoginSecurityScreenState extends State<LoginSecurityScreen> {
  final _baseUrlController = TextEditingController(text: ApiConfig.defaultBaseUrl);
  final _emailController = TextEditingController(text: 'ravi@clickconnectmedia.com');
  final _passwordController = TextEditingController(text: 'tele123');
  String selectedRole = 'Telecaller';
  bool remember = true;
  bool obscure = true;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = CrmScope.of(context);
    return BrandedScaffold(
      title: 'Click Connect AI CRM',
      showBack: false,
      actions: [IconButton(icon: const Icon(Icons.shield_outlined), onPressed: () {})],
      child: AnimatedBuilder(
        animation: app,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            Center(child: IconBadge(icon: Icons.hub_rounded, color: CcColors.blue500, size: 70)),
            const SizedBox(height: 14),
            const Text('Login & Security', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('API login, role access, device binding and native calling service.', textAlign: TextAlign.center, style: TextStyle(color: CcColors.textMuted)),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select your role', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  RoleSelector(selectedRole: selectedRole, onChanged: (v) => setState(() => selectedRole = v)),
                  const SizedBox(height: 16),
                  TextField(controller: _baseUrlController, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'CRM Base URL', prefixIcon: Icon(Icons.language_rounded))),
                  const SizedBox(height: 12),
                  TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email or Mobile Number', prefixIcon: Icon(Icons.person_outline_rounded))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => obscure = !obscure)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(value: remember, onChanged: (v) => setState(() => remember = v ?? true)),
                      const Text('Remember me', style: TextStyle(color: CcColors.textSoft)),
                      const Spacer(),
                      TextButton(onPressed: () => _showForgotPassword(context), child: const Text('Forgot Password?')),
                    ],
                  ),
                  if (app.error != null) ...[
                    const SizedBox(height: 8),
                    Text(app.error!, style: const TextStyle(color: CcColors.red, height: 1.35)),
                  ],
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: app.loading ? 'Connecting...' : 'Login & Start Service',
                    icon: app.loading ? Icons.sync_rounded : Icons.login_rounded,
                    onPressed: app.loading ? null : () => _login(context),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: app.loading ? null : () => _healthCheck(context),
                    icon: const Icon(Icons.health_and_safety_rounded),
                    label: const Text('Test API Health'),
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
                children: [
                  const Row(children: [Icon(Icons.verified_user_rounded, color: CcColors.green), SizedBox(width: 10), Expanded(child: Text('Device Binding Ready', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16))), CcChip(label: 'Protected', color: CcColors.green, filled: true)]),
                  const SizedBox(height: 12),
                  FutureBuilder<String>(future: SessionStore().getOrCreateDeviceId(), builder: (_, snap) => KeyValueRow('Device ID', snap.data ?? 'Loading...', icon: Icons.phone_android_rounded)),
                  const KeyValueRow('Policy', 'One employee = one approved device', icon: Icons.policy_rounded),
                  const KeyValueRow('Unauthorized alert', 'CRM can block/alert unknown device', icon: Icons.warning_amber_rounded, valueColor: CcColors.amber),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                children: const [
                  KeyValueRow('Backend URL File', 'lib/src/core/api/api_config.dart', icon: Icons.link_rounded, valueColor: CcColors.blue300),
                  KeyValueRow('Login API', '/api/mobile-login.php', icon: Icons.api_rounded),
                  KeyValueRow('Calling Service', 'Starts after login, also available in Calling tab', icon: Icons.phone_in_talk_rounded, valueColor: CcColors.green),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    final app = CrmScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await app.login(
        crmUrl: _baseUrlController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: selectedRole,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Login successful')));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  Future<void> _healthCheck(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await const ApiClient().getJson(ApiConfig.normalizeBaseUrl(_baseUrlController.text), ApiConfig.health);
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('API OK: ${data['message'] ?? 'health success'}')));
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('API Health failed: $e')));
    }
  }

  void _showForgotPassword(BuildContext context) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: CcColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Forgot Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(controller: controller, decoration: const InputDecoration(labelText: 'Registered email or mobile', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 14),
            PrimaryButton(label: 'Send Reset Request', icon: Icons.send_rounded, onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
