import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:device_preview/device_preview.dart';
import 'package:http/http.dart' as http;
import 'package:outspot/Views/Message/messages_screen_controller.dart';
import 'package:outspot/Views/SettingNotification/SettingNotification.dart';
import 'package:outspot/Views/SettingNotification/SettingNotification_binding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:media_kit/media_kit.dart';
import 'package:outspot/Views/Directmassagescreen.dart/directmassagescreen_controller.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:outspot/Network_Manager/api_constains.dart';
import 'package:outspot/Network_Manager/api_service.dart';
import 'package:outspot/Network_Manager/notification_badge_service.dart';
import 'package:outspot/Network_Manager/socketService.dart';
import 'package:outspot/Network_Manager/user_preference.dart';
import 'package:outspot/Utils/routes.dart';
import 'package:outspot/Utils/profile_reload_observer.dart';
import 'package:outspot/Views/Mapscreen/map_controller.dart';
import 'package:outspot/Views/AllStats/allStats.dart';
import 'package:outspot/Views/AllStats/allStats_binding.dart';
import 'package:outspot/Views/BlockList/blockList.dart';
import 'package:outspot/Views/BlockList/blockList_binding.dart';
import 'package:outspot/Views/Camerascreen/camerascreen_binding.dart';
import 'package:outspot/Views/Camerascreen/camerascreen_controller.dart';
import 'package:outspot/Views/Camerascreen/photo_submit_screen.dart';
import 'package:outspot/Views/Camerascreen/postscreen.dart';
import 'package:outspot/Views/Challenges/challenge_binding.dart';
import 'package:outspot/Views/Challenges/challenge_screen.dart';
import 'package:outspot/Views/Challenges/daily_challenge.dart';
import 'package:outspot/Views/Community/community.dart';
import 'package:outspot/Views/Community/community_binding.dart';
import 'package:outspot/Views/CreatePassword/createPassword_bindings.dart';
import 'package:outspot/Views/CreatePassword/createPassword_screen.dart';
import 'package:outspot/Views/CreateProfile/Feminine_body.dart';
import 'package:outspot/Views/CreateProfile/chooseBodyType.dart';
import 'package:outspot/Views/CreateProfile/createProfile.dart';
import 'package:outspot/Views/CreateProfile/createProfile_bindings.dart';
import 'package:outspot/Views/CreateProfile/generate_Screen.dart';
import 'package:outspot/Views/CreateProfile/outfit_Screen.dart';
import 'package:outspot/Views/Create_Mini_Me/create_mini_me.dart';
import 'package:outspot/Views/Create_Mini_Me/create_mini_me_bindings.dart';
import 'package:outspot/Views/Create_Mini_Me/take_selfie.dart';
import 'package:outspot/Views/Directmassagescreen.dart/directmassgescreen_binding.dart';
import 'package:outspot/Views/Explore_Category/explore_category.dart';
import 'package:outspot/Views/Explore_Category/explore_category_binding.dart';
import 'package:outspot/Views/Explorescreen/explore_bonding.dart';
import 'package:outspot/Views/ForgotScreen/forgot_bindings.dart';
import 'package:outspot/Views/ForgotScreen/forgot_screen.dart';
import 'package:outspot/Views/CreateProfile/masculine_Body.dart';
import 'package:outspot/Views/FriendList/friendList.dart';
import 'package:outspot/Views/FriendList/friendList_binding.dart';
import 'package:outspot/Views/FriendsProfile/friends_profile.dart';
import 'package:outspot/Views/FriendsProfile/friends_profile_binding.dart';
import 'package:outspot/Views/Groupdetails/groupmember_page.dart';
import 'package:outspot/Views/Groupdetails/groupdetails_binding.dart';
import 'package:outspot/Views/Groups/groups.dart';
import 'package:outspot/Views/Groups/groups_binding.dart';
import 'package:outspot/Views/NewChat/new_chat_screen.dart';
import 'package:outspot/Views/Directmassagescreen.dart/conversation_options_screen.dart';
import 'package:outspot/Views/NewChat/new_chat_binding.dart';
import 'package:outspot/Views/LaunchScreen/launch_bindings.dart';
import 'package:outspot/Views/LaunchScreen/launch_screen.dart';
import 'package:outspot/Views/Leaderboard%20Global1/leaderboard_binding.dart';
import 'package:outspot/Views/Leaderboard%20Global1/leaderboard_global.dart';
import 'package:outspot/Views/Login/login_screen.dart';
import 'package:outspot/Views/Login/login_bindings.dart';
import 'package:outspot/Views/Mapscreen/map_binding.dart';
import 'package:outspot/Views/Message/camera_screen.dart';
import 'package:outspot/Views/Message/View_achievements.dart';
import 'package:outspot/Views/Directmassagescreen.dart/direct_message_screen.dart';
import 'package:outspot/Views/Explorescreen/explore.dart';
import 'package:outspot/Views/Mainscreen/main_screen.dart';
import 'package:outspot/Views/Mainscreen/mainscreeen_controller.dart';
import 'package:outspot/Views/Mapscreen/map_screen.dart';
import 'package:outspot/Views/Mainscreen/mainscreen_binding.dart';
import 'package:outspot/Views/No%20Community/noCommunity.dart';
import 'package:outspot/Views/No%20Community/noCommunity_binding.dart';
import 'package:outspot/Views/Notification1/notification1.dart';
import 'package:outspot/Views/Notification1/notification1_binding.dart';
import 'package:outspot/Views/PreviewAvatar/preview.dart';
import 'package:outspot/Views/PreviewAvatar/preview_bindings.dart';
import 'package:outspot/Views/SendorSubmitchallenge/Select%20_Challenge.dart';
import 'package:outspot/Views/SendorSubmitchallenge/send_or%20submid_binding.dart';
import 'package:outspot/Views/SendorSubmitchallenge/send_submit%20challange.dart';
import 'package:outspot/Views/ModalBottomSheet/modalBottomSheet.dart';
import 'package:outspot/Views/ModalBottomSheet/modalBottomSheet_binding.dart';
import 'package:outspot/Views/NewGroupScreen/add_screen.dart';
import 'package:outspot/Views/NewGroupScreen/new_group_screen.dart';
import 'package:outspot/Views/NewGroupScreen/new_group_screen_binding.dart';
import 'package:outspot/Views/NonPrivateProfile/non_private_profile.dart';
import 'package:outspot/Views/NonPrivateProfile/non_private_profile_binding.dart';
import 'package:outspot/Views/OtpScreen/otp_bindings.dart';
import 'package:outspot/Views/OtpScreen/otp_screen.dart';
import 'package:outspot/Views/SettingScreen/setting_bindings.dart';
import 'package:outspot/Views/SettingScreen/setting_screen.dart';
import 'package:outspot/Views/ShopCloths/shopCloths.dart';
import 'package:outspot/Views/ShopCloths/shopCloths_binding.dart';
import 'package:outspot/Views/SignUpScreen/signUp_bindings.dart';
import 'package:outspot/Views/SignUpScreen/signUp_screen.dart';
import 'package:outspot/Views/Message/messages_screen.dart';
import 'package:outspot/Views/Message/messages_screen_binding.dart';
import 'package:outspot/Views/MyProfile/myProfile.dart';
import 'package:outspot/Views/MyProfile/myProfile_binding.dart';
import 'package:outspot/Views/SplashScreen/splash_binding.dart';
import 'package:outspot/Views/SplashScreen/splash_screen.dart';
import 'package:outspot/Views/PasswordScreen/password_screen.dart';
import 'package:outspot/Views/PasswordScreen/password_screen_binding.dart';
import 'package:outspot/Views/UpdateScreen/update_screen.dart';
import 'package:outspot/Views/UpdateScreen/update_screen_binding.dart';
import 'package:outspot/Views/UpdateBio/updateBio.dart';
import 'package:outspot/Views/UpdateBio/updateBio_binding.dart';
import 'package:outspot/Views/UserName/contactUs.dart';
import 'package:outspot/Views/UserName/userName.dart';
import 'package:outspot/Views/UserName/userName_binding.dart';
import 'package:outspot/Views/waredrop/generations_screen.dart';
import 'package:outspot/Views/waredrop/waredrop.dart';
import 'package:outspot/Views/waredrop/waredrop_binding.dart';
import 'package:outspot/Views/waredrop_preview/waredrop_preview.dart';
import 'package:outspot/Views/waredrop_preview/waredrop_preview_binding.dart';
import 'package:outspot/firebase_options.dart';

