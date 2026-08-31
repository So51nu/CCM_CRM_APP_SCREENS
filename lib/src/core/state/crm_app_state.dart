part of '../../../click_connect_ai_crm_ui.dart';

class CrmScope extends InheritedNotifier<CrmAppState> {
  const CrmScope({super.key, required CrmAppState state, required super.child}) : super(notifier: state);

  static CrmAppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CrmScope>();
    assert(scope != null, 'CrmScope not found in widget tree');
    return scope!.notifier!;
  }
}

class CrmAppState extends ChangeNotifier {
  final ApiClient api;
  final SessionStore store;
  final NativeCallBridge native;

  CrmAppState({required this.api, required this.store, required this.native});

  bool initialized = false;
  bool loading = false;
  bool apiLoading = false;
  String? error;
  CrmSession? session;
  String baseUrl = ApiConfig.defaultBaseUrl;
  bool serviceRunning = false;
  bool autoCallEnabled = true;
  bool autoRecordingEnabled = true;
  String statusMessage = 'Ready';
  String lastNativeMessage = '-';
  String lastRecordingPath = '-';
  String lastRecordingUrl = '-';
  String lastRecordingFolder = 'Music/ClickConnectCRM/CallRecordings';

  Map<String, dynamic> dashboard = <String, dynamic>{};
  List<Lead> leads = <Lead>[];
  List<Map<String, dynamic>> followups = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> notifications = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> products = <Map<String, dynamic>>[];
  Map<int, Map<String, dynamic>> leadDetails = <int, Map<String, dynamic>>{};

  Timer? _nativeStatusTimer;
  Timer? _autoServiceTimer;
  Timer? _webCallWatcherTimer;
  Timer? _feedbackSyncTimer;
  bool _checkingWebCall = false;
  bool _permissionsRequested = false;
  int activeCallRequestId = 0;
  Map<String, dynamic>? activeCallRequest;
  Map<String, dynamic>? pendingFeedback;
  int pendingFeedbackSerial = 0;
  String _lastPendingFeedbackEventId = '';
  String webCallSyncStatus = 'No web call request received yet';
  int feedbackQueueCount = 0;

  bool get isLoggedIn => session?.isValid == true;
  bool get isManager => (session?.role.toLowerCase().contains('manager') ?? false) || (session?.role.toLowerCase().contains('director') ?? false);
  String get role => session?.role ?? 'Telecaller';
  String get userName => session?.userName.isNotEmpty == true ? session!.userName : 'CRM User';
  String get userEmail => session?.userEmail ?? '';
  int get userId => session?.userId ?? 0;
  String get token => session?.token ?? '';
  String get deviceId => session?.deviceId ?? '-';

  Future<void> init() async {
    initialized = false;
    notifyListeners();
    baseUrl = ApiConfig.normalizeBaseUrl(baseUrl);
    autoCallEnabled = await store.getAutoCall();
    autoRecordingEnabled = await store.getAutoRecording();
    feedbackQueueCount = 0;
    session = await store.loadSession();
    if (session != null) baseUrl = session!.baseUrl;
    initialized = true;
    notifyListeners();
    if (session != null) {
      await ensureRealtimeCallSync(reason: 'saved_login_restore');
      _startCallingWatchers();
      statusMessage = serviceRunning
          ? 'Saved login restored. Real-time web calling sync is active.'
          : 'Saved login restored. Calling service could not auto-start. Open Calling tab and tap Start Service.';
      await refreshNativeStatus();
      unawaited(refreshAll());
      _startFeedbackQueueTimer();
    }
  }

