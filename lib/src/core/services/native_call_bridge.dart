part of '../../../click_connect_ai_crm_ui.dart';

class NativeCallBridge {
  static const MethodChannel _channel = MethodChannel('com.clickconnect.crm_companion/call');

  Future<bool> requestRequiredPermissions() async {
    try {
      return await _channel.invokeMethod<bool>('requestRequiredPermissions') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveSession(CrmSession session, {required bool autoCallEnabled, required bool autoRecordingEnabled, bool startService = false}) async {
    await _channel.invokeMethod('saveSession', {
      'crmUrl': ApiConfig.normalizeBaseUrl(session.baseUrl),
      'userId': session.userId,
      'token': session.token,
      'userName': session.userName,
      'userEmail': session.userEmail,
      'autoCallEnabled': autoCallEnabled,
      'autoRecordingEnabled': autoRecordingEnabled,
      'pollingSeconds': 1,
      'maxRecordingMinutes': 30,
      'speakerCaptureMode': true,
      'startService': startService,
    });
  }

  Future<bool> startService() async {
    try {
      return await _channel.invokeMethod<bool>('startService') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> stopService() async {
    try {
      await _channel.invokeMethod('stopService');
    } catch (_) {}
  }

  Future<bool> isServiceRunning() async {
    try {
      return await _channel.invokeMethod<bool>('isServiceRunning') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String> lastMessage() async {
    try {
      return await _channel.invokeMethod<String>('lastMessage') ?? '-';
    } catch (_) {
      return '-';
    }
  }

  Future<String> lastRecordingPath() async {
    try {
      return await _channel.invokeMethod<String>('lastRecordingPath') ?? '-';
    } catch (_) {
      return '-';
    }
  }

  Future<String> lastRecordingUrl() async {
    try {
      return await _channel.invokeMethod<String>('lastRecordingUrl') ?? '-';
    } catch (_) {
      return '-';
    }
  }

  Future<String> lastRecordingFolder() async {
    try {
      return await _channel.invokeMethod<String>('lastRecordingFolder') ?? 'Music/ClickConnectCRM/CallRecordings';
    } catch (_) {
      return 'Music/ClickConnectCRM/CallRecordings';
    }
  }

  Future<Map<String, dynamic>> ensureRecordingFolder() async {
    try {
      final result = await _channel.invokeMethod<dynamic>('ensureRecordingFolder');
      if (result is Map) return Map<String, dynamic>.from(result);
    } catch (_) {}
    return <String, dynamic>{'ready': false, 'path': 'Music/ClickConnectCRM/CallRecordings'};
  }

  Future<void> setAutoCallEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setAutoCallEnabled', {'enabled': enabled});
    } catch (_) {}
  }

  Future<void> setAutoRecordingEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod('setAutoRecordingEnabled', {'enabled': enabled});
    } catch (_) {}
  }

  Future<void> setSpeakerCaptureMode(bool enabled) async {
    try {
      await _channel.invokeMethod('setSpeakerCaptureMode', {'enabled': enabled});
    } catch (_) {}
  }

  Future<void> clearSession() async {
    try {
      await _channel.invokeMethod('clearSession');
    } catch (_) {}
  }

  Future<void> callNow(String phone, {int requestId = 0}) async {
    await requestRequiredPermissions();
    await _channel.invokeMethod('callNow', {'phone': phone, 'requestId': requestId});
  }

  Future<void> checkNow() async {
    try {
      await _channel.invokeMethod('checkNow');
    } catch (_) {}
  }
  Future<Map<String, dynamic>?> pendingFeedback() async {
    // Mobile feedback removed: Web CRM handles all post-call feedback.
    return null;
  }

  Future<void> clearPendingFeedback() async {
    try {
      await _channel.invokeMethod('clearPendingFeedback');
    } catch (_) {}
  }

  Future<void> openBatterySettings() async {
    try {
      await _channel.invokeMethod('openBatterySettings');
    } catch (_) {}
  }
}