// ---------------- Local Notifications Plugin ----------------
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ---------------- Background Message Handler ----------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  log('📩 Background message received: ${message.messageId}');

  // Confirm delivery for chat messages (double grey tick)
  final type = message.data['type'];
  if (type == 'CHAT_MESSAGE') {
    final chatId = message.data['chatId'];
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (chatId != null && token != null) {
      try {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}/chats/confirm-delivery'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'chatId': int.parse(chatId.toString())}),
        );
        log('✅ Delivery confirmed for chat $chatId');
      } catch (e) {
        log('❌ Delivery confirm failed: $e');
      }
    }
  }
}

// ---------------- Initialize Notifications ----------------
Future<void> initNotification() async {
  // Android settings
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('ic_notification');

  // iOS settings
  final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );

  await flutterLocalNotificationsPlugin.initialize(
    InitializationSettings(android: androidSettings, iOS: iosSettings),
    onDidReceiveNotificationResponse: (NotificationResponse details) {
      log("📌 Notification tapped: ${details.payload}");

      if (details.payload != null) {
        final parts = details.payload!.split('|');
        final data = <String, dynamic>{
          'type': parts[0],
          if (parts.length > 1 && parts[1].isNotEmpty) 'actorId': parts[1],
          if (parts.length > 2 && parts[2].isNotEmpty) 'challengeId': parts[2],
        };
        _handleNotificationNavigation(data);
      }
    },
  );

  // Foreground message listener
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // NOTE: the notification bell red dot is driven realtime by
    // NotificationBadgeService's socket (works even when push is disabled), so
    // we deliberately do NOT refresh it here — that would be redundant.

    RemoteNotification? notification = message.notification;

    if (notification != null) {
      final type = message.data['type'] ?? '';
      final actorId = message.data['actorId'] ?? '';
      final challengeId = message.data['challengeId'] ?? '';

      // Friend accepted — refresh their marker on the map in real-time,
      // even if the map is already open.
      if (type == 'FRIEND_ACCEPTED' && Get.isRegistered<MapController>()) {
        Get.find<MapController>().refreshFriendsLocation();
      }
      if (type == 'FRIEND_ACCEPTED' &&
          Get.isRegistered<MessagesScreenController>()) {
        Get.find<MessagesScreenController>().fetchChats();
      }

      // Skip notification if user is currently in the same person's chat
      if (type == 'MESSAGE' && actorId.isNotEmpty) {
        try {
          if (Get.isRegistered<DirectmassagescreenController>()) {
            final dmController = Get.find<DirectmassagescreenController>();
            if (dmController.frienduserId.value.toString() == actorId) {
              // User is already in this chat — no notification needed
              return;
            }
          }
        } catch (_) {}
      }

      // On iOS, system handles foreground display via setForegroundNotificationPresentationOptions
      // Only show local notification on Android
      if (Platform.isAndroid) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default Channel',
              icon: 'ic_notification',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: '$type|$actorId|$challengeId',
        );
      }
    }
  });

  // When app is opened via notification (background)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    log("📌 App opened from notification: ${message.data}");
    if (message.data['type'] != null) {
      _handleNotificationNavigation(message.data);
    }
  });

  // When app is launched from terminated state
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null && initialMessage.data['type'] != null) {
    _handleNotificationNavigation(initialMessage.data);
  }
}

