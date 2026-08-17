import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import 'package:outspot/Model/friendLocation.dart';
import 'package:outspot/Model/inventory_model.dart';
import 'package:outspot/Model/lockerItem_model.dart';
import 'package:outspot/Model/resturant_model.dart';
import 'package:outspot/Model/savedStory_model.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:http/http.dart' as http;
import 'package:outspot/Network_Manager/api_provider.dart';
import 'package:outspot/Network_Manager/user_preference.dart';

/// Thrown when a chat-lock password attempt is rejected with HTTP 429
/// (too many wrong attempts). [retryAfterSeconds] comes from the `Retry-After`
/// response header (0 when the server didn't send one). See CHAT_LOCK_API.md.
class ChatLockRateLimited implements Exception {
  final int retryAfterSeconds;
  const ChatLockRateLimited(this.retryAfterSeconds);
}

class ApiService {
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = (await UserPreference.getToken())?.trim();
    log('📦 token being sent => $token');

    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> fetchStoriesFeed({
    required String filter,
    String? bucket, // 'friends' | 'community'
    int? communityId, // required when bucket == 'community'
    int? page,
    int pageSize = 20,
  }) {
    final params = <String>['filter=$filter', 'pageSize=$pageSize'];
    if (bucket != null) params.add('bucket=$bucket');
    if (communityId != null) params.add('communityId=$communityId');
    if (page != null) params.add('page=$page');
    return ApiProvider.authGet(
      endpoint: '${ApiConstants.storiesFeed}?${params.join('&')}',
    );
  }

  static Future<http.Response> fetchExplorePosts() {
    return ApiProvider.authGet(endpoint: ApiConstants.explorePosts);
  }

  static Future<http.Response> storiesRemove(int id) {
    return ApiProvider.authDelete(
      endpoint: '${ApiConstants.removeStories}/$id',
    );
  }

