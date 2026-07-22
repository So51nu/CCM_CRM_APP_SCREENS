import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CompanionApp());
}

class CompanionApp extends StatelessWidget {
  const CompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRM Call Companion',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        scaffoldBackgroundColor: const Color(0xFFF4F7FB),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const CompanionHomePage(),
    );
  }
}

class CompanionHomePage extends StatefulWidget {
  const CompanionHomePage({super.key});

  @override
  State<CompanionHomePage> createState() => _CompanionHomePageState();
}

class _CompanionHomePageState extends State<CompanionHomePage> {
  static const MethodChannel _channel = MethodChannel('com.clickconnect.crm_companion/call');

  final TextEditingController _crmUrlController = TextEditingController(
    text: 'https://darkslategray-badger-734782.hostingersite.com',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'priya@clickconnectmedia.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'admin123',
  );

  bool _loading = true;
  bool _loggingIn = false;
  bool _loggedIn = false;
  bool _serviceRunning = false;
  bool _autoCallEnabled = true;
  bool _autoRecordingEnabled = true;
  String _status = 'Checking saved login...';
  String _userName = '';
  String _userEmail = '';
  int _userId = 0;
  String _token = '';
  String _lastMessage = '-';
  String _lastRecordingPath = '-';
  String _lastRecordingUrl = '-';
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _loadSavedSession();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _crmUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final crmUrl = prefs.getString('crm_url') ?? _crmUrlController.text.trim();
    final userId = prefs.getInt('user_id') ?? 0;
    final token = prefs.getString('mobile_token') ?? '';
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? _emailController.text.trim();
    final autoCall = prefs.getBool('auto_call_enabled') ?? true;
    final autoRecording = prefs.getBool('auto_recording_enabled') ?? true;

    _crmUrlController.text = crmUrl;
    _emailController.text = email;

    setState(() {
      _userId = userId;
      _token = token;
      _userName = name;
      _userEmail = email;
      _autoCallEnabled = autoCall;
      _autoRecordingEnabled = autoRecording;
      _loggedIn = userId > 0 && token.isNotEmpty;
      _loading = false;
      _status = _loggedIn
          ? 'Logged in. Start service for background auto-call and recording.'
          : 'Please login to connect app with CRM.';
    });