// -------------------- Handle Navigation --------------------
void _navigateToMainTab(int tab) {
  if (Get.isRegistered<MainscreeenController>()) {
    final controller = Get.find<MainscreeenController>();
    controller.changeTab(tab);
    Get.until((route) => route.settings.name == Routes.mainscreen);
  } else {
    Get.offAllNamed(Routes.mainscreen, arguments: {"tab": tab});
  }
}

void _handleNotificationNavigation(Map<String, dynamic> data) {
  final type = data['type'] ?? '';
  final actorId = int.tryParse('${data['actorId'] ?? ''}');

  switch (type) {
    case 'FRIEND_ACCEPTED':
      if (actorId != null) {
        Get.toNamed(Routes.friendsProfile, arguments: {"id": actorId});
      }
      break;
    case 'FRIEND_REQUEST':
      Get.toNamed(Routes.friendlist, arguments: {"tab": 1});
      break;
    case 'NEW_CHALLENGE':
    case 'DAILY_CHALLENGE':
    case 'WEEKLY_CHALLENGE':
      _navigateToMainTab(3);
      break;
    case 'MESSAGE':
      _navigateToMainTab(0);
      break;
    case 'COMMUNITY_BANNED':
    case 'COMMUNITY_UNBANNED':
      final cid = int.tryParse('${data['communityId'] ?? ''}');
      if (cid != null) {
        Get.toNamed(Routes.community, arguments: {"id": cid});
      } else {
        _navigateToMainTab(0);
      }
      break;
    case 'GROUP_BANNED':
    case 'GROUP_UNBANNED':
      _navigateToMainTab(0);
      break;
    default:
      _navigateToMainTab(0);
      break;
  }
}