  static Future<http.Response> storieSaveVault(Map<String, dynamic> body) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.storieSaveVault,
      body: body,
    );
  }

  static Future<http.Response> storieSaveProfile(Map<String, dynamic> body) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.storieSaveProfile,
      body: body,
    );
  }

  static Future<http.Response> fetchStory() {
    return ApiProvider.authGet(endpoint: ApiConstants.getStories);
  }

  /// Submit-for-points cooldown status. Returns
  /// { canSubmit, retryAfterSeconds, nextAllowedAt, rateLimitMinutes, lastSubmitAt }.
  static Future<http.Response> getSubmitForPointsStatus() {
    return ApiProvider.authGet(
      endpoint: '${ApiConstants.submitPoints}/status',
    );
  }

  static Future<http.Response> submitForPoints({
    required File file,
    required String placeName,
    required String latitude,
    required String longitude,
    String? placeId,
  }) async {
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.submitPoints);
    final token = (await UserPreference.getToken())?.trim();

    final request = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath('media', file.path));
    request.fields['placeName'] = placeName;
    request.fields['latitude'] = latitude;
    request.fields['longitude'] = longitude;
    if (placeId != null && placeId.isNotEmpty) {
      request.fields['placeId'] = placeId;
    }

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  static Future<http.Response> sendCapture({
    required File file,
    required String type,
    List<int>? chatIds, // 👈 made optional
    String? challengeId,
    String? latitude,
    String? longitude,
    bool postToStory = false,
  }) async {
    final url = Uri.parse(ApiConstants.baseUrl + ApiConstants.upload);
    final token = (await UserPreference.getToken())?.trim();

    final request = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath('media', file.path));
    request.fields['type'] = type;
    request.fields['postToStory'] = postToStory.toString();

    // ✅ Add chatId only if available
    if (chatIds != null && chatIds.isNotEmpty) {
      request.fields['chatIds'] = chatIds.join(',');
    }

    if (challengeId != null && challengeId.isNotEmpty) {
      request.fields['challengeId'] = challengeId;
    }
    if (latitude != null && latitude.isNotEmpty) {
      request.fields['latitude'] = latitude;
    }
    if (longitude != null && longitude.isNotEmpty) {
      request.fields['longitude'] = longitude;
    }

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  static Future<http.Response> unblockUser(int id) {
    return ApiProvider.authDelete(endpoint: '${ApiConstants.unblockUser}/$id');
  }

  static Future<http.Response> fetchBlockList() {
    return ApiProvider.authGet(endpoint: ApiConstants.getBlock);
  }

  // 🔐 Authentication
  static Future<http.Response> phoneOtp(Map<String, dynamic> body) {
    return ApiProvider.post(endpoint: ApiConstants.phoneOtp, body: body);
  }

  static Future<http.Response> signUp(Map<String, dynamic> body) {
    return ApiProvider.post(endpoint: ApiConstants.signup, body: body);
  }

  static Future<http.Response> verifyOtp(Map<String, dynamic> body) {
    return ApiProvider.post(endpoint: ApiConstants.verifyOtp, body: body);
  }

  static Future<http.Response> login(Map<String, dynamic> body) {
    return ApiProvider.post(endpoint: ApiConstants.login, body: body);
  }

  static Future<http.Response> resendOtp(Map<String, dynamic> body) {
    return ApiProvider.post(endpoint: ApiConstants.resendOtp, body: body);
  }

  static Future<http.Response> forgotPassword(Map<String, dynamic> body) {
    return ApiProvider.post(endpoint: ApiConstants.forgotpass, body: body);
  }

  static Future<http.Response> resetPassword(Map<String, dynamic> body) {
    return ApiProvider.post(endpoint: ApiConstants.resetPass, body: body);
  }

  static Future<http.Response> updateName(Map<String, dynamic> body) {
    return ApiProvider.authPost(endpoint: ApiConstants.updateName, body: body);
  }

  static Future<http.Response> updateBio(Map<String, dynamic> body) {
    return ApiProvider.authPost(endpoint: ApiConstants.updateBio, body: body);
  }

  static Future<http.Response> updateUsername(Map<String, dynamic> body) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.updateUsername,
      body: body,
    );
  }

  static Future<http.Response> updatePassword(Map<String, dynamic> body) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.updatePassword,
      body: body,
    );
  }

  static Future<http.Response> fetchUserProfile() {
    return ApiProvider.authGet(endpoint: ApiConstants.userProfile);
  }

  static Future<http.Response> sendContactMessage(Map<String, dynamic> body) {
    return ApiProvider.authPost(endpoint: ApiConstants.contactUs, body: body);
  }

  static Future<http.Response> logout() {
    return ApiProvider.authPost(endpoint: ApiConstants.logOut, body: {});
  }

  static Future<http.Response> deleteAccount() {
    return ApiProvider.authDelete(endpoint: ApiConstants.deleteaccount);
  }

  // ApiService.dart
  static Future<http.Response> fetchFriendList() {
    return ApiProvider.authGet(endpoint: ApiConstants.friendS);
  }

  // ApiService.dart
  // ApiService.dart
  static Future<http.Response> getPoints(int userId) {
    final endpoint = '${ApiConstants.points}/$userId';
    log("Fetching points from URL: $endpoint");

    return ApiProvider.authGet(endpoint: endpoint);
  }

  static Future<http.Response> getMinimeForLocker() {
    return ApiProvider.authGet(endpoint: ApiConstants.minimeLocker);
  }

  // ApiService.dart
  /// 🔹 Set profile privacy
  static Future<http.Response> setProfilePrivacy(bool isPrivate) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.setProfilePrivacy,
      body: {
        "isPrivate": isPrivate, // true বা false
      },
    );
  }

  // 🔹 Recommended Friends API
  static Future<http.Response> fetchRecommendedFriends() {
    return ApiProvider.authGet(endpoint: ApiConstants.recommendedFriends);
  }

  // ApiService.dart
  static Future<http.Response> searchUsers(String query) {
    return ApiProvider.authGet(
      endpoint: "${ApiConstants.searchFriends}?q=$query",
    );
  }

  static Future<http.Response> sendFriendRequest(int id) {
    return ApiProvider.authPost(
      endpoint: '${ApiConstants.sendFriendRequest}/$id',
      body: {},
    );
  }

  static Future<http.Response> unfriendUser(int friendId) {
    return ApiProvider.authDelete(
      endpoint: '${ApiConstants.unfriend}/$friendId',
    );
  }

  static Future<http.Response> acceptFriendRequest(int id) {
    return ApiProvider.authPost(
      endpoint: '${ApiConstants.acceptFriendRequest}/$id',
      body: {},
    );
  }

  static Future<http.Response> incomingFriendRequestsList() {
    return ApiProvider.authGet(
      endpoint: ApiConstants.IncomingFriendRequestsList,
    );
  }

  // Decline / Cancel Friend Request
  static Future<http.Response> declineFriendRequest(int id) {
    return ApiProvider.authPost(
      endpoint: '${ApiConstants.declineRequest}/$id',
      body: {},
    );
  }

  // Cancel an outgoing (sent, not-yet-accepted) friend request.
  // Backend route is POST /friends/decline/:userId — the same handler cancels a
  // sent request OR declines a received one (it deletes the PENDING friendship
  // in either direction). There is no DELETE on this path, so authPost is used.
  static Future<http.Response> cancelSentRequest(int userId) {
    return ApiProvider.authPost(
      endpoint: '${ApiConstants.declineRequest}/$userId',
      body: {},
    );
  }
  // ApiService.dart

  static Future<http.Response> fetchFriendProfile(int id) {
    return ApiProvider.authGet(endpoint: '${ApiConstants.friendsProfile}/$id');
  }

  static Future<http.Response> blockUser(int id) {
    return ApiProvider.authPost(
      endpoint: '${ApiConstants.blockUser}/$id',
      body: {},
    );
  }

  /// Report a single chat message → moderation queue (OutSpot team).
  /// reason: spam | harassment | nudity | violence | other
  static Future<http.Response> reportMessage({
    required int messageId,
    required String reason,
    String? note,
  }) {
    return ApiProvider.authPost(
      endpoint: '/chats/messages/$messageId/report',
      body: {"reason": reason, if (note != null && note.isNotEmpty) "note": note},
    );
  }

  /// Admin (group admin / community creator) hard-deletes any message.
  /// Server emits `messagesDeleted` to all members.
  static Future<http.Response> adminDeleteMessage(int messageId) {
    return ApiProvider.authPost(
      endpoint: '/chats/messages/$messageId/admin-delete',
      body: {},
    );
  }

  // ── Admin moderation: ban / unban members ──────────────────────────────────

  /// Community creator bans a member.
  static Future<http.Response> banCommunityMember(
    int communityId,
    int userId, {
    String? reason,
  }) {
    return ApiProvider.authPost(
      endpoint: '/communities/$communityId/members/$userId/ban',
      body: {if (reason != null && reason.isNotEmpty) "reason": reason},
    );
  }

  static Future<http.Response> unbanCommunityMember(
    int communityId,
    int userId,
  ) {
    return ApiProvider.authDelete(
      endpoint: '/communities/$communityId/members/$userId/ban',
    );
  }

  /// List the banned members of a community (admin/creator only).
  static Future<http.Response> fetchBannedCommunityMembers(int communityId) {
    return ApiProvider.authGet(endpoint: '/communities/$communityId/banned');
  }

  /// Group admin bans a member.
  static Future<http.Response> banGroupMember(
    int chatId,
    int userId, {
    String? reason,
  }) {
    return ApiProvider.authPost(
      endpoint: '/chats/$chatId/members/$userId/ban',
      body: {if (reason != null && reason.isNotEmpty) "reason": reason},
    );
  }

  static Future<http.Response> unbanGroupMember(int chatId, int userId) {
    return ApiProvider.authDelete(
      endpoint: '/chats/$chatId/members/$userId/ban',
    );
  }

  // Saved Stories Get by targetUserId
  static Future<http.Response> fetchSavedStories(int targetUserId) {
    return ApiProvider.authGet(
      endpoint: '${ApiConstants.savedStories}?targetUserId=$targetUserId',
    );
  }

  static Future<http.Response> fetchSavedStoriesforUser() {
    return ApiProvider.authGet(endpoint: '${ApiConstants.savedStories}');
  }

  /// Delete a saved story by its CLONE story id (savedStories[i].story.id).
  /// Backend hard-deletes the story row + its SavedStory link.
  static Future<http.Response> deleteStory(int storyId) {
    return ApiProvider.authDelete(
      endpoint: '${ApiConstants.removeStories}/$storyId',
    );
  }

  static Future<List<SavedStory>> fetchSavedVaultStories(int userId) async {
    final response = await ApiProvider.authGet(
      endpoint: '${ApiConstants.savedVaultStory}?targetUserId=$userId',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['vaultStories'] != null && data['vaultStories'] is List) {
        return (data['vaultStories'] as List)
            .map((item) => SavedStory.fromJson(item))
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception("Failed to fetch vault stories: ${response.statusCode}");
    }
  }

  static Future<http.Response> createCommunity({
    required String name,
    File? imageFile,
    String? description,
    String? bio,
  }) async {
    // Full URL
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.createCommunity}',
    );
    log('🌍 API URL => $url');

    final headers = await _getAuthHeaders();

    // Multipart request
    final req = http.MultipartRequest('POST', url);

    // Add headers
    req.headers.addAll(headers);

    // Add fields
    req.fields['name'] = name;
    if (description != null) req.fields['description'] = description;
    // Optional community bio — only send when provided.
    if (bio != null && bio.isNotEmpty) req.fields['bio'] = bio;
    log('📝 fields => ${req.fields}');

    // Add image if exists
    if (imageFile != null) {
      log('📷 image file path => ${imageFile.path}');
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
    }

    // Send request
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);

    log('📩 response status => ${response.statusCode}');
    log('📩 response body => ${response.body}');

    return response;
  }

  // Get All Communities (Created + Joined)
  static Future<http.Response> myCommunity() {
    return ApiProvider.authGet(endpoint: ApiConstants.myCommunity);
  }

  // // Get All Communities
  // static Future<http.Response> fetchAllCommunities() {
  //   return ApiProvider.authGet(endpoint: ApiConstants.getAllCommunities);
  // }

  static Future<http.Response> fetchAllCommunities({
    int skip = 0,
    int take = 10,
  }) {
    final String endpoint =
        "${ApiConstants.getAllCommunities}?skip=$skip&take=$take";

    return ApiProvider.authGet(endpoint: endpoint);
  }

  static Future<http.Response> updateLocation(Map<String, dynamic> body) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.updateLocation,
      body: body,
    );
  }

  // Get Community Details
  static Future<http.Response> fetchCommunityDetails(int id) {
    return ApiProvider.authGet(
      endpoint: '${ApiConstants.getCommunityDetails}/$id',
    );
  }

  static Future<http.Response> joinCommunity(int communityId) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.joinCommunity,
      body: {"communityId": communityId},
    );
  }

  // Delete Community
  static Future<http.Response> deleteCommunity(int communityId) {
    return ApiProvider.authDelete(
      endpoint: '${ApiConstants.deleteCommunity}/$communityId',
    );
  }

  static Future<http.Response> updateCommunity({
    required int id,
    String? name,
    File? imageFile, // optional image
    String? bio, // optional bio — only sent when non-null
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.editCommunity}/$id',
    );
    final headers = await _getAuthHeaders();

    // যদি image পাঠাতে হয়
    if (imageFile != null) {
      final req = http.MultipartRequest('PUT', url);
      req.headers.addAll(headers);

      if (name != null) req.fields['name'] = name;
      if (bio != null) req.fields['bio'] = bio;

      // Image attach
      req.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final streamed = await req.send();
      final response = await http.Response.fromStream(streamed);
      return response;
    } else {
      // শুধু text update
      return await ApiProvider.authPut(
        endpoint: '${ApiConstants.editCommunity}/$id',
        body: {
          if (name != null) "name": name,
          if (bio != null) "bio": bio,
        },
      );
    }
  }

  /// Leave a community by ID (POST request)
  static Future<http.Response> leaveCommunity(int communityId) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.leaveCommunity,
      body: {"communityId": communityId},
    );
  }

  // Get My Stories
  static Future<http.Response> fetchUserStories() {
    return ApiProvider.authGet(endpoint: ApiConstants.getOwnStory);
  }

  static Future<http.Response> fetchSentFriendRequests() {
    return ApiProvider.authGet(endpoint: ApiConstants.getSentFriendRequests);
  }

  static Future<http.Response> fetchProfileavatar(int userId) {
    return ApiProvider.authGet(
      endpoint: '${ApiConstants.ProfileAvatar}/$userId/profile',
    );
  }

  // 🔹 Recent Community List
  static Future<http.Response> fetchRecentCommunities({
    int skip = 0,
    int take = 50,
  }) {
    return ApiProvider.authGet(
      endpoint: '${ApiConstants.recentCommunities}?skip=$skip&take=$take',
    );
  }

  // 🔹 Community Activity History (joined + left actions)
  static Future<http.Response> fetchCommunityActivity({
    int skip = 0,
    int take = 50,
  }) {
    return ApiProvider.authGet(
      endpoint: '${ApiConstants.communityActivity}?skip=$skip&take=$take',
    );
  }

  static Future<http.Response> getStoriesWithLocation() {
    return ApiProvider.authGet(endpoint: ApiConstants.getStoriesWithLocation);
  }

  // Report Friend
  static Future<http.Response> reportFriend(int reportedId) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.reportFriend,
      body: {"reportedId": reportedId},
    );
  }

  //////////////////////////////////////////////////////////////////////////

  static Future<Map<String, dynamic>> saveProfile({
    required Map<String, dynamic> body,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/save-profile');

    final res = await http.post(
      url,
      headers: await _getAuthHeaders(),
      body: jsonEncode(body),
    );

    log('🔗 POST ${url.path}  ⇢  ${res.statusCode}');
    log('📦 body: ${jsonEncode(body)}');
    log('📦 response: ${res.body}');
    final json = jsonDecode(res.body);

    if (res.statusCode == 200 && json['status'] == true) return json;
    throw Exception(json['message'] ?? 'save‑profile failed');
  }

  static Future<List<Map<String, dynamic>>> getPremades() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/minime/premades');
    final res = await http.get(uri, headers: await _getAuthHeaders());

    log('🔗 GET ${uri.path} ⇢ ${res.statusCode}');
    log('📥 response: ${res.body}');
    final json = jsonDecode(res.body);

    if (res.statusCode == 200 &&
        json['status'] == true &&
        json['data'] is List) {
      return List<Map<String, dynamic>>.from(json['data']);
    }
    throw Exception(json['message'] ?? 'fetch premades failed');
  }

  static Future<Map<String, dynamic>> uploadAvatar({
    File? selfieFile,
    File? avatarFile,
    String? premadeUrl,
    int? premadeId,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/minime/upload-avatar');
    final auth = await _getAuthHeaders();

    http.Response res;

    if (premadeId != null) {
      res = await http.post(
        uri,
        headers: auth,
        body: jsonEncode({'premadeId': premadeId}),
      );
    } else if (premadeUrl != null) {
      res = await http.post(
        uri,
        headers: auth,
        body: jsonEncode({'premadeUrl': premadeUrl}),
      );
    } else {
      final req = http.MultipartRequest('POST', uri);
      req.headers.addAll(auth..remove('Content-Type'));

      if (selfieFile != null) {
        req.files.add(
          await http.MultipartFile.fromPath('selfie', selfieFile.path),
        );
      }
      if (avatarFile != null) {
        req.files.add(
          await http.MultipartFile.fromPath('avatar', avatarFile.path),
        );
      }

      final streamed = await req.send();
      res = await http.Response.fromStream(streamed);
    }

    log('🔗 POST ${uri.path} ⇢ ${res.statusCode}');
    log('📥 response: ${res.body}');
    final json = jsonDecode(res.body);

    if (res.statusCode == 200 && json['status'] == true) return json;
    throw Exception(json['message'] ?? 'upload‑avatar failed');
  }

  static Future<Map<String, dynamic>> setActiveMinime(int minimeId) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/minime/$minimeId/set-active',
    );
    final auth = await _getAuthHeaders();

    final res = await http.post(uri, headers: auth);

    log('🔗 POST ${uri.path} ⇢ ${res.statusCode}');
    log('📥 response: ${res.body}');
    final json = jsonDecode(res.body);

    if (res.statusCode == 200) return json;
    throw Exception(json['message'] ?? 'set-active failed');
  }

  static Future<Map<String, dynamic>> uploadAvatares({
    File? selfieFile,
    String? premadeUrl,
    int? premadeId,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/minime/upload-avatar');
    final auth = await _getAuthHeaders();

    http.Response res;

    if (premadeId != null) {
      res = await http.post(
        uri,
        headers: auth,
        body: jsonEncode({'premadeId': premadeId}),
      );
    } else if (premadeUrl != null) {
      res = await http.post(
        uri,
        headers: auth,
        body: jsonEncode({'premadeUrl': premadeUrl}),
      );
    } else if (selfieFile != null) {
      final req = http.MultipartRequest('POST', uri);
      req.headers.addAll(auth..remove('Content-Type'));

      req.files.add(
        await http.MultipartFile.fromPath('selfie', selfieFile.path),
      );

      final streamed = await req.send();
      res = await http.Response.fromStream(streamed);
    } else {
      throw Exception("No file or premade URL provided");
    }

    log('🔗 POST ${uri.path} ⇢ ${res.statusCode}');
    log('📥 response: ${res.body}');

    final json = jsonDecode(res.body);

    if (res.statusCode == 200 && json['status'] == true) {
      return json;
    } else {
      throw Exception(json['message'] ?? 'upload-avatar failed');
    }
  }

  static Future<List<Map<String, dynamic>>> getBodyShapes() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/body-shapes');
    final res = await http.get(uri, headers: await _getAuthHeaders());

    log('🔗 GET ${uri.path} ⇢ ${res.statusCode}');
    log('📥 response: ${res.body}');
    final json = jsonDecode(res.body);

    if (res.statusCode == 200 &&
        json['status'] == true &&
        json['data'] is List) {
      return List<Map<String, dynamic>>.from(json['data']);
    }
    throw Exception(json['message'] ?? 'fetch body-shapes failed');
  }

  static Future<Map<String, dynamic>> getFreeItems({
    required String gender,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/shop/catalog/free?gender=$gender',
    );
    final res = await http.get(uri, headers: await _getAuthHeaders());

    log('🔗 GET ${uri.path} ⇢ ${res.statusCode}');
    log('📥 response: ${res.body}');
    final json = jsonDecode(res.body);

    if (res.statusCode == 200 && json['success'] == true) {
      return Map<String, dynamic>.from(json['data']['grouped'] ?? {});
    }
    throw Exception(json['message'] ?? 'fetch free items failed');
  }

  static Future<Map<String, dynamic>> saveMinimeOptions(
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/minime/generate');
    final res = await http.post(
      uri,
      headers: await _getAuthHeaders(),
      body: jsonEncode(body),
    );

    log('🔗 POST ${uri.path} ⇢ ${res.statusCode}');
    log('📤 body: $body');
    final json = jsonDecode(res.body);
    log('📤 response: $json');

    if (res.statusCode == 200 && json['status'] == true) return json;
    throw Exception(json['message'] ?? 'save‑minime‑options failed');
  }

  static Future<List<Map<String, dynamic>>> getMinimeLocker() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/minime/locker');
    final res = await http.get(uri, headers: await _getAuthHeaders());

    log('🔗 GET ${uri.path} ⇢ ${res.statusCode}');
    log('📥 response: ${res.body}');
    final json = jsonDecode(res.body);

    if (res.statusCode == 200 && json['locker'] is List) {
      return List<Map<String, dynamic>>.from(json['locker']);
    }
    throw Exception(json['message'] ?? 'Failed to fetch locker');
  }

  static Future<Map<String, dynamic>> regenerateMinime(
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/minime/regenerate');

    final res = await http.post(
      uri,
      headers: await _getAuthHeaders(), // Bearer + JSON
      body: jsonEncode(body),
    );

    log('🔗 POST ${uri.path} ⇢ ${res.statusCode}');
    log('📤 body: $body');
    final json = jsonDecode(res.body);

    if (res.statusCode == 200 && json['status'] == true) return json;
    throw Exception(json['message'] ?? 'minime‑regenerate failed');
  }

  static Future<Map<String, dynamic>> saveLatestMinime() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/minime/save-latest');

    final res = await http.post(
      uri,
      headers: await _getAuthHeaders(), // Bearer + JSON
    );

    log('🔗 POST ${uri.path} ⇢ ${res.statusCode}');
    final json = jsonDecode(res.body);

    if (res.statusCode == 200 && json['status'] == true) return json;
    throw Exception(json['message'] ?? 'save‑latest‑minime failed');
  }

  static Future<List<Map<String, dynamic>>> getAllChats() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/chats');
    final headers = await _getAuthHeaders();
    final res = await http.get(uri, headers: headers);

    // log('🔗 GET ${uri.path} ⇢ ${res.statusCode}');
    // log('📥 response: ${res.body}');

    final decoded = jsonDecode(res.body);

    if (res.statusCode == 200 && decoded is List) {
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      throw Exception('Invalid chat list response');
    }
  }

  static Future<List<Map<String, dynamic>>> getChatMessages(int chatId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/chats/messages/$chatId');
    final headers = await _getAuthHeaders();

    final res = await http.get(uri, headers: headers);

    // log('🔗 GET ${uri.path} ⇢ ${res.statusCode}');
    // log('📥 response: ${res.body}');

    final decoded = jsonDecode(res.body);

    if (res.statusCode == 200 && decoded is List) {
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      throw Exception('Invalid messages response');
    }
  }

  static Future<String> uploadChatImage({required XFile file}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/chat/upload');
    final req =
        http.MultipartRequest('POST', uri)
          ..files.add(
            await http.MultipartFile.fromPath(
              'image',
              file.path,
              filename: file.name,
            ),
          )
          ..headers.addAll(
            await _getAuthHeaders()
              ..remove('Content-Type'),
          );

    try {
      final res = await http.Response.fromStream(await req.send());

      if (res.statusCode != 200)
        throw Exception('Upload failed: ${res.statusCode}');

      final Map<String, dynamic> b = jsonDecode(res.body);
      String? imageUrl = b['chatImage']?['fileUrl'];

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('No image URL in response');
      }

      if (!imageUrl.startsWith('http')) {
        final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/*$'), '');
        final path = imageUrl.replaceFirst(RegExp(r'^/+'), '');
        imageUrl = '$base/$path';
      }

      return imageUrl;
    } catch (e) {
      log('❌ uploadChatImage failed: $e');
      throw Exception('Image upload failed');
    }
  }

  static Future<Map<String, dynamic>> createChat({
    required List<int> userIds,
    required bool isGroup,
  }) async {
    final url = '${ApiConstants.baseUrl}/chats/create';
    final headers = {
      ...(await _getAuthHeaders()),
      'Content-Type': 'application/json', // ensure JSON
    };

    // Backend expects "UserId": [ ... ]
    final body = jsonEncode({
      'UserId': userIds, // 👈 key changed
      'isGroup': isGroup,
    });

    print('POST URL: $url');
    print('Headers: $headers');
    print('Body: $body');

    try {
      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        throw Exception('Bad request: ${response.body}');
      } else if (response.statusCode == 404) {
        throw Exception('Chat endpoint not found: ${response.body}');
      } else {
        throw Exception(
          'Failed to create chat. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      print('Error creating chat: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserChats({
    required int userId,
  }) async {
    final url = '${ApiConstants.baseUrl}/chats/$userId';
    final headers = await _getAuthHeaders();

    print('GET URL: $url');
    print('Headers: $headers');

    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(Duration(seconds: 30));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to fetch chats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching chats: $e');
    }
  }

  static Future<List<FriendLocation>> fetchFriendsLocation() async {
    try {
      final response = await ApiProvider.authGet(
        endpoint: ApiConstants.getFriendsLocation,
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((friend) => FriendLocation.fromJson(friend)).toList();
      } else {
        throw Exception('Failed to load friend locations');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createGroupChat(
    List<int> userIds,
    String groupName,
    String? imagePath,
  ) async {
    if (groupName.trim().isEmpty) throw Exception('Group name required');
    if (userIds.isEmpty) throw Exception('At least one user required');

    final url = Uri.parse('${ApiConstants.baseUrl}/chats/createGroupChat');
    final headers = await _getAuthHeaders();

    final req = http.MultipartRequest('POST', url);
    req.headers.addAll(headers);

    // Text fields
    req.fields['userIds'] = jsonEncode(userIds);
    req.fields['name'] = groupName.trim();
    req.fields['isGroup'] = 'true'; // অথবা "1"

    // File field – key হবে 'image'
    if (imagePath != null && imagePath.isNotEmpty) {
      req.files.add(await http.MultipartFile.fromPath('image', imagePath));
    }

    final resp = await req.send().timeout(const Duration(seconds: 30));
    final body = await resp.stream.bytesToString();

    if (resp.statusCode != 200) {
      throw Exception('Failed to create group chat: ${resp.statusCode} $body');
    }
    return json.decode(body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> editGroupChat(
    String groupName,
    String? imagePath,
    int groupId,
  ) async {
    if (groupName.trim().isEmpty) throw Exception('Group name required');

    final url = Uri.parse('${ApiConstants.baseUrl}/chats/$groupId');
    final headers = await _getAuthHeaders();
    final req = http.MultipartRequest('PUT', url)..headers.addAll(headers);

    req.fields['name'] = groupName.trim();
    req.fields['isGroup'] = 'true';

    // Add the image if it's a local file or URL
    if (imagePath?.isNotEmpty ?? false) {
      if (imagePath!.startsWith('http')) {
        req.fields['imageUrl'] = imagePath; // URL image
      } else {
        File file = File(imagePath);
        if (await file.exists()) {
          req.files.add(
            await http.MultipartFile.fromPath('image', imagePath),
          ); // Local file image
        } else {
          throw Exception('Selected image file does not exist');
        }
      }
    }

    try {
      final resp = await req.send().timeout(const Duration(seconds: 30));
      final body = await resp.stream.bytesToString();
      if (resp.statusCode != 200) {
        throw Exception(
          'Failed to update group chat: ${resp.statusCode} $body',
        );
      }
      return json.decode(body);
    } catch (e) {
      log('Error updating group chat: $e');
      throw Exception('Error updating group chat: $e');
    }
  }

  static Future<void> addUsersToGroup(List<int> userIds, int chatId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/addUser/$chatId');
    final headers = await _getAuthHeaders();
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({'userIds': userIds}),
      );

      if (response.statusCode == 200) {
        print('Users added successfully');
      } else {
        print('Failed to add users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> getGroupDetails(int groupId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/chats/groupMembers/$groupId',
    );
    final headers = await _getAuthHeaders();
    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load group details');
      }
    } catch (e) {
      throw Exception('Error fetching group details: $e');
    }
  }

  static Future<Map<String, dynamic>> getCommunityChatId(
    int communityId,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/communities/$communityId/chat-id',
    );

    final headers = await _getAuthHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return data; // Expected: { "chatId": 7 }
      } else {
        throw Exception(
          'Failed to load community chat ID (status: ${response.statusCode})',
        );
      }
    } catch (e) {
      throw Exception('Error fetching community chat ID: $e');
    }
  }

  static Future<http.Response> leaveGroup(int chatId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/leave/$chatId');
    final headers = await _getAuthHeaders();
    return http.delete(url, headers: headers);
  }

  /// Admin-only: remove another user from a group chat.
  /// `DELETE /chats/{chatId}/users/{userId}`
  static Future<http.Response> removeUserFromGroup({
    required int chatId,
    required int userId,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/chats/$chatId/users/$userId',
    );
    final headers = await _getAuthHeaders();
    return http.delete(url, headers: headers);
  }

  static Future<Map<String, dynamic>> getanyUserProfile(int userId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/users/profile/$userId');
    final headers = await _getAuthHeaders();

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data.containsKey('data')) {
          return data['data'];
        } else {
          throw Exception('Failed to fetch user profile: ${data['message']}');
        }
      } else {
        throw Exception('Server error (code: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  static Future<http.Response> fetchNotifications() {
    return ApiProvider.authGet(endpoint: ApiConstants.notification);
  }

  static Future<void> updateFcmToken(String fcmToken) async {
    if (fcmToken.isEmpty) return;

    try {
      final body = {"fcmToken": fcmToken};

      final response = await ApiProvider.authPost(
        endpoint: ApiConstants.updateFcmToken,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log(
          "✅ FCM token updated successfully: ${data['message'] ?? 'Token updated'}",
        );
      } else {
        log(
          "❌ Failed to update FCM token. Status: ${response.statusCode}, Body: ${response.body}",
        );
      }
    } catch (e, st) {
      log("❌ Error updating FCM token: $e\n$st");
    }
  }

  static Future<http.Response> fetchHomeExplore({
    required double lat,
    required double lng,
    required int radius,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.exploreHome}'
      '?lat=$lat&lng=$lng&radius=$radius',
    );

    final headers = await _getAuthHeaders();

    return http.get(uri, headers: headers);
  }

  static Future<http.Response> fetchPlacesByCategory({
    required String categoryKey,
    required double lat,
    required double lng,
    int radius = 16093,
    int page = 1,
    int pageSize = 20,
  }) async {
    final headers = await _getAuthHeaders();

    final url = Uri.parse(
      '${ApiConstants.baseUrl}/explore/category/$categoryKey/places'
      '?lat=$lat&lng=$lng&radius=$radius&page=$page&pageSize=$pageSize',
    );
    log('📡 Fetching places for $categoryKey page=$page (lat=$lat, lng=$lng)');
    return http.get(url, headers: headers);
  }

  static Future<http.Response> searchExplorePlaces({
    required String query,
    required double lat,
    required double lng,
    required String category,
    int radius = 32187,
    int limit = 10,
  }) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/explore/search'
      '?q=${Uri.encodeComponent(query)}'
      '&lat=$lat&lng=$lng'
      '&radius=$radius&limit=$limit'
      '&category=$category',
    );
    log('🔍 Searching places: $query at $lat, $lng (category=$category)');
    return http.get(url, headers: headers);
  }

  static Future<List<Map<String, dynamic>>> getChallengescards() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/challenges/cards');
    final headers = await _getAuthHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final Map<String, dynamic> data = json.decode(response.body);

    return [
      if (data['daily'] is Map<String, dynamic>) data['daily'],
      if (data['weekly'] is Map<String, dynamic>) data['weekly'],
    ];
  }

  /// Challenge history (In Progress / Completed tabs). Returns the full
  /// paginated envelope: { items, total, page, pageSize, hasMore }.
  /// [tab] = 'in_progress' | 'completed'.
  static Future<Map<String, dynamic>> getChallengeHistory({
    required String tab,
    String frequency = 'all',
    int page = 1,
    int pageSize = 20,
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/challenges/history'
      '?tab=$tab&frequency=$frequency&page=$page&pageSize=$pageSize',
    );
    final headers = await _getAuthHeaders();

    final response = await http.get(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {
      'items': const [],
      'total': 0,
      'page': page,
      'pageSize': pageSize,
      'hasMore': false,
    };
  }

  static Future<List<Map<String, dynamic>>> getMySubmissionChallenge(
    int challengeId,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/challenges/$challengeId/my-submission',
    );
    final headers = await _getAuthHeaders();

    final res = await http.get(url, headers: headers);

    if (res.statusCode == 200) {
      final body = res.body.isEmpty ? '{}' : res.body;
      final decoded = json.decode(body);

      // ✅ Extract 'items' from the response
      if (decoded is Map && decoded['items'] is List) {
        return (decoded['items'] as List)
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return <Map<String, dynamic>>[];
    }
    throw Exception('Server error: ${res.statusCode}');
  }

  /// Fetch a page of participants who attempted a challenge.
  ///
  /// Sends `?page=&pageSize=&sort=` (sort = `newest` | `oldest`). The backend
  /// SHOULD order results friends-first → users sharing a community/group →
  /// others, paginate to [pageSize], and return:
  ///   `{ "items": [...], "page": n, "pageSize": s, "total": int, "hasMore": bool }`
  ///
  /// Returns a normalized map: `{ items, hasMore, total, paginated }`.
  /// `paginated` is true when the response carried pagination metadata
  /// (`hasMore`/`total`/`page`); when false the caller treats the response as
  /// the full unpaginated list (current backend) and paginates on the client.
  static Future<Map<String, dynamic>> getOthersSubmissions(
    int challengeId, {
    int page = 1,
    int pageSize = 20,
    String sort = 'newest',
  }) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/challenges/$challengeId/submissions'
      '?page=$page&pageSize=$pageSize&sort=$sort',
    );
    final headers = await _getAuthHeaders();

    final response = await http.get(url, headers: headers);
    final decoded = json.decode(response.body);

    log('getOthersSubmissions type: ${decoded.runtimeType}');

    List<Map<String, dynamic>> items = [];
    bool? hasMore;
    int? total;
    bool paginated = false;

    if (response.statusCode == 200) {
      if (decoded is List) {
        // Plain list (current backend): full, unpaginated.
        items = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } else if (decoded is Map) {
        final root = Map<String, dynamic>.from(decoded);
        // Allow an optional { data: {...} } envelope.
        final body =
            (root['data'] is Map)
                ? Map<String, dynamic>.from(root['data'])
                : root;

        final rawItems = body['items'] ?? root['items'];
        if (rawItems is List) {
          items = rawItems.map((e) => Map<String, dynamic>.from(e)).toList();
        }

        // Any of these present ⇒ the server is paginating/ordering for us.
        final hm = body['hasMore'] ?? root['hasMore'];
        final tot = body['total'] ?? root['total'];
        final pg = body['page'] ?? root['page'];
        if (hm is bool) {
          hasMore = hm;
          paginated = true;
        }
        if (tot != null) {
          total = tot is int ? tot : int.tryParse(tot.toString());
          if (total != null) paginated = true;
        }
        if (pg != null) paginated = true;
      }
    } else {
      log('getOthersSubmissions: status ${response.statusCode}');
    }

    return {
      'items': items,
      'hasMore': hasMore,
      'total': total,
      'paginated': paginated,
    };
  }

  static Future<Map<String, dynamic>> challengeSubmit({
    required int challengeId,
    required String filePath,
  }) async {
    final req =
        http.MultipartRequest(
            'POST',
            Uri.parse('${ApiConstants.baseUrl}/challenges/submit'),
          )
          ..headers.addAll(await _getAuthHeaders())
          ..fields['challengeId'] = '$challengeId'
          ..files.add(await http.MultipartFile.fromPath('media', filePath));

    final res = await http.Response.fromStream(await req.send());

    final d = jsonDecode(res.body);
    final data = d is Map<String, dynamic> ? d : <String, dynamic>{'raw': d};
    data['_statusCode'] = res.statusCode;
    return data;
  }

  // static Future<List<Map<String, dynamic>>>
  // getWeeklyCommunityLeaderboard() async {
  //   final url = Uri.parse(
  //     '${ApiConstants.baseUrl}/leaderboard/weekly/communities',
  //   );
  //   final headers = await _getAuthHeaders();

  //   final res = await http.get(url, headers: headers);
  //   if (res.statusCode != 200) {
  //     throw Exception('Server error: ${res.statusCode}');
  //   }

  //   final decoded = json.decode(res.body);
  //   final data =
  //       decoded is Map<String, dynamic> ? decoded['leaderboard'] : decoded;

  //   if (data is List) {
  //     return data
  //         .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
  //         .toList();
  //   }
  //   throw Exception('Unexpected response type: ${decoded.runtimeType}');
  // }

  static Future<Map<String, dynamic>> getWeeklyCommunityLeaderboard() async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/leaderboard/weekly/communities',
    );
    final headers = await _getAuthHeaders();

    final res = await http.get(url, headers: headers);
    if (res.statusCode != 200) {
      throw Exception('Server error: ${res.statusCode}');
    }

    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) {
      // পুরো JSON object return করছি
      return decoded;
    }

    throw Exception('Unexpected response type: ${decoded.runtimeType}');
  }

  static Future<Map<String, dynamic>> getWeeklyGlobalLeaderboard() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/leaderboard/weekly/global');
    final headers = await _getAuthHeaders();

    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        throw Exception('Expected Map, got ${decoded.runtimeType}');
      }
    }
    throw Exception('Server error: ${res.statusCode}');
  }

  static Future<http.Response> recordVisit({
    required String placeId,
    required String name,
    required double latitude,
    required double longitude,
    required String categoryKey,
    double? accuracy,
    bool? isMocked,
    File? media,
  }) async {
    final url = Uri.parse(ApiConstants.baseUrl + '/explore/visit');
    final token = (await UserPreference.getToken())?.trim();

    // Multipart so the check-in can carry an evidence photo. All values are
    // sent as form fields; the backend coerces them (Number/'true') exactly as
    // it did for the old JSON body, so this stays backward-compatible.
    final request = http.MultipartRequest('POST', url);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['placeId'] = placeId;
    request.fields['name'] = name;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    request.fields['categoryKey'] = categoryKey;
    // GPS quality — so the backend can reject low-accuracy / spoofed submits.
    if (accuracy != null) request.fields['accuracy'] = accuracy.toString();
    if (isMocked != null) request.fields['isMocked'] = isMocked.toString();

    // Evidence photo (the captured check-in image). Optional: video captures /
    // older flows omit it and the server stores an empty mediaUrl.
    if (media != null) {
      request.files.add(await http.MultipartFile.fromPath('media', media.path));
    }

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      log("Response status: ${response.statusCode}");

      return response;
    } catch (e) {
      log("❌ Error sending request: $e");
      throw Exception("Failed to record visit");
    }
  }

  static Future<Map<String, dynamic>> getMyAchievements() async {
    final url = Uri.parse('${ApiConstants.baseUrl}/me/achievements');
    final headers = await _getAuthHeaders();

    final res = await http.get(url, headers: headers);
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Server error: ${res.statusCode}: ${res.body}');
  }

  static Future<http.Response> getFilterNotifications({
    String? read,
    String? type,
  }) {
    final queryParams = <String, String>{};

    if (read != null && read.isNotEmpty) {
      queryParams['read'] = read;
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    String queryString = '';
    if (queryParams.isNotEmpty) {
      queryString = '?' + Uri(queryParameters: queryParams).query;
    }

    return ApiProvider.authGet(
      endpoint: '${ApiConstants.notifications}$queryString',
    );
  }

  static Future<http.Response> clearAllNotifications() {
    return ApiProvider.authDelete(endpoint: ApiConstants.clearNotifications);
  }

  static Future<http.Response> getPointMultipliers() {
    final endpoint = ApiConstants.pointMultipliers;
    log("Fetching point multipliers from URL: $endpoint");

    return ApiProvider.authGet(endpoint: endpoint);
  }

  static Future<http.Response> activateMultiplier(Map<String, dynamic> body) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.pointActivateMultipliers,
      body: body,
    );
  }

  static Future<http.Response> getReferralLink() {
    return ApiProvider.authGet(endpoint: ApiConstants.referralLink);
  }

  static Future<http.Response> checkReferralReward(Map<String, dynamic> body) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.checkReferralReward,
      body: body,
    );
  }

  static Future<http.Response> getBundles() {
    final endpoint = ApiConstants.shopbundles;
    log("Fetching bundles from URL: $endpoint");

    return ApiProvider.authGet(endpoint: endpoint);
  }

  // ApiService.dart
  static Future<http.Response> purchaseBundle(Map<String, dynamic> body) {
    final endpoint = ApiConstants.bundlePurchase;
    log("Purchasing bundle at: $endpoint with body: $body");

    return ApiProvider.authPost(endpoint: endpoint, body: body);
  }

  static Future<http.Response> applyCustomPreview(Map<String, dynamic> body) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.customPreview,
      body: body,
    );
  }

  /// Lock a group chat by ID
  static Future<Map<String, dynamic>> lockGroupChat(int chatId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/lock/$chatId');
    final headers = await _getAuthHeaders();

    final response = await http.put(url, headers: headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to lock chat');
    }
  }

  /// Unlock a group chat by ID
  static Future<Map<String, dynamic>> unlockGroupChat(int chatId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/unlock/$chatId');
    final headers = await _getAuthHeaders();

    final response = await http.put(url, headers: headers);
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to unlock chat');
    }
  }

  // ============ Chat PASSWORD lock (per-chat privacy lock) ============
  // NOTE: distinct from lock/unlockGroupChat above (that freezes group sending).
  // Server-synced so the lock follows the user across devices. Backend stores a
  // bcrypt hash per (user, chat) and NEVER returns it — only `isPasswordLocked`.
  // Contract: CHAT_LOCK_API.md (POST/DELETE /chats/:id/lock, /lock/verify,
  // /lock/status). verify + delete share a 5-per-15min wrong-attempt budget and
  // answer 429 with a Retry-After header → surfaced via [ChatLockRateLimited].

  /// Set (or change) the password lock on a chat. Pass [currentPassword] when
  /// changing an existing lock.
  static Future<Map<String, dynamic>> setChatPassword(
    int chatId,
    String password, {
    String? currentPassword,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/$chatId/lock');
    final res = await http.post(
      url,
      headers: await _getAuthHeaders(),
      body: jsonEncode({
        'password': password,
        if (currentPassword != null) 'currentPassword': currentPassword,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['status'] == true) return data;
    throw Exception(data['message'] ?? 'Failed to lock chat');
  }

  /// Verify a chat's password. Returns true only when correct, false on a wrong
  /// password (the backend answers 200 with `data.ok = false`, NOT a 4xx).
  /// Throws [ChatLockRateLimited] on 429 (too many wrong attempts).
  static Future<bool> verifyChatPassword(int chatId, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/$chatId/lock/verify');
    final res = await http.post(
      url,
      headers: await _getAuthHeaders(),
      body: jsonEncode({'password': password}),
    );
    if (res.statusCode == 429) {
      throw ChatLockRateLimited(_retryAfterSeconds(res));
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['status'] == true) {
      // Accept {status:true, data:{ok:true}} or a bare {status:true}.
      final ok = data['data'] is Map ? data['data']['ok'] : true;
      return ok == true;
    }
    return false;
  }

  /// Parse the `Retry-After` header (seconds) from a rate-limited response.
  static int _retryAfterSeconds(http.Response res) =>
      int.tryParse(res.headers['retry-after']?.trim() ?? '') ?? 0;

  /// Whether this chat currently has a password lock (for the settings screen).
  static Future<bool> getChatLockStatus(int chatId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/$chatId/lock/status');
    final res = await http.get(url, headers: await _getAuthHeaders());
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['status'] == true) {
      final d = data['data'];
      return (d is Map ? d['isPasswordLocked'] : false) == true;
    }
    return false;
  }

  /// Remove the password lock from a chat (requires the current password).
  static Future<Map<String, dynamic>> removeChatPassword(
    int chatId,
    String password,
  ) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/$chatId/lock');
    final res = await http.delete(
      url,
      headers: await _getAuthHeaders(),
      body: jsonEncode({'password': password}),
    );
    if (res.statusCode == 429) {
      throw ChatLockRateLimited(_retryAfterSeconds(res));
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 && data['status'] == true) return data;
    throw Exception(data['message'] ?? 'Failed to remove lock');
  }

  static Future<Map<String, dynamic>> muteChatNotifications(int chatId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/notifications/mute/$chatId');
    final headers = await _getAuthHeaders();

    try {
      final response = await http.put(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to mute chat. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> unmuteChatNotifications(
    int chatId,
  ) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/notifications/unmute/$chatId',
    );
    final headers = await _getAuthHeaders();

    try {
      final response = await http.put(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception(
          'Failed to mute chat. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> getMuteStatus(int chatId) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}/notifications/mute-status/$chatId',
    );

    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['isMuted'] ?? false;
      } else {
        throw Exception(
          'Failed to fetch mute status. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("❌ Error fetching mute status: $e");
      return false;
    }
  }

  static Future<int> getDisappearingSeconds(int chatId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/$chatId/disappearing');
    final headers = await _getAuthHeaders();
    try {
      final response = await http.get(url, headers: headers);
      log(
        'getDisappearingSeconds: status=${response.statusCode}, body=${response.body}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['disappearingSeconds'] ?? 0;
      }
      return 0;
    } catch (e) {
      log('Error fetching disappearing setting: $e');
      return 0;
    }
  }

  static Future<bool> setDisappearingSeconds(int chatId, int seconds) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/$chatId/disappearing');
    final headers = await _getAuthHeaders();
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({'seconds': seconds}),
      );
      log(
        'setDisappearingSeconds: status=${response.statusCode}, body=${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      log('Error setting disappearing messages: $e');
      return false;
    }
  }

  // Backup for the socket 'exitChat' emit. The socket fires on screen teardown
  // then disconnects immediately, which can drop the packet — this HTTP call
  // guarantees the server records the exit (hide/clear for disappearing chats).
  static Future<void> exitChat(int chatId) async {
    if (chatId <= 0) return;
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/$chatId/exit');
    final headers = await _getAuthHeaders();
    try {
      final response = await http.post(url, headers: headers);
      log('exitChat: status=${response.statusCode}, chatId=$chatId');
    } catch (e) {
      log('Error sending exitChat: $e');
    }
  }

  static Future<Map<String, dynamic>> deleteChats(List<int> chatIds) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/delete');
    final headers = await _getAuthHeaders();

    try {
      final response = await http.delete(
        url,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({"chatIds": chatIds}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        log("Chats deleted: $data");
        return data;
      } else {
        throw Exception(
          'Failed to delete chats. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Purchase outfit / accessory using authPost
  static Future<http.Response> purchaseItem({
    required String slot,
    required String priceUsd,
    required String brand,
    required bool equip,
    required String imageUrl,
  }) {
    final body = {
      "slot": slot.toUpperCase(),
      "priceUsd": priceUsd,
      "brand": brand,
      "equip": equip,
      "imageUrl": imageUrl,
    };

    return ApiProvider.authPost(
      endpoint: ApiConstants.customQuickBuy,
      body: body,
    );
  }

  // GET: /api/users/profile/{userId}
  static Future<http.Response> fetchAnyUserProfile(int userId) {
    return ApiProvider.authGet(
      endpoint: '${ApiConstants.anyOneProfile}/$userId',
    );
  }

  static Future<Map<String, dynamic>> markChatAsRead(int chatId) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/chats/markChatAsRead');
    final headers = await _getAuthHeaders();
    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode({'chatId': chatId}),
      );

      log('📤 Request: PUT $url');
      log('📥 Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to mark chat as read');
      }
    } catch (e) {
      log('❌ Error in markChatAsRead: $e');
      throw Exception('Error in markChatAsRead: $e');
    }
  }

  // 🗑️ Delete Notification
  static Future<http.Response> deleteNotification(int notificationId) {
    return ApiProvider.authDelete(
      endpoint: '${ApiConstants.deleteNotification}/$notificationId',
    );
  }

  /// 🟢 Get Notification Status or List
  static Future<http.Response> getRedDot() {
    return ApiProvider.authGet(endpoint: ApiConstants.getRedDot);
  }

  /// 🔴 Reset notification red dot
  static Future<http.Response> resetNotificationRedDot() {
    return ApiProvider.authPost(
      endpoint: ApiConstants.resetNotificationRedDot,
      body: {},
    );
  }

  static Future<http.Response> shareReferralReward({required String platform}) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.shareReferral,
      body: {"platform": platform},
    );
  }

  static Future<http.Response> getGlobalchatId() {
    return ApiProvider.authGet(endpoint: ApiConstants.globalId);
  }

  // api_service.dart

  static Future<http.Response> getGlobalchatIds({String? city}) async {
    String endpoint = '/chats/global-id';
    if (city != null && city.isNotEmpty) {
      endpoint += '?city=${Uri.encodeQueryComponent(city)}';
    }
    log("🔗 Calling Global Chat API: $endpoint");
    final response = await ApiProvider.authGet(endpoint: endpoint);
    return response;
  }

  static Future<List<dynamic>> getGlobalChatMessages({
    required int chatId,
    int page = 1,
    int limit = 20,
  }) async {
    final endpoint =
        '${ApiConstants.globalmessages}/$chatId?page=$page&limit=$limit';

    final res = await ApiProvider.authGet(endpoint: endpoint);

    if (res.statusCode != 200) {
      log('❌ global messages error: ${res.statusCode} -> ${res.body}');
      throw Exception('Failed to load global messages: ${res.statusCode}');
    }

    final body = jsonDecode(res.body);
    log('📥 Successful global chat response body: ${res.body}');

    // তোমার Postman স্ক্রিনশট অনুযায়ী body সরাসরি List
    if (body is List) return body;

    // extra safety (যদি ভবিষ্যতে data / messages key এ আসে)
    if (body is Map && body['messages'] is List)
      return body['messages'] as List;
    if (body is Map && body['data'] is List) return body['data'] as List;
    log('⚠️ getGlobalChatMessages: unexpected response format: ${res.body}');
    return <dynamic>[];
  }

  static Future<Map<String, dynamic>> sendGlobalChatMessage({
    required int chatId,
    required String content,
    String? imageUrl,
    bool forwarded = false,
  }) async {
    final payload = <String, dynamic>{'chatId': chatId, 'content': content};
    // When sharing a story/post we send it as a real image message (not a raw
    // URL pasted into the text). Backend should store this on the message AND
    // copy the media to a chat-owned object so it survives the 24h story delete.
    if (imageUrl != null && imageUrl.isNotEmpty) {
      payload['imageUrl'] = imageUrl;
    }
    // Forwarded messages carry a flag so the receiver shows a "Forwarded" label.
    if (forwarded) payload['forwarded'] = true;

    log('📤 sendGlobalChatMessage payload: $payload');

    final res = await ApiProvider.authPost(
      endpoint: ApiConstants.sendChatMessage,
      body: payload, // ✅ এখানে আর jsonEncode নাই
    );

    log('📥 sendGlobalChatMessage status=${res.statusCode} body=${res.body}');

    if (res.statusCode == 200 || res.statusCode == 201) {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;

      if (decoded['message'] is Map<String, dynamic>) {
        return decoded['message'] as Map<String, dynamic>;
      }
      return decoded;
    } else {
      throw Exception(
        'Failed to send global message: ${res.statusCode} ${res.body}',
      );
    }
  }

  static Future<PaginatedRestaurants> fetchRestaurants({
    required String categoryKey,
    required double lat,
    required double lng,
    int? page,
    int? pageSize,
  }) async {
    final qp = <String, String>{
      'lat': '$lat',
      'lng': '$lng',
      if (page != null) 'page': '$page',
      if (pageSize != null) 'pageSize': '$pageSize',
    };
    final String url =
        "${ApiConstants.baseUrl}/restaurants/category/$categoryKey/places"
        "?${qp.entries.map((e) => '${e.key}=${e.value}').join('&')}";
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true && data['restaurants'] != null) {
          final List<dynamic> restaurantList = data['restaurants'];
          final items =
              restaurantList
                  .map((json) => RestaurantModel.fromJson(json))
                  .toList();
          return PaginatedRestaurants(
            restaurants: items,
            page: (data['page'] as num?)?.toInt() ?? page ?? 1,
            pageSize:
                (data['pageSize'] as num?)?.toInt() ?? pageSize ?? items.length,
            totalCount: (data['totalCount'] as num?)?.toInt() ?? items.length,
            hasMore: data['hasMore'] == true,
          );
        }
      } else {
        print("API Error: ${response.statusCode}");
        print("Response Body: ${response.body}");
      }
    } catch (e) {
      print("Exception fetching restaurants: $e");
    }
    return PaginatedRestaurants.empty();
  }

  static Future<List<InventoryModel>> fetchInventory() async {
    final String url = "${ApiConstants.baseUrl}/shop/wardrobe";
    final String? token = await UserPreference.getToken();

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          final Map<String, dynamic> responseData = data['data'];
          final List<dynamic> inventoryList = responseData['flat'] ?? [];
          log("My Inventory Count: ${inventoryList.length}");
          return inventoryList.map((e) => InventoryModel.fromJson(e)).toList();
        }
      } else {
        log("❌ Failed to fetch inventory: ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error fetching inventory: $e");
    }
    return [];
  }

  static Future<Map<String, dynamic>?> fetchUserStats(int userId) async {
    final String url = "${ApiConstants.baseUrl}/users/$userId/stats";
    final String? token = await UserPreference.getToken();

    log("🚀 Calling Stats API: $url");
    log("🔑 Token: $token");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      log("📊 Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['success'] == true) {
          log("✅ Stats Data: ${data['data']}");
          return data['data'];
        }
      } else {
        log("❌ Failed to fetch stats: ${response.statusCode}");
        log("Response Body: ${response.body}");
      }
    } catch (e) {
      log("❌ Error fetching stats: $e");
    }
    return null;
  }

  static Future<http.Response> fetchVisitedSpots(
    int userId, {
    int page = 1,
    int limit = 20,
  }) {
    return ApiProvider.authGet(
      endpoint:
          '${ApiConstants.visitedSpots}/$userId/visited-spots?page=$page&limit=$limit',
    );
  }

  static Future<http.Response> fetchPlaceDetails({
    required String placeId,
    required double lat,
    required double lng,
  }) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.explorePlace}/$placeId'
      '?lat=$lat&lng=$lng',
    );
    log('📡 Fetching place details: $placeId');
    return http.get(url, headers: headers);
  }

  static Future<List<LockerItem>> getLockerData(int userId) async {
    final String? token = await UserPreference.getToken();
    final url = Uri.parse(
      "${ApiConstants.baseUrl}/users/$userId/minime-locker",
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List list = data['locker'] ?? [];
        return list.map((item) => LockerItem.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load locker data");
      }
    } catch (e) {
      log("❌ Error fetching locker: $e");
      rethrow;
    }
  }

  /// Fetch shop catalog from server
  static Future<http.Response> fetchCatalog({String? gender}) {
    final endpoint =
        gender != null
            ? '${ApiConstants.shopCatalog}?gender=$gender'
            : ApiConstants.shopCatalog;
    log("Fetching shop catalog from: $endpoint");
    return ApiProvider.authGet(endpoint: endpoint);
  }

  /// Equip an inventory item
  static Future<http.Response> equipItem({
    required int itemId,
    required String slot,
    bool applyNow = true,
  }) {
    final body = {
      "itemId": itemId,
      "slot": slot.toUpperCase(),
      "applyNow": applyNow,
    };
    log("Equipping item: $body");
    return ApiProvider.authPost(endpoint: ApiConstants.shopEquip, body: body);
  }

  /// Fetch active multiplier
  static Future<http.Response> fetchActiveMultiplier() {
    return ApiProvider.authGet(endpoint: ApiConstants.activeMultiplier);
  }

  static Future<List<dynamic>> getGlobalRooms() async {
    try {
      final response = await ApiProvider.authGet(
        endpoint: '/chats/global-rooms',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['rooms'] != null) {
          return data['rooms'];
        }
      }

      log("❌ Failed fetch global rooms: ${response.body}");
      return [];
    } catch (e) {
      log("⚠️ Exception fetching global rooms: $e");
      return [];
    }
  }

  /// Fetch completed challenges for a specific user
  static Future<http.Response> fetchCompletedChallenges(int userId) {
    final String endpoint = '/users/$userId/completed-challenges';

    log("Fetching completed challenges from: $endpoint");
    return ApiProvider.authGet(endpoint: endpoint);
  }

  static Future<http.Response> fetchSportVisited(int userId) {
    final String endpoint = '/users/$userId/visited-spots';
    log("Fetching visited spots from: $endpoint");
    return ApiProvider.authGet(endpoint: endpoint);
  }

  static Future<RestaurantModel?> placeFetched(String placeId) async {
    final String endpoint = '/explore/place/$placeId';

    try {
      final response = await ApiProvider.authGet(endpoint: endpoint);

      if (response.statusCode == 200) {
        log(response.statusCode.toString());
        log(response.body);
        final data = jsonDecode(response.body);

        // API returns the restaurant object directly (no success/data wrapper)
        if (data is Map<String, dynamic> && data['id'] != null) {
          return RestaurantModel.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print("Error parsing restaurant: $e");
      return null;
    }
  }

  // 🔹 Community History List (Join and Create only)
  static Future<http.Response> fetchCommunityHistory() {
    return ApiProvider.authGet(endpoint: 'communities/history');
  }

  /// Remove a member from a community (Admin only action)
  static Future<http.Response> removeCommunityMember({
    required int communityId,
    required int userId,
  }) {
    final body = {"communityId": communityId, "userId": userId};
    log("Removing community member payload: $body");
    return ApiProvider.authPost(
      endpoint: '/communities/remove-member',
      body: body,
    );
  }

  static Future<http.Response> getNotificationSetting() {
    return ApiProvider.authGet(endpoint: ApiConstants.notificationSetting);
  }

  static Future<http.Response> updateNotificationSetting(bool enabled) {
    return ApiProvider.authPost(
      endpoint: ApiConstants.notificationSetting,
      body: {"enabled": enabled},
    );
  }
}
