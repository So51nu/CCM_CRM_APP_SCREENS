part of '../../../click_connect_ai_crm_ui.dart';

class ApiConfig {
  static const String defaultBaseUrl = 'https://test.clickconnectmedia.cloud';

  static String normalizeBaseUrl(String value) {
    var url = value.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.isEmpty) return defaultBaseUrl;
    return url;
  }

  static Uri uri(String baseUrl, String path, [Map<String, dynamic>? query]) {
    final normalized = normalizeBaseUrl(baseUrl);
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final params = <String, String>{};
    query?.forEach((key, value) {
      if (value != null && '$value'.isNotEmpty) params[key] = '$value';
    });
    return Uri.parse('$normalized$cleanPath').replace(queryParameters: params.isEmpty ? null : params);
  }

  static const String health = '/api/api-test.php';
  static const String login = '/api/mobile-login.php';
  static const String dashboard = '/api/mobile-dashboard.php';
  static const String sync = '/api/sync.php';
  static const String assignedLeads = '/api/assigned-leads.php';
  static const String leadDetail = '/api/lead-detail.php';
  static const String products = '/api/products.php';
  static const String getCallRequest = '/api/get-call-request.php';
  static const String updateCallRequest = '/api/update-call-request.php';
  static const String uploadCallRecording = '/api/upload-call-recording.php';
  static const String callFeedback = '/api/call-feedback.php';
  static const String autoCallFeedback = '/api/auto-call-feedback.php';
  static const String followups = '/api/followups.php';
  static const String addFollowup = '/api/add-followup.php';
  static const String updateFollowup = '/api/update-followup.php';
  static const String aiSuggestion = '/api/ai-suggestion.php';
  static const String notifications = '/api/notifications.php';
  static const String mobileSettings = '/api/mobile-settings.php';
  static const String logout = '/api/mobile-logout.php';
}
