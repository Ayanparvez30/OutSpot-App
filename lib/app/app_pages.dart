import 'package:get/get.dart';

import 'package:outspot/Views/SettingNotification/SettingNotification.dart';
import 'package:outspot/Views/SettingNotification/SettingNotification_binding.dart';
import 'package:outspot/Utils/routes.dart';
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

/// Every named route in the app, in one place.
///
/// Lifted out of `main.dart`, which had grown past 800 lines with this list
/// making up more than a third of it. Nothing about the routes changed — the
/// entries, their bindings and their transitions are the same objects `main.dart`
/// used to declare inline, so `GetMaterialApp` behaves identically.
abstract final class AppPages {
  static final List<GetPage> routes = [
    GetPage(
      name: Routes.friendlist,
      page: () => FriendListScreen(),
      binding: FriendListBinding(),
      transition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 800),
    ),
    GetPage(name: Routes.group, page: () => Groups(), binding: GroupsBinding()),
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
  ];
}