// -------------------- FCM token --------------------
Future<void> getFcmToken() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Enable iOS foreground notification display
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    String? token = await messaging.getToken();
    log("📱 FCM Token: $token");

    // Re-register on every app open so a rotated/stale token (cleared backend
    // side when FCM reports it dead) is restored — login/OTP no longer fire
    // for an already-logged-in user, so this is the only path that refreshes it.
    await _registerFcmToken(token);
  } else {
    log("User declined notification permission");
  }
}

/// Push the FCM token to the backend, but only when a user is logged in
/// (otherwise there's no account to attach it to).
Future<void> _registerFcmToken(String? token) async {
  if (token == null || token.isEmpty) return;
  final authToken = (await UserPreference.getToken())?.trim();
  if (authToken == null || authToken.isEmpty) {
    log("ℹ️ Skipping FCM register — no logged-in user");
    return;
  }
  try {
    await ApiService.updateFcmToken(token);
    log("✅ FCM token registered with backend");
  } catch (e) {
    log("❌ Failed to register FCM token: $e");
  }
}

// Toggle to preview the app inside different device frames (screen sizes,
// notches, safe areas). Set to `true` to turn the device-preview panel on,
// `false` for the normal app. Keep it `false` for release builds.
const bool kUseDevicePreview = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock app to portrait only — no rotation anywhere.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  MediaKit.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics — capture Flutter + platform errors so we can debug issues
  // (e.g. video playback failing on devices we don't own) remotely.
  // Non-fatal: the app survives overflows, missing assets and failed font
  // fetches — marking them fatal buried the real crashes.
  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterError(details, fatal: false);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
    return true;
  };

  // background handler set
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // FCM rotates tokens on its own schedule; push the new one to the backend the
  // moment it changes so we never silently drift to a dead/stale token.
  FirebaseMessaging.instance.onTokenRefresh.listen(_registerFcmToken);

  // NOTE: initNotification() and getFcmToken() are now called in SplashController
  // after the UI is loaded to prevent TestFlight launch issues

  SocketService(ApiConstants.socketUrl);
  Get.put(NotificationBadgeService());
  configLoading();
  runApp(
    DevicePreview(
      // When false, DevicePreview is a no-op passthrough — the real app runs
      // as normal. Flip kUseDevicePreview to true to get the device panel.
      enabled: kUseDevicePreview,
      builder: (context) => const MyApp(),
    ),
  );
}

void configLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.circle
    ..loadingStyle = EasyLoadingStyle.dark
    ..backgroundColor = Colors.white
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..dismissOnTap = false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Outspot',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'roboto'),
          // device_preview wiring — inert when kUseDevicePreview is false.
          useInheritedMediaQuery: true,
          locale: DevicePreview.locale(context),
          // Reloads a profile screen for its own id when revealed on back-nav
          // (friend → friend-of-friend chain uses singleton controllers).
          navigatorObservers: [ProfileReloadObserver()],

          // Tag every Crashlytics report with the screen the user was on.
          // Release traces only carry framework frames, so an Obx/render crash
          // is otherwise unattributable to a route.
          routingCallback: (routing) {
            final route = routing?.current ?? '';
            if (route.isEmpty) return;
            FirebaseCrashlytics.instance.setCustomKey('route', route);
            FirebaseCrashlytics.instance.log('route: $route');
          },

          builder: (context, widget) {
            // AppToast.init(context);

            widget = EasyLoading.init()(context, widget);

            widget = GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: widget,
            );

            // Wrap with the device_preview frame (no-op when disabled).
            return DevicePreview.appBuilder(context, widget);
          },
          initialRoute: Routes.splashScreen,
          getPages: [
            GetPage(
              name: Routes.friendlist,
              page: () => FriendListScreen(),
              binding: FriendListBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.group,
              page: () => Groups(),
              binding: GroupsBinding(),
            ),
            GetPage(
              name: Routes.newChat,
              page: () => const NewChatScreen(),
              binding: NewChatBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.conversationOptions,
              page: () => const ConversationOptionsScreen(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.friendsProfile,
              page: () => FriendsProfile(),
              binding: FriendsProfileBinding(),
            ),
            GetPage(
              name: Routes.nonPrivateProfile,
              page: () => NonPrivateProfile(),
              binding: NonPrivateProfileBinding(),
            ),
            GetPage(
              name: Routes.community,
              page: () => CommunityScreen(),
              binding: CommunityBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.notification1,
              page: () => Notification1(),
              binding: Notification1Binding(),
            ),
            GetPage(
              name: Routes.loginScreen,
              page: () => LoginScreen(),
              binding: LoginBindings(),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: Routes.passwordScreen,
              page: () => PasswordScreen(),
              binding: PasswordScreenBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.updateScreen,
              page: () => UpdateScreen(),
              binding: UpdateScreenBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.shopCloths,
              page: () => ShopCloths(),
              binding: ShopClothsBinding(),
            ),
            GetPage(
              name: Routes.myProfile,
              page: () => MyProfile(),
              binding: MyProfileBindings(),
            ),
            GetPage(
              name: Routes.createProfile,
              page: () => Createprofile(),
              binding: CreateprofileBindings(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.splashScreen,
              page: () => SplashScreen(),
              binding: SplashBinding(),
              transition: Transition.fade,
            ),
            GetPage(
              name: Routes.messagesScreen,
              page: () => MessagesScreen(),
              binding: MessagesScreenBinding(),
            ),
            GetPage(
              name: Routes.launchScreen,
              page: () => LaunchScreen(),
              binding: LaunchBindings(),

              // transition: Transition.fadeIn,
              // transitionDuration: const Duration(milliseconds: 500),
            ),
            GetPage(
              name: Routes.mainscreen,
              page: () => MainScreen(),
              binding: MainscreenBinding(),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 500),
            ),
            GetPage(
              name: Routes.mapscreen,
              page: () => MapScreen(),
              binding: MapScreenBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.directMessageScreen,
              page: () => DirectMessageScreen(),
              binding: DirectmassgescreenBinding(),
            ),
            GetPage(
              name: Routes.signUpScreen,
              page: () => SignupScreen(),
              binding: SignupBindings(),
              transition: Transition.fadeIn,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: Routes.forgotScreen,
              page: () => ForgotScreen(),
              binding: ForgotBindings(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.createPassword,
              page: () => CreatepasswordScreen(),
              binding: CreatepasswordBindings(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.chooseBody,
              page: () => Choosebodytype(),
              binding: CreateprofileBindings(),
            ),
            GetPage(
              name: Routes.masculineBody,
              page: () => MasculineBody(),
              binding: CreateprofileBindings(),
            ),
            GetPage(
              name: Routes.feminineBody,
              page: () => FeminineBody(),
              binding: CreateprofileBindings(),
            ),
            GetPage(
              name: Routes.createMiniMe,
              page: () => CreateMiniMe(),
              binding: CreateMiniMeBindings(),
            ),
            GetPage(
              name: Routes.takeSelfie,
              page: () => TakeSelfie(),
              binding: CreateMiniMeBindings(),
            ),
            GetPage(
              name: Routes.camerascreen,
              page: () => CameraScreen(),
              binding: MessagesScreenBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.sendSubmitchallange,
              page: () => SendSubmitchallange(),
              binding: SendorsubmidBinding(),
            ),
            GetPage(
              name: Routes.otpScreen,
              page: () => OtpScreen(),
              binding: OtpBindings(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.outfitScreen,
              page: () => OutfitScreen(),
              binding: CreateprofileBindings(),
            ),
            GetPage(
              name: Routes.settingScreen,
              page: () => SettingScreen(),
              binding: SettingBindings(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.userName,
              page: () => Username(),
              binding: UsernameBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.updateBio,
              page: () => Updatebio(),
              binding: UpdatebioBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.contactUs,
              page: () => Contactus(),
              binding: UsernameBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.generate,
              page: () => GenerateScreen(),
              binding: UsernameBinding(),
            ),
            GetPage(
              name: Routes.previewMinime,
              page: () => PreviewMinime(),
              binding: PreviewBindings(),
            ),
            GetPage(
              name: Routes.blockList,
              page: () => Blocklist(),
              binding: BlocklistBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.modalBottomSheet,
              page: () => Modalbottomsheet(),
              binding: ModalbottomsheetBinding(),
            ),
            GetPage(
              name: Routes.explore,
              page: () => Explore(),
              binding: ExploreBinding(),
            ),
            GetPage(
              name: Routes.selectChallenge,
              page: () => SelectChallenge(),
              binding: SendorsubmidBinding(),
            ),
            GetPage(
              name: Routes.newGroupScreen,
              page: () => NewGroupScreen(),
              binding: NewGroupScreenBinding(),
            ),
            GetPage(
              name: Routes.addscreen,
              page: () => AddScreen(),
              binding: NewGroupScreenBinding(),
            ),
            GetPage(
              name: Routes.viewAchievements,
              page: () => ViewAchievements(),
              binding: MessagesScreenBinding(),
              // Native iOS slide (right-to-left). downToUp flashed a white gap
              // during the slide on iOS; cupertino handles the background.
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 300),
            ),
            GetPage(
              name: Routes.challengeScreen,
              page: () => ChallengeScreen(),
              binding: ChallengeBinding(),
            ),
            GetPage(
              name: Routes.dailyChallenge,
              page: () => DailyChallenge(),
              binding: ChallengeBinding(),
            ),
            GetPage(
              name: Routes.photoSubmitScreen,
              page: () => PhotoSubmitScreen(),
              binding: CamerascreenBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.leaderboardGlobal,
              page: () => LeaderboardGlobal(),
              binding: LeaderboardBinding(),
            ),
            GetPage(
              name: Routes.postscreen,
              page: () => Postscreen(),
              binding: BindingsBuilder(() {
                Get.put(CamerascreenController());
              }),
            ),
            GetPage(
              name: Routes.noCommunity,
              page: () => Nocommunity(),
              binding: NocommunityBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.waredrop,
              page: () => Waredrop(),
              binding: WaredropBinding(),
            ),
            GetPage(
              name: Routes.groupMembersPage,
              page: () => GroupMembersPage(),
              binding: GroupdetailsBinding(),
            ),
            GetPage(
              name: Routes.wareDropPreview,
              page: () => WaredropPreview(),
              binding: WaredropPreviewBinding(),
            ),
            GetPage(
              name: Routes.waredropgenerate,
              page: () => GenerateScreens(),
              binding: UsernameBinding(),
            ),
            GetPage(
              name: Routes.exploreCategory,
              page: () => ExploreCategory(),
              binding: ExploreCategoryBinding(),
            ),
            GetPage(
              name: Routes.allStats,
              page: () => AllStats(),
              binding: AllStatsBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
            GetPage(
              name: Routes.settingnotification,
              page: () => Settingnotification(),
              binding: SettingnotificationBinding(),
              transition: Transition.cupertino,
              transitionDuration: const Duration(milliseconds: 800),
            ),
          ],
        );
      },
    );
  }
}
