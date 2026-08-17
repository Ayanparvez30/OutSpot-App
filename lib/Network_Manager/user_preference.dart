import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserPreference {
  static const _kProfileDone = 'profile_done';
  static const _kProfileData = 'profile_data';
  static const _kSearchHistory = 'search_history';
  static const String _userIdKey = "user_id";
 

  static Future<void> saveToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> saveEmail(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
  }

  static Future<String?> getEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  static Future<void> saveRememberMe(bool stay) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('RememberMe', stay);
  }

  static Future<bool> getRememberMe() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('RememberMe') ?? false;
  }

  /// Own profile privacy. Persisted locally because the stats/profile endpoints
  /// report isPrivate relative to the VIEWER (always false for your own view),
  /// so this is the reliable source for showing the user their own setting.
  static Future<void> saveProfilePrivacy(bool isPrivate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ProfilePrivacy', isPrivate);
  }

  static Future<bool?> getProfilePrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('ProfilePrivacy');
  }

  static Future<void> clearAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('email');
    // Clear user-specific state so the next account that logs in doesn't
    // inherit it (e.g. the previous user's privacy toggle or user id).
    await prefs.remove('ProfilePrivacy');
    await prefs.remove(_userIdKey);
    await clearSearchHistory();
  }

  static Future<void> saveIsLoggedIn(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', value);
   
  }

  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<void> saveProfileDone(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kProfileDone, value);
  }

  static Future<bool> isProfileDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kProfileDone) ?? false;
  }

  static Future<void> cacheProfile(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileData, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_kProfileData);
    return (str == null) ? null : jsonDecode(str) as Map<String, dynamic>;
  }

  static Future<void> addSearchItem(String title, String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    String? oldHistory = prefs.getString(_kSearchHistory);
    List<dynamic> historyList =
        oldHistory != null ? jsonDecode(oldHistory) : [];
    historyList.removeWhere((item) => item['title'] == title);
    Map<String, String> newItem = {'title': title, 'image': imageUrl};
    historyList.insert(0, newItem);
    await prefs.setString(_kSearchHistory, jsonEncode(historyList));
  }

  static Future<List<Map<String, dynamic>>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      String? historyString = prefs.getString(_kSearchHistory);

      if (historyString != null) {
        List<dynamic> decoded = jsonDecode(historyString);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      print("Old history format found, clearing it.");
      await prefs.remove(_kSearchHistory);
    }
    return [];
  }

  static Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSearchHistory);
  }

  static Future<void> removeSearchItem(String title) async {
    final prefs = await SharedPreferences.getInstance();
    String? historyString = prefs.getString(_kSearchHistory);

    if (historyString != null) {
      List<dynamic> historyList = jsonDecode(historyString);
      
      // স্পেসিফিক টাইটেল খুঁজে রিমুভ করা
      historyList.removeWhere((item) => item['title'] == title);

      // আপডেট করা লিস্ট আবার সেভ করা
      await prefs.setString(_kSearchHistory, jsonEncode(historyList));
    }
  }
  static const _kCatalogCache = 'catalog_cache';

  static Future<void> cacheCatalog(String jsonStr) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCatalogCache, jsonStr);
  }

  static Future<String?> getCachedCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kCatalogCache);
  }

  // ID save korar jonno
  static Future<void> saveUserId(int userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  // ID get korar jonno
  static Future<int?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  static const _kSelectedCity = 'selected_global_city';

  static Future<void> saveSelectedCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedCity, city);
  }

  static Future<String?> getSelectedCity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSelectedCity);
  }

  // ----- Seen stories (story ring goes grey once viewed) -----
  static const _kSeenStoryIds = 'seen_story_ids';

  static Future<Set<int>> getSeenStoryIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSeenStoryIds) ?? const [];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  /// Merge [ids] into the persisted seen set and return the full updated set.
  static Future<Set<int>> addSeenStoryIds(Iterable<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getSeenStoryIds();
    current.addAll(ids);
    await prefs.setStringList(
      _kSeenStoryIds,
      current.map((e) => e.toString()).toList(),
    );
    return current;
  }
}
