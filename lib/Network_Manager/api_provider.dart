import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart' hide Response;
import 'package:http/http.dart' as http;
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Views/SettingScreen/setting_controller.dart';
import 'api_constains.dart';

class ApiProvider {
  static bool _handlingSessionExpiry = false;

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = (await UserPreference.getToken())?.trim();
    log('📦 token being sent => $token');

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static void _handleUnauthorized(http.Response response) {
    if (response.statusCode == 401 && !_handlingSessionExpiry) {
      _handlingSessionExpiry = true;
      log('🔒 401 Unauthorized — clearing all session data');
      // Use the same cleanup as voluntary logout
      SettingController.cleanupAllSessionData().then((_) {
        Get.offAllNamed(Routes.loginScreen);
        // Re-open the gate only after the in-flight burst of 401s has drained.
        // A screen often fires several auth'd requests at once; without this
        // delay, a late 401 from the same expiry would re-run cleanup
        // (Get.deleteAll) and nuke the freshly-created login screen.
        Future.delayed(const Duration(seconds: 2), () {
          _handlingSessionExpiry = false;
        });
      });
    }
  }

  static Future<http.Response> post({
    required String endpoint,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse(ApiConstants.baseUrl + endpoint);
    return await http.post(
      url,
      headers: headers ?? {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> authPost({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    final url = Uri.parse(ApiConstants.baseUrl + endpoint);
    final headers = await _getAuthHeaders();
    final response = await http.post(url, headers: headers, body: jsonEncode(body));
    _handleUnauthorized(response);
    return response;
  }

  static Future<http.Response> authGet({required String endpoint}) async {
    final url = Uri.parse(ApiConstants.baseUrl + endpoint);
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    _handleUnauthorized(response);
    return response;
  }

  static Future<http.Response> authDelete({required String endpoint}) async {
    final url = Uri.parse(ApiConstants.baseUrl + endpoint);
    final headers = await _getAuthHeaders();
    final response = await http.delete(url, headers: headers);
    _handleUnauthorized(response);
    return response;
  }

   static Future<http.Response> authPut({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    final url = Uri.parse(ApiConstants.baseUrl + endpoint);
    final headers = await _getAuthHeaders();
    final response = await http.put(url, headers: headers, body: jsonEncode(body));
    _handleUnauthorized(response);
    return response;
  }

  //   static Future<http.Response> post({
  //   required String endpoint,
  //   required Map<String, dynamic> body,
  //   Map<String, String>? headers,
  // }) async {
  //   final url = Uri.parse(ApiConstants.baseUrl + endpoint);
  //   final response = await http.post(
  //     url,
  //     headers: headers ?? {'Content-Type': 'application/json'},
  //     body: jsonEncode(body),
  //   );

  //   if (response.statusCode != 200) {
  //     throw Exception('POST request failed: ${response.statusCode} - ${response.body}');
  //   }

  //   return response;
  // }

  // static Future<http.Response> authPost({
  //   required String endpoint,
  //   required Map<String, dynamic> body,
  // }) async {
  //   final url = Uri.parse(ApiConstants.baseUrl + endpoint);
  //   final headers = await _getAuthHeaders();
  //   final response = await http.post(
  //     url,
  //     headers: headers,
  //     body: jsonEncode(body),
  //   );

  //   if (response.statusCode != 200) {
  //     throw Exception('Auth POST failed: ${response.statusCode} - ${response.body}');
  //   }

  //   return response;
  // }

  // static Future<http.Response> authGet({required String endpoint}) async {
  //   final url = Uri.parse(ApiConstants.baseUrl + endpoint);
  //   final headers = await _getAuthHeaders();
  //   final response = await http.get(url, headers: headers);

  //   if (response.statusCode != 200) {
  //     throw Exception('Auth GET failed: ${response.statusCode} - ${response.body}');
  //   }

  //   return response;
  // }

  // static Future<http.Response> authDelete({required String endpoint}) async {
  //   final url = Uri.parse(ApiConstants.baseUrl + endpoint);
  //   final headers = await _getAuthHeaders();
  //   final response = await http.delete(url, headers: headers);

  //   if (response.statusCode != 200) {
  //     throw Exception('Auth DELETE failed: ${response.statusCode} - ${response.body}');
  //   }

  //   return response;
  // }
}
