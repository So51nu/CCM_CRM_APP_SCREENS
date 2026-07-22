part of '../../../click_connect_ai_crm_ui.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? raw;
  const ApiException(this.message, {this.statusCode, this.raw});

  @override
  String toString() => message;
}

class ApiClient {
  final Duration timeout;
  final int retries;
  const ApiClient({this.timeout = const Duration(seconds: 18), this.retries = 3});

  Future<Map<String, dynamic>> getJson(String baseUrl, String path, {Map<String, dynamic>? query, String? token}) async {
    return _retry(() async {
      final response = await http
          .get(
            ApiConfig.uri(baseUrl, path, query),
            headers: _headers(token: token),
          )
          .timeout(timeout);
      return _decodeResponse(response);
    });
  }

  Future<Map<String, dynamic>> postJson(String baseUrl, String path, Map<String, dynamic> body, {String? token}) async {
    return _retry(() async {
      final response = await http
          .post(
            ApiConfig.uri(baseUrl, path),
            headers: _headers(token: token, json: true),
            body: jsonEncode(body),
          )
          .timeout(timeout);
      return _decodeResponse(response);
    });
  }

  Future<Map<String, dynamic>> postForm(String baseUrl, String path, Map<String, dynamic> body, {String? token}) async {
    return _retry(() async {
      final response = await http
          .post(
            ApiConfig.uri(baseUrl, path),
            headers: _headers(token: token),
            body: body.map((key, value) => MapEntry(key, '$value')),
          )
          .timeout(timeout);
      return _decodeResponse(response);
    });
  }

  Future<T> _retry<T>(Future<T> Function() action) async {
    Object? lastError;
    for (var attempt = 1; attempt <= retries; attempt++) {
      try {
        return await action();
      } on SocketException catch (e) {
        lastError = e;
      } on TimeoutException catch (e) {
        lastError = e;
      } on HttpException catch (e) {
        lastError = e;
      }
      if (attempt < retries) {
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    if (lastError is SocketException) {
      throw ApiException('Network/DNS issue. Internet ya DNS check karo. App ne data local pending sync me save kar diya hai. Details: ${lastError.message}', raw: lastError);
    }
    if (lastError is TimeoutException) {
      throw ApiException('Network timeout. App ne data local pending sync me save kar diya hai.', raw: lastError);
    }
    throw lastError ?? const ApiException('Network request failed');
  }

  Map<String, String> _headers({String? token, bool json = false}) {
    return <String, String>{
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'X-Mobile-Token': token,
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Invalid API response. HTTP ${response.statusCode}: ${response.body.length > 180 ? response.body.substring(0, 180) : response.body}',
        statusCode: response.statusCode,
        raw: response.body,
      );
    }

    final map = decoded is Map<String, dynamic>
        ? decoded
        : decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{'data': decoded};

    final success = map['success'];
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (!ok || success == false || map['error'] == true) {
      throw ApiException('${map['message'] ?? map['error_message'] ?? 'API request failed'}', statusCode: response.statusCode, raw: map);
    }
    return map;
  }
}