  Future<void> login({required String crmUrl, required String email, required String password, required String role}) async {
    loading = true;
    error = null;
    statusMessage = 'Logging in...';
    notifyListeners();
    try {
      baseUrl = ApiConfig.normalizeBaseUrl(crmUrl);
      final device = await store.getOrCreateDeviceId();
      final deviceName = await store.getDeviceName();
      final payload = <String, dynamic>{
        'email': email.trim(),
        'password': password,
        'device_id': device,
        'device_name': deviceName,
      };

      Map<String, dynamic> data;
      try {
        data = await api.postJson(baseUrl, ApiConfig.login, payload);
      } catch (_) {
        data = await api.postForm(baseUrl, ApiConfig.login, payload);
      }

      final userMap = _asMap(data['user'] ?? data['data']?['user'] ?? data['employee'] ?? data);
      final id = _int(userMap['id'] ?? userMap['user_id'] ?? data['user_id']);
      final mobileToken = '${data['token'] ?? data['mobile_token'] ?? data['data']?['token'] ?? data['data']?['mobile_token'] ?? ''}';
      if (id <= 0 || mobileToken.isEmpty) {
        throw const ApiException('Login response missing user id or token');
      }
      session = CrmSession(
        baseUrl: baseUrl,
        userId: id,
        token: mobileToken,
        userName: '${userMap['name'] ?? userMap['full_name'] ?? email.split('@').first}',
        userEmail: '${userMap['email'] ?? email}',
        role: _roleFromApi(userMap, role),
        deviceId: device,
        deviceName: deviceName,
      );
      await store.saveSession(session!);
      await ensureRealtimeCallSync(reason: 'login');
      _startCallingWatchers();
      statusMessage = serviceRunning ? 'Login successful. Real-time web calling sync is active.' : 'Login successful. Start calling service from Calling tab.';
      await refreshAll();
      _startFeedbackQueueTimer();
    } catch (e) {
      error = '$e';
      statusMessage = 'Login failed: $e';
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    loading = true;
    notifyListeners();
    final old = session;
    try {
      if (old != null) {
        await api.postJson(old.baseUrl, ApiConfig.logout, {'user_id': old.userId, 'token': old.token}, token: old.token).catchError((_) => <String, dynamic>{});
      }
      _stopCallingWatchers();
      await native.stopService();
      await native.clearSession();
      await store.clearSession();
      session = null;
      activeCallRequestId = 0;
      activeCallRequest = null;
      pendingFeedback = null;
      pendingFeedbackSerial = 0;
      feedbackQueueCount = 0;
      _lastPendingFeedbackEventId = '';
      webCallSyncStatus = 'Logged out';
      dashboard.clear();
      leads.clear();
      followups.clear();
      notifications.clear();
      products.clear();
      serviceRunning = false;
      statusMessage = 'Logged out';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAll() async {
    if (!isLoggedIn) return;
    await Future.wait([
      refreshDashboard(silent: true),
      refreshLeads(silent: true),
      refreshFollowups(silent: true),
      refreshNotifications(silent: true),
      refreshProducts(silent: true),
    ]);
    notifyListeners();
  }

  Future<void> refreshDashboard({bool silent = false}) async {
    if (!isLoggedIn) return;
    if (!silent) _startApiLoad('Loading dashboard...');
    try {
      final data = await api.getJson(baseUrl, ApiConfig.dashboard, query: session!.authQuery, token: token);
      dashboard = _asMap(data['dashboard'] ?? data['summary'] ?? data['data'] ?? data);
      _mergeDashboardLists(data);
      statusMessage = 'Dashboard synced';
    } catch (e) {
      error = '$e';
      statusMessage = 'Dashboard sync failed: $e';
    } finally {
      if (!silent) _stopApiLoad();
    }
  }

  Future<void> fullSync() async {
    if (!isLoggedIn) return;
    _startApiLoad('Running full sync...');
    try {
      final data = await api.getJson(baseUrl, ApiConfig.sync, query: session!.authQuery, token: token);
      _mergeDashboardLists(data);
      final leadList = _firstList(data, ['leads', 'assigned_leads', 'data.leads']);
      if (leadList.isNotEmpty) leads = leadList.map((e) => Lead.fromJson(_asMap(e))).toList();
      products = _firstList(data, ['products', 'data.products']).map((e) => _asMap(e)).toList();
      followups = _firstList(data, ['followups', 'data.followups']).map((e) => _asMap(e)).toList();
      notifications = _firstList(data, ['notifications', 'data.notifications']).map((e) => _asMap(e)).toList();
      statusMessage = 'Full sync completed';
    } catch (e) {
      error = '$e';
      statusMessage = 'Full sync failed: $e';
    } finally {
      _stopApiLoad();
    }
  }

  Future<void> refreshLeads({bool silent = false}) async {
    if (!isLoggedIn) return;
    if (!silent) _startApiLoad('Loading assigned leads...');
    try {
      final data = await api.getJson(baseUrl, ApiConfig.assignedLeads, query: session!.authQuery, token: token);
      final list = _firstList(data, ['leads', 'assigned_leads', 'data', 'data.leads']);
      leads = list.map((e) => Lead.fromJson(_asMap(e))).toList();
      statusMessage = 'Assigned leads synced';
    } catch (e) {
      error = '$e';
      statusMessage = 'Leads sync failed: $e';
    } finally {
      if (!silent) _stopApiLoad();
    }
  }

  Future<Map<String, dynamic>> fetchLeadDetail(int leadId) async {
    if (!isLoggedIn || leadId <= 0) return <String, dynamic>{};
    final data = await api.getJson(baseUrl, ApiConfig.leadDetail, query: {...session!.authQuery, 'lead_id': leadId}, token: token);
    final detail = _asMap(data['lead'] ?? data['data'] ?? data);
    leadDetails[leadId] = detail;
    notifyListeners();
    return detail;
  }

  Future<void> refreshProducts({bool silent = false}) async {
    if (!isLoggedIn) return;
    try {
      final data = await api.getJson(baseUrl, ApiConfig.products, query: session!.authQuery, token: token);
      products = _firstList(data, ['products', 'data', 'data.products']).map((e) => _asMap(e)).toList();
    } catch (_) {}
  }

  Future<void> refreshFollowups({bool silent = false}) async {
    if (!isLoggedIn) return;
    if (!silent) _startApiLoad('Loading follow-ups...');
    try {
      final data = await api.getJson(baseUrl, ApiConfig.followups, query: session!.authQuery, token: token);
      followups = _firstList(data, ['followups', 'data', 'data.followups']).map((e) => _asMap(e)).toList();
      statusMessage = 'Follow-ups synced';
    } catch (e) {
      error = '$e';
      statusMessage = 'Follow-up sync failed: $e';
    } finally {
      if (!silent) _stopApiLoad();
    }
  }

  Future<void> addFollowup({required int leadId, required String title, required String scheduledAt, String notes = ''}) async {
    if (!isLoggedIn) return;
    _startApiLoad('Creating follow-up...');
    try {
      await api.postJson(baseUrl, ApiConfig.addFollowup, {'user_id': userId, 'token': token, 'lead_id': leadId, 'title': title, 'scheduled_at': scheduledAt, 'notes': notes}, token: token);
      await refreshFollowups(silent: true);
      statusMessage = 'Follow-up created';
    } finally {
      _stopApiLoad();
    }
  }

  Future<void> refreshNotifications({bool silent = false}) async {
    if (!isLoggedIn) return;
    try {
      final data = await api.getJson(baseUrl, ApiConfig.notifications, query: session!.authQuery, token: token);
      notifications = _firstList(data, ['notifications', 'data', 'data.notifications']).map((e) => _asMap(e)).toList();
    } catch (_) {}
  }

  Future<String> getAiSuggestion({required int leadId, required String context}) async {
    if (!isLoggedIn) return 'Login required';
    final data = await api.postJson(baseUrl, ApiConfig.aiSuggestion, {'user_id': userId, 'token': token, 'lead_id': leadId, 'context': context}, token: token);
    final suggestions = data['suggestions'];
    if (suggestions is List && suggestions.isNotEmpty) return suggestions.map((e) => '$e').join('\n');
    return '${data['suggestion'] ?? data['message'] ?? data['data'] ?? 'No suggestion received'}';
  }

  Future<Map<String, dynamic>> getAutoCallFeedback({
    required int leadId,
    required int requestId,
    String duration = '',
    String notes = '',
    String recordingUrl = '',
    bool refreshAi = false,
  }) async {
    if (!isLoggedIn) return <String, dynamic>{};
    final payload = <String, dynamic>{
      'user_id': userId,
      'token': token,
      'lead_id': leadId,
      'request_id': requestId,
      'duration': duration,
      'notes': notes,
      'recording_url': recordingUrl,
      'refresh_ai': refreshAi ? '1' : '0',
    };
    try {
      return await api.postJson(baseUrl, ApiConfig.autoCallFeedback, payload, token: token);
    } catch (_) {
      return await api.postForm(baseUrl, ApiConfig.autoCallFeedback, payload, token: token);
    }
  }

  Future<void> submitFeedback({
    required Lead lead,
    int requestId = 0,
    required String status,
    required String duration,
    required String notes,
    String nextFollowup = '',
    String customerMood = '',
    String leadQuality = '',
    String productInterested = '',
    String budget = '',
    String meetingAt = '',
    String proposalRequired = '',
    String whatsappSend = '',
    String recordingUrl = '',
    String aiSuggestion = '',
  }) async {
    if (!isLoggedIn) return;
    final linkedRequestId = requestId > 0
        ? requestId
        : ((pendingFeedback != null && _int(pendingFeedback?['lead_id']) == lead.id)
            ? _int(pendingFeedback?['request_id'])
            : ((activeCallRequestId > 0 && _int(activeCallRequest?['lead_id']) == lead.id) ? activeCallRequestId : 0));
    final cleanRecordingUrl = recordingUrl.trim().isNotEmpty
        ? recordingUrl.trim()
        : ((pendingFeedback?['recording_url']?.toString().trim().isNotEmpty ?? false)
            ? pendingFeedback!['recording_url'].toString().trim()
            : (lastRecordingUrl.trim().isNotEmpty && lastRecordingUrl != '-' ? lastRecordingUrl.trim() : ''));

    final enrichedNotes = _buildFeedbackNotes(
      notes: notes,
      customerMood: customerMood,
      leadQuality: leadQuality,
      productInterested: productInterested,
      budget: budget,
      meetingAt: meetingAt,
      proposalRequired: proposalRequired,
      whatsappSend: whatsappSend,
      recordingUrl: cleanRecordingUrl,
      aiSuggestion: aiSuggestion,
    );

    final payload = <String, dynamic>{
      'user_id': userId,
      'token': token,
      'lead_id': lead.id,
      'request_id': linkedRequestId,
      'status': status,
      'call_status': status,
      'duration': duration,
      'notes': enrichedNotes,
      'feedback': enrichedNotes,
      'customer_mood': customerMood,
      'lead_quality': leadQuality,
      'product_interested': productInterested,
      'budget': budget,
      'meeting_at': meetingAt,
      'proposal_required': proposalRequired,
      'whatsapp_send': whatsappSend,
      'created_local_at': DateTime.now().toIso8601String(),
    };
    if (nextFollowup.trim().isNotEmpty) payload['next_followup'] = nextFollowup.trim();
    if (cleanRecordingUrl.isNotEmpty && cleanRecordingUrl != '-') payload['recording_url'] = cleanRecordingUrl;

    _startApiLoad('Saving feedback...');
    var syncedNow = false;
    try {
      try {
        await _sendFeedbackPayload(payload);
        syncedNow = true;
        statusMessage = 'Feedback synced with CRM';
      } catch (e) {
        await store.enqueueFeedback(payload);
        feedbackQueueCount = 0;
        statusMessage = 'Feedback saved locally. Network aate hi auto-sync hoga. Pending: $feedbackQueueCount';
        error = null;
      }
      activeCallRequestId = 0;
      activeCallRequest = null;
      pendingFeedback = null;
      await native.clearPendingFeedback();
      if (syncedNow) {
        await refreshDashboard(silent: true);
        await refreshLeads(silent: true);
      }
      _startFeedbackQueueTimer();
    } finally {
      _stopApiLoad();
    }
  }

  Future<void> _sendFeedbackPayload(Map<String, dynamic> payload) async {
    try {
      await api.postJson(baseUrl, ApiConfig.callFeedback, payload, token: token);
    } catch (_) {
      await api.postForm(baseUrl, ApiConfig.callFeedback, payload, token: token);
    }
  }
  void _startFeedbackQueueTimer() {
    // Mobile feedback workflow removed. Feedback is collected only on Web CRM.
    _feedbackSyncTimer?.cancel();
    _feedbackSyncTimer = null;
    feedbackQueueCount = 0;
  }

  Future<void> syncQueuedFeedbacks({bool silent = false}) async {
    // Mobile feedback queue disabled. Web CRM owns post-call feedback.
    await store.saveFeedbackQueue(const <Map<String, dynamic>>[]);
    feedbackQueueCount = 0;
    if (!silent) notifyListeners();
  }

  String _buildFeedbackNotes({
    required String notes,
    required String customerMood,
    required String leadQuality,
    required String productInterested,
    required String budget,
    required String meetingAt,
    required String proposalRequired,
    required String whatsappSend,
    required String recordingUrl,
    required String aiSuggestion,
  }) {
    final lines = <String>[];
    final raw = notes.trim();
    if (raw.isNotEmpty) lines.add(raw);
    void add(String label, String value) {
      final clean = value.trim();
      if (clean.isNotEmpty) lines.add('$label: $clean');
    }
    add('Customer mood', customerMood);
    add('Lead quality', leadQuality);
    add('Product interested', productInterested);
    add('Budget', budget);
    add('Meeting date/time', meetingAt);
    add('Proposal required', proposalRequired);
    add('WhatsApp send', whatsappSend);
    add('Recording URL', recordingUrl);
    add('AI suggestion', aiSuggestion);
    return lines.join('\n');
  }

  Future<void> callLead(Lead lead, {bool alternate = false}) async {
    if (!isLoggedIn) return;
    final phone = alternate ? lead.alternate : lead.mobile;
    await ensureRealtimeCallSync(reason: 'manual_app_call');
    await native.callNow(phone);
    statusMessage = 'Call started for ${lead.name}';
    notifyListeners();
  }

  Future<void> testPendingCallApi() async {
    if (!isLoggedIn) return;
    _startApiLoad('Testing pending-call API...');
    try {
      final data = await api.getJson(baseUrl, ApiConfig.getCallRequest, query: session!.authQuery, token: token);
      lastNativeMessage = jsonEncode(data);
      statusMessage = 'Pending call API working';
    } catch (e) {
      lastNativeMessage = '$e';
      statusMessage = 'Pending call API failed: $e';
    } finally {
      _stopApiLoad();
    }
  }

  Future<void> startCallingService() async {
    if (!isLoggedIn) return;
    await ensureRealtimeCallSync(reason: 'manual_start');
    _startCallingWatchers();
    statusMessage = serviceRunning
        ? 'Calling service running. Web CRM call button will sync in 1-2 seconds.'
        : 'Service not started. Check phone permissions / battery settings.';
    notifyListeners();
  }

  Future<void> stopCallingService() async {
    _stopCallingWatchers();
    await native.stopService();
    serviceRunning = false;
    statusMessage = 'Calling service stopped';
    notifyListeners();
  }

  Future<void> refreshNativeStatus() async {
    final oldService = serviceRunning;
    final oldMessage = lastNativeMessage;
    final oldPath = lastRecordingPath;
    final oldUrl = lastRecordingUrl;
    final oldFolder = lastRecordingFolder;

    serviceRunning = await native.isServiceRunning();
    lastNativeMessage = await native.lastMessage();
    lastRecordingPath = await native.lastRecordingPath();
    lastRecordingUrl = await native.lastRecordingUrl();
    lastRecordingFolder = await native.lastRecordingFolder();
    // Mobile app no longer opens or stores any feedback form.
    pendingFeedback = null;
    pendingFeedbackSerial = 0;
    _lastPendingFeedbackEventId = '';

    final changed = oldService != serviceRunning ||
        oldMessage != lastNativeMessage ||
        oldPath != lastRecordingPath ||
        oldUrl != lastRecordingUrl ||
        oldFolder != lastRecordingFolder;
    if (changed) notifyListeners();
  }

  Future<void> setAutoCall(bool value) async {
    autoCallEnabled = value;
    await store.setAutoCall(value);
    await native.setAutoCallEnabled(value);
    if (value) {
      await ensureRealtimeCallSync(reason: 'auto_call_enabled');
      _startCallingWatchers();
    } else if (session != null) {
      await _syncNativeSession(startService: false);
      _webCallWatcherTimer?.cancel();
    }
    notifyListeners();
  }

  Future<void> setAutoRecording(bool value) async {
    autoRecordingEnabled = value;
    await store.setAutoRecording(value);
    await native.setAutoRecordingEnabled(value);
    if (session != null) await _syncNativeSession(startService: false);
    notifyListeners();
  }


  void _startCallingWatchers() {
    if (!isLoggedIn) return;
    _nativeStatusTimer?.cancel();
    _autoServiceTimer?.cancel();
    _webCallWatcherTimer?.cancel();

    _nativeStatusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isLoggedIn) unawaited(refreshNativeStatus());
    });

    _autoServiceTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!isLoggedIn || !autoCallEnabled) return;
      await ensureRealtimeCallSync(reason: 'watchdog');
    });

    // Real-time sync: keep asking the native foreground service to poll immediately.
    // Native service performs the safe flow: pending -> picked -> SIM call -> recording -> upload -> completed.
    _webCallWatcherTimer = Timer.periodic(const Duration(milliseconds: 350), (_) {
      if (isLoggedIn && autoCallEnabled) unawaited(checkWebCallRequestAndDial());
    });

    unawaited(checkWebCallRequestAndDial(force: true));
    _startFeedbackQueueTimer();
  }

  void _stopCallingWatchers() {
    _nativeStatusTimer?.cancel();
    _autoServiceTimer?.cancel();
    _webCallWatcherTimer?.cancel();
    _feedbackSyncTimer?.cancel();
    _nativeStatusTimer = null;
    _autoServiceTimer = null;
    _webCallWatcherTimer = null;
    _feedbackSyncTimer = null;
  }

  Future<void> checkWebCallRequestAndDial({bool force = false}) async {
    if (!isLoggedIn || _checkingWebCall || (!autoCallEnabled && !force)) return;
    _checkingWebCall = true;
    try {
      // Fast path: only wake native service. Do not hit PHP API from Flutter every 500ms.
      // This removes UI lag and keeps native service as the single caller/recorder owner.
      if (force || !serviceRunning) {
        await ensureRealtimeCallSync(reason: force ? 'force_check' : 'timer_check', notify: false);
      } else {
        await native.checkNow();
      }
      if (force) {
        webCallSyncStatus = 'Real-time sync active. Waiting for web call button...';
        notifyListeners();
      }
    } catch (e) {
      if (force) {
        webCallSyncStatus = 'Web call sync check failed: $e';
        lastNativeMessage = '$e';
        notifyListeners();
      }
    } finally {
      _checkingWebCall = false;
    }
  }

  Future<void> ensureRealtimeCallSync({String reason = 'ensure', bool notify = true}) async {
    if (!isLoggedIn) return;
    if (!_permissionsRequested || reason.contains('login') || reason.contains('manual')) {
      await native.requestRequiredPermissions();
      _permissionsRequested = true;
    }
    await _syncNativeSession(startService: true);
    serviceRunning = await native.isServiceRunning();
    if (!serviceRunning) {
      serviceRunning = await native.startService();
    }
    if (serviceRunning) {
      await native.checkNow();
      webCallSyncStatus = 'Real-time sync active. Last check: $reason';
    } else {
      webCallSyncStatus = 'Native service not running. Allow permissions and disable battery restriction.';
    }
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _stopCallingWatchers();
    super.dispose();
  }

  Future<void> _syncNativeSession({required bool startService}) async {
    final active = session;
    if (active == null) return;
    await native.saveSession(active, autoCallEnabled: autoCallEnabled, autoRecordingEnabled: autoRecordingEnabled, startService: startService);
  }

  void _startApiLoad(String message) {
    apiLoading = true;
    error = null;
    statusMessage = message;
    notifyListeners();
  }

  void _stopApiLoad() {
    apiLoading = false;
    notifyListeners();
  }

  void _mergeDashboardLists(Map<String, dynamic> data) {
    final leadList = _firstList(data, ['leads', 'assigned_leads', 'data.leads', 'data.assigned_leads']);
    if (leadList.isNotEmpty) leads = leadList.map((e) => Lead.fromJson(_asMap(e))).toList();
    final followupList = _firstList(data, ['followups', 'follow_ups', 'data.followups']);
    if (followupList.isNotEmpty) followups = followupList.map((e) => _asMap(e)).toList();
    final notificationList = _firstList(data, ['notifications', 'data.notifications']);
    if (notificationList.isNotEmpty) notifications = notificationList.map((e) => _asMap(e)).toList();
  }

  String _roleFromApi(Map<String, dynamic> user, String selectedRole) {
    final raw = '${user['role'] ?? user['user_role'] ?? user['type'] ?? selectedRole}'.trim();
    if (raw.isEmpty) return selectedRole;
    final low = raw.toLowerCase();
    if (low.contains('manager')) return 'Manager';
    if (low.contains('sales')) return 'Sales Executive';
    if (low.contains('director') || low.contains('admin')) return 'Manager';
    return 'Telecaller';
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> _firstList(Map<String, dynamic> root, List<String> paths) {
  for (final path in paths) {
    dynamic current = root;
    for (final segment in path.split('.')) {
      if (current is Map) {
        current = current[segment];
      } else {
        current = null;
        break;
      }
    }
    if (current is List) return current;
  }
  return const <dynamic>[];
}

int _int(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

double _double(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse('$value') ?? fallback;
}

String _text(dynamic value, [String fallback = '-']) {
  final text = '${value ?? ''}'.trim();
  return text.isEmpty || text == 'null' ? fallback : text;
}

String _initial(String value) {
  final text = value.trim();
  if (text.isEmpty) return 'C';
  return text.substring(0, 1).toUpperCase();
}

String _prettyDate(dynamic value) {
  final text = _text(value, 'Not set');
  return text;
}

String _dashboardValue(Map<String, dynamic> data, List<String> keys, String fallback) {
  for (final key in keys) {
    if (data.containsKey(key) && '${data[key]}'.trim().isNotEmpty && data[key] != null) return '${data[key]}';
  }
  return fallback;
}
