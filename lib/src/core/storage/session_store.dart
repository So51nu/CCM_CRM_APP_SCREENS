part of '../../../click_connect_ai_crm_ui.dart';

class CrmSession {
  final String baseUrl;
  final int userId;
  final String token;
  final String userName;
  final String userEmail;
  final String role;
  final String deviceId;
  final String deviceName;

  const CrmSession({
    required this.baseUrl,
    required this.userId,
    required this.token,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.deviceId,
    required this.deviceName,
  });

  bool get isValid => userId > 0 && token.isNotEmpty;

  Map<String, dynamic> get authQuery => {'user_id': userId, 'token': token};

  CrmSession copyWith({String? baseUrl, int? userId, String? token, String? userName, String? userEmail, String? role, String? deviceId, String? deviceName}) {
    return CrmSession(
      baseUrl: baseUrl ?? this.baseUrl,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
    );
  }
}

class SessionStore {
  static const _baseUrl = 'crm_url';
  static const _userId = 'user_id';
  static const _token = 'mobile_token';
  static const _userName = 'user_name';
  static const _userEmail = 'user_email';
  static const _role = 'user_role';
  static const _deviceId = 'device_id';
  static const _deviceName = 'device_name';
  static const _autoCall = 'auto_call_enabled';
  static const _autoRecording = 'auto_recording_enabled';
  static const _feedbackQueue = 'pending_feedback_queue';

  Future<CrmSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userId) ?? 0;
    final token = prefs.getString(_token) ?? '';
    if (userId <= 0 || token.isEmpty) return null;
    final deviceId = await getOrCreateDeviceId();
    return CrmSession(
      baseUrl: ApiConfig.normalizeBaseUrl(prefs.getString(_baseUrl) ?? ApiConfig.defaultBaseUrl),
      userId: userId,
      token: token,
      userName: prefs.getString(_userName) ?? 'CRM User',
      userEmail: prefs.getString(_userEmail) ?? '',
      role: prefs.getString(_role) ?? 'Telecaller',
      deviceId: deviceId,
      deviceName: prefs.getString(_deviceName) ?? _defaultDeviceName(),
    );
  }

  Future<void> saveSession(CrmSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrl, ApiConfig.normalizeBaseUrl(session.baseUrl));
    await prefs.setInt(_userId, session.userId);
    await prefs.setString(_token, session.token);
    await prefs.setString(_userName, session.userName);
    await prefs.setString(_userEmail, session.userEmail);
    await prefs.setString(_role, session.role);
    await prefs.setString(_deviceId, session.deviceId);
    await prefs.setString(_deviceName, session.deviceName);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userId);
    await prefs.remove(_token);
    await prefs.remove(_userName);
    await prefs.remove(_userEmail);
    await prefs.remove(_role);
    await prefs.remove(_feedbackQueue);
  }

  Future<String> getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_deviceId);
    if (id == null || id.isEmpty) {
      id = 'ANDROID-${DateTime.now().millisecondsSinceEpoch}-${Platform.localHostname.hashCode.abs()}';
      await prefs.setString(_deviceId, id);
    }
    return id;
  }

  Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceName) ?? _defaultDeviceName();
  }

  Future<bool> getAutoCall() async => (await SharedPreferences.getInstance()).getBool(_autoCall) ?? true;
  Future<bool> getAutoRecording() async => (await SharedPreferences.getInstance()).getBool(_autoRecording) ?? true;
  Future<void> setAutoCall(bool value) async => (await SharedPreferences.getInstance()).setBool(_autoCall, value);
  Future<void> setAutoRecording(bool value) async => (await SharedPreferences.getInstance()).setBool(_autoRecording, value);

  Future<List<Map<String, dynamic>>> loadFeedbackQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_feedbackQueue) ?? const <String>[];
    final rows = <Map<String, dynamic>>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map) rows.add(Map<String, dynamic>.from(decoded));
      } catch (_) {}
    }
    return rows;
  }

  Future<void> saveFeedbackQueue(List<Map<String, dynamic>> queue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_feedbackQueue, queue.map((e) => jsonEncode(e)).toList());
  }

  Future<void> enqueueFeedback(Map<String, dynamic> payload) async {
    final queue = await loadFeedbackQueue();
    final requestId = _int(payload['request_id']);
    final leadId = _int(payload['lead_id']);
    queue.removeWhere((item) => requestId > 0
        ? _int(item['request_id']) == requestId
        : (leadId > 0 && _int(item['lead_id']) == leadId && '${item['created_local_at']}' == '${payload['created_local_at']}'));
    queue.add(payload);
    await saveFeedbackQueue(queue);
  }

  Future<int> feedbackQueueCount() async => (await loadFeedbackQueue()).length;

  String _defaultDeviceName() {
    if (Platform.localHostname.isNotEmpty) return Platform.localHostname;
    return 'Android Phone';
  }
}