    if (_loggedIn) {
      await _saveSessionToNative(startService: false);
      await _refreshNativeServiceState();
      _startUiStatusTimer();
    }
  }

  String _cleanBaseUrl(String value) {
    var url = value.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('device_id');
    if (id == null || id.isEmpty) {
      id = 'android-${DateTime.now().millisecondsSinceEpoch}-${Platform.localHostname.hashCode.abs()}';
      await prefs.setString('device_id', id);
    }
    return id;
  }

  Future<void> _login() async {
    final crmUrl = _cleanBaseUrl(_crmUrlController.text);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (crmUrl.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('CRM URL, email and password required');
      return;
    }

    setState(() {
      _loggingIn = true;
      _status = 'Logging in...';
    });

    try {
      final response = await http.post(
        Uri.parse('$crmUrl/api/mobile-login.php'),
        body: {
          'email': email,
          'password': password,
          'device_id': await _deviceId(),
          'device_name': Platform.localHostname.isEmpty ? 'Android Phone' : Platform.localHostname,
        },
      ).timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(data['message'] ?? 'Login failed');
      }

      final user = Map<String, dynamic>.from(data['user'] as Map);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('crm_url', crmUrl);
      await prefs.setInt('user_id', int.parse('${user['id']}'));
      await prefs.setString('mobile_token', '${data['token']}');
      await prefs.setString('user_name', '${user['name'] ?? ''}');
      await prefs.setString('user_email', '${user['email'] ?? email}');
      await prefs.setBool('auto_call_enabled', _autoCallEnabled);
      await prefs.setBool('auto_recording_enabled', _autoRecordingEnabled);

      setState(() {
        _loggedIn = true;
        _userId = int.parse('${user['id']}');
        _token = '${data['token']}';
        _userName = '${user['name'] ?? ''}';
        _userEmail = '${user['email'] ?? email}';
        _status = 'Login successful. Requesting phone, mic and call-state permissions...';
      });

      await _requestRequiredPermissions();
      await _saveSessionToNative(startService: true);
      await _startService();
      _startUiStatusTimer();
      _showSnack('Connected successfully');
    } catch (e) {
      setState(() => _status = 'Login failed: $e');
      _showSnack('Login failed: $e');
    } finally {
      if (mounted) {
        setState(() => _loggingIn = false);
      }
    }
  }

  Future<void> _requestRequiredPermissions() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestRequiredPermissions') ?? false;
      if (!granted) {
        _showSnack('Phone/Mic/Call-state permission not fully allowed. Recording or auto-complete may fail.');
      }
    } catch (e) {
      _showSnack('Permission check failed: $e');
    }
  }

  Future<void> _saveSessionToNative({required bool startService}) async {
    try {
      await _channel.invokeMethod('saveSession', {
        'crmUrl': _cleanBaseUrl(_crmUrlController.text),
        'userId': _userId,
        'token': _token,
        'userName': _userName,
        'userEmail': _userEmail,
        'autoCallEnabled': _autoCallEnabled,
        'autoRecordingEnabled': _autoRecordingEnabled,
        'pollingSeconds': 3,
        'maxRecordingMinutes': 30,
        'startService': startService,
      });
    } catch (e) {
      _showSnack('Native session save failed: $e');
    }
  }

  Future<void> _startService() async {
    if (!_loggedIn) return;
    await _requestRequiredPermissions();
    await _saveSessionToNative(startService: false);
    try {
      final started = await _channel.invokeMethod<bool>('startService') ?? false;
      setState(() {
        _serviceRunning = started;
        _status = started
            ? 'Background auto-call + recording service running. Keep notification active.'
            : 'Service not started.';
      });
    } catch (e) {
      setState(() => _status = 'Service start failed: $e');
    }
  }

  Future<void> _stopService() async {
    try {
      await _channel.invokeMethod('stopService');
      setState(() {
        _serviceRunning = false;
        _status = 'Service stopped. Calls will not auto-start.';
      });
    } catch (e) {
      _showSnack('Stop service failed: $e');
    }
  }

  Future<void> _refreshNativeServiceState() async {
    try {
      final running = await _channel.invokeMethod<bool>('isServiceRunning') ?? false;
      final last = await _channel.invokeMethod<String>('lastMessage') ?? '-';
      final recPath = await _channel.invokeMethod<String>('lastRecordingPath') ?? '-';
      final recUrl = await _channel.invokeMethod<String>('lastRecordingUrl') ?? '-';
      setState(() {
        _serviceRunning = running;
        _lastMessage = last;
        _lastRecordingPath = recPath;
        _lastRecordingUrl = recUrl;
      });
    } catch (_) {}
  }

  void _startUiStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshNativeServiceState());
  }

  Future<void> _toggleAutoCall(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_call_enabled', value);
    setState(() => _autoCallEnabled = value);
    await _saveSessionToNative(startService: false);
    try {
      await _channel.invokeMethod('setAutoCallEnabled', {'enabled': value});
    } catch (_) {}
  }

  Future<void> _toggleAutoRecording(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_recording_enabled', value);
    setState(() => _autoRecordingEnabled = value);
    await _saveSessionToNative(startService: false);
    try {
      await _channel.invokeMethod('setAutoRecordingEnabled', {'enabled': value});
    } catch (_) {}
  }

  Future<void> _testApi() async {
    if (!_loggedIn) return;
    final crmUrl = _cleanBaseUrl(_crmUrlController.text);
    setState(() => _status = 'Testing pending-call API...');
    try {
      final response = await http.get(
        Uri.parse('$crmUrl/api/get-call-request.php?user_id=$_userId&token=$_token'),
        headers: {'X-Mobile-Token': _token},
      ).timeout(const Duration(seconds: 15));
      setState(() {
        _status = 'API test: HTTP ${response.statusCode}';
        _lastMessage = response.body.length > 300 ? '${response.body.substring(0, 300)}...' : response.body;
      });
    } catch (e) {
      setState(() => _status = 'API test failed: $e');
    }
  }

  Future<void> _manualTestCall() async {
    const phone = '+919999999999';
    try {
      await _requestRequiredPermissions();
      await _channel.invokeMethod('callNow', {'phone': phone, 'requestId': 0});
    } catch (e) {
      _showSnack('Manual call test failed: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await _stopService();
    try {
      final crmUrl = _cleanBaseUrl(_crmUrlController.text);
      if (_token.isNotEmpty && _userId > 0) {
        await http.post(
          Uri.parse('$crmUrl/api/mobile-logout.php'),
          headers: {'X-Mobile-Token': _token},
          body: {'user_id': '$_userId', 'token': _token},
        ).timeout(const Duration(seconds: 10));
      }
    } catch (_) {}
    await prefs.remove('user_id');
    await prefs.remove('mobile_token');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    try { await _channel.invokeMethod('clearSession'); } catch (_) {}
    setState(() {
      _loggedIn = false;
      _userId = 0;
      _token = '';
      _userName = '';
      _userEmail = '';
      _status = 'Logged out';
      _lastMessage = '-';
      _lastRecordingPath = '-';
      _lastRecordingUrl = '-';
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM Call Companion'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshNativeServiceState,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _headerCard(),
              const SizedBox(height: 16),
              if (!_loggedIn) _loginCard() else _connectedCard(),
              const SizedBox(height: 16),
              _statusCard(),
              const SizedBox(height: 16),
              _recordingNoteCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF2563EB)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.phone_in_talk, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Click Connect AI CRM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                    SizedBox(height: 2),
                    Text('Android Companion Auto-Call + Recording', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _serviceRunning ? 'Service Active' : 'Service Inactive',
            style: TextStyle(
              color: _serviceRunning ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Desktop CRM se call button click hote hi app mobile SIM se call trigger karega, call complete hone par status + recording CRM me upload karega.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _loginCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Login / Pair Mobile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(
            controller: _crmUrlController,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'CRM URL', prefixIcon: Icon(Icons.language)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'CRM Email / Username', prefixIcon: Icon(Icons.person)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loggingIn ? null : _login,
            icon: _loggingIn
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.login),
            label: Text(_loggingIn ? 'Connecting...' : 'Login & Start Auto-Call Service'),
          ),
        ],
      ),
    );
  }

  Widget _connectedCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userName.isEmpty ? 'CRM User' : _userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(_userEmail, style: const TextStyle(color: Colors.black54)),
                    Text('User ID: $_userId', style: const TextStyle(color: Colors.black38, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          SwitchListTile(
            value: _autoCallEnabled,
            onChanged: _toggleAutoCall,
            title: const Text('Direct Auto-Call'),
            subtitle: const Text('Pending request milte hi mobile SIM se call start kare'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _autoRecordingEnabled,
            onChanged: _toggleAutoRecording,
            title: const Text('Auto Recording Upload'),
            subtitle: const Text('Call end hone par local recording CRM lead details me upload kare'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _serviceRunning ? null : _startService,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Service'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _serviceRunning ? _stopService : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testApi,
                  icon: const Icon(Icons.api),
                  label: const Text('Test API'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _manualTestCall,
                  icon: const Icon(Icons.call),
                  label: const Text('Test Call'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _statusCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _infoRow('Status', _status),
          const SizedBox(height: 8),
          _infoRow('Last Native Message', _lastMessage),
          const SizedBox(height: 8),
          _infoRow('Last Recording Local Path', _lastRecordingPath),
          const SizedBox(height: 8),
          _infoRow('Last Recording CRM URL', _lastRecordingUrl),
          const SizedBox(height: 8),
          _infoRow('CRM URL', _cleanBaseUrl(_crmUrlController.text)),
        ],
      ),
    );
  }

  Widget _recordingNoteCard() {
    return _card(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recording Important Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 8),
          Text(
            'Android normal apps ko system call audio ka full access har phone par nahi deta. Ye app microphone recording use karta hai. Kuch phones par customer side low/blank aa sakti hai. Better result ke liye speaker mode use karo aur phone permission + microphone permission + battery unrestricted rakho.',
            style: TextStyle(height: 1.45, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        SelectableText(value.isEmpty ? '-' : value, style: const TextStyle(fontSize: 14, height: 1.35)),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: child,
    );
  }
}
