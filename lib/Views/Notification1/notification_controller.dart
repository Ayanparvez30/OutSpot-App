import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:outspot/Model/friends_model.dart';
import 'package:outspot/Model/notificaton_model.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Utils/app_snackbar.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:outspot/Views/Message/messages_screen_controller.dart';

class Notification1Controller extends GetxController
    with SingleGetTickerProviderMixin {
  late TabController tabController;

  var isLoading = false.obs;
  var notifications = <NotificationModel>[].obs;

  var selectedRead = RxnString();
  var selectedType = RxnString();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final notificationOptions = ["All Notifications", "Unread Only"];
  final typeOptions = ["All Types", "Challenges", "Friend Requests"];

  var selectedNotificationIndex = 0.obs;
  var selectedTypeIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);

    initLocalNotifications();

    getFcmToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleIncomingNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleIncomingNotification(message);
    });

    // getNotifications();
    loadNotifications();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  /// ---------------- Local Notifications ----------------
  void initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    await flutterLocalNotificationsPlugin.initialize(
      InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (details) {
        print("Notification tapped: ${details.payload}");
      },
    );
  }

  /// ---------------- FCM Token ----------------
  Future<void> getFcmToken() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await messaging.getToken();
      print("📱 FCM Token: $token");
    } else {
      print("User declined notification permission");
    }
  }

  /// ---------------- Handle incoming notifications ----------------
  void _handleIncomingNotification(RemoteMessage message) {
    final data = message.data;

    final type = data['type'] ?? '';
    final actorId = data['actorId'] ?? '0';
    final challengeId = data['challengeId'] ?? '';

    notifications.insert(
      0,
      NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: int.tryParse(data['userId'] ?? "0") ?? 0,
        actorId: int.tryParse(actorId) ?? 0,
        type: type,
        title: message.notification?.title ?? '',
        description: message.notification?.body ?? '',
        isRead: false,
        createdAt: DateTime.now(),
        avatarUrl: data['avatar'],
        actorUsername: data['actorUsername'],
        actorFirstName: data['actorFirstName'],
        actorLastName: data['actorLastName'],
        challengeId: challengeId.isNotEmpty ? int.tryParse(challengeId) : null,
        friendId:
            data['friendId'] != null
                ? int.tryParse('${data['friendId']}')
                : null,
        frequency: data['frequency'],
        points:
            data['points'] != null ? int.tryParse('${data['points']}') : null,
        icon: NotificationModel.iconFromType(type),
      ),
    );
    // Local notification is already shown in main.dart — no need to show again here

    // When a friend accepts, refresh their marker on the map in real-time
    // (works even if the map controller is already open).
    if (type == 'FRIEND_ACCEPTED' && Get.isRegistered<MapController>()) {
      Get.find<MapController>().refreshFriendsLocation();
    }
    if (type == 'FRIEND_ACCEPTED' &&
        Get.isRegistered<MessagesScreenController>()) {
      Get.find<MessagesScreenController>().fetchChats();
    }
  }

  Future<void> getNotifications() async {
    try {
      isLoading.value = true;
      final response = await ApiService.fetchNotifications();

      if (response.statusCode == 200) {
        log("status code: ${response.statusCode}");
        log("Response body: ${response.body}");
        final Map<String, dynamic> jsonMap = jsonDecode(response.body);

        final List<dynamic> dataList = jsonMap['data'] ?? [];

        notifications.value =
            dataList.map((e) => NotificationModel.fromJson(e)).toList();
      } else {
        AppSnackbar.error("Failed to fetch notifications");
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void handleIncomingFriendAccept(FriendsModel friend) {
    log("🔔 Friend accept notification triggered for: ${friend.username}");

    final message = RemoteMessage(
      notification: RemoteNotification(
        title: "You are now friends with ${friend.username}",
        body: "Friend request accepted",
      ),
      data: {
        "userId": friend.id.toString(),
        "actorId": friend.id.toString(),
        "type": "FRIEND_ACCEPTED",
        "avatar": friend.avatarUrl ?? '',
        "actorUsername": friend.username,
        "actorFirstName": friend.firstName,
        "actorLastName": friend.lastName,
      },
    );

    _handleIncomingNotification(message);
  }

  Future<void> loadNotifications() async {
    try {
      isLoading.value = true;

      String? read;
      String? type;

      if (selectedNotificationIndex.value == 1) {
        read = "read";
      } else if (selectedNotificationIndex.value == 2) {
        read = "unread";
      }

      if (selectedTypeIndex.value == 1) {
        type = "challenges";
      } else if (selectedTypeIndex.value == 2) {
        type = "friend_requests";
      }

      final res = await ApiService.getFilterNotifications(
        read: read,
        type: type,
      );
      log("Notification status: ${res.statusCode}");
      log("Notification response: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list =
            (data["data"] as List)
                .map((e) => NotificationModel.fromJson(e))
                .toList();
        notifications.assignAll(list);
      } else {
        notifications.clear();
      }
    } catch (e) {
      log("Error loading notifications: $e");
      notifications.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // void clearFilters() {
  //   selectedNotificationIndex.value = 0;
  //   selectedTypeIndex.value = 0;
  //   loadNotifications();
  // }

  Future<void> clearAllNotifications() async {
    try {
      isLoading.value = true;

      final res = await ApiService.clearAllNotifications();
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 &&
          data["message"] == "All notifications cleared") {
        notifications.clear();
        log("status code: ${res.statusCode}");
        log("Response body: ${res.body}");
      } else {
        log("Failed to clear notifications");
      }
    } catch (e) {
      log("Error clearing notifications: $e");
    } finally {
      isLoading.value = false;
    }
  }

  // 🗑️ Delete Notification function
  Future<void> deleteNotification(int notificationId) async {
    try {
      final response = await ApiService.deleteNotification(notificationId);

      if (response.statusCode == 200) {
        notifications.removeWhere((n) => n.id == notificationId);
        AppSnackbar.info("Notification deleted successfully", title: "Deleted");
      } else {
        AppSnackbar.error("Failed to delete notification");
      }
    } catch (e) {
      AppSnackbar.error("Something went wrong: $e");
    }
  }
}
