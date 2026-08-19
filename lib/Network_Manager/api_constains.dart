class ApiConstants {
  // Single source of truth for the backend host.
  static const String host = 'https://api-app.outspot.app';
  static const String baseUrl = '$host/api';
  // Socket.IO endpoint — same host, no /api prefix. https upgrades to wss
  // automatically (transports: websocket).
  static const String socketUrl = host;
  static const String signup = '/signup';
  static const String verifyOtp = '/verify-otp';
  static const String login = '/login';
  static const String resendOtp = '/resend-otp';
  static const String forgotpass = '/forgot-password';
  static const String resetPass = '/forgot-password/reset';
  static const String contactUs = '/contact-us';
  static const String logOut = '/logout';
  static const String deleteaccount = '/me/delete';
  static const String userProfile = '/me/profile';
  static const String updatePassword = '/update-password';
  static const String updateUsername = '/update-username';
  static const String updateBio = '/me/update-bio';
  static const String updateName = '/me/update-name';
  static const String friendS = '/friends';
  static const String points = '/users/points';
  static const String minimeLocker = '/minime/locker';
  static const String searchFriends = '/friends/search';
  static const String getBlock = '/users/blocked';
  static const String unblockUser = '/block';
  static const String sendFriendRequest = '/friends/request';
  static const String unfriend = '/friends';
  static const String acceptFriendRequest = '/friends/accept';
  static const String IncomingFriendRequestsList = '/friends/requests/incoming';
  static const String declineRequest = '/friends/decline';
  static const String friendsProfile = '/friends-profile';
  static const String blockUser = '/block';
  static const String createCommunity = '/communities';
  static const String getAllCommunities = '/communities';
  static const String joinCommunity = '/communities/join';
  static const String updateLocation = "/map/location";
  static const String getFriendsLocation = '/map/friends';
  static const String upload = '/upload';
  static const String getStories = '/stories';
  static const String getCommunityDetails = '/communities';
  static const String getStoriesWithLocation = '/stories';
  static const String deleteCommunity = '/communities';
  static const String editCommunity = '/communities';
  static const String recentCommunity = '/communities/recent';
  static const String storieSaveProfile = '/stories/profile';
  static const String storieSaveVault = '/stories/vault';
  static const String removeStories = '/stories';
  static const String leaveCommunity = '/communities/leave';
  static const String getOwnStory = '/stories/me';
  static const String getSentFriendRequests = '/friends/sent-requests';
  static const String ProfileAvatar = '/users';
  static const String recentCommunities = '/communities/my/recent';
  static const String communityActivity = '/communities/history';
  static const String savedStories = '/stories/saved';
  static const String savedVaultStory = '/stories/vault';
  static const String setProfilePrivacy = '/me/privacy';
  static const String recommendedFriends = '/friends/recommended';
  static const String myCommunity = '/communities/mine';
  static const String reportFriend = '/report';
  static const String notification = '/notifications';
  // Force-update policy. Public — answered before login.
  static const String appVersion = '/app/version';

  // In-app reviews of OutSpot itself.
  static const String myReview = '/review/me';
  static const String submitReview = '/review';

  // Spots users suggest from Explore.
  static const String suggestSpot = '/spots/suggest';
  static const String mySpotSuggestions = '/spots/my-suggestions';

  static const String exploreHome = '/explore/home';

  static const String updateFcmToken = '/me/fcm-token';
  static const String submitPoints = '/submit-for-points';
  static const String notifications = '/notifications';
  static const String clearNotifications = '/notifications/clearAll';
  static const String pointMultipliers = '/shop/multipliers';
  static const String pointActivateMultipliers = '/shop/iap/confirm';
  static const String referralLink = '/referrals/link';
  static const String checkReferralReward = '/referrals/summary';
  static const String shopbundles = '/shop/bundles';
  static const String bundlePurchase = '/shop/bundles/purchase';
  static const String customPreview = '/shop/custom/preview';
  static const String customQuickBuy = '/shop/custom/quick-buy';
  static const String shopCatalog = '/shop/catalog';
  static const String shopEquip = '/shop/equip';
  static const String activeMultiplier = '/shop/multiplier/active';
  static const String anyOneProfile = '/users/profile';
  static const String storiesFeed = '/stories/feed';
  static const String phoneOtp = '/verify-otp';
  static const String deleteNotification = '/notifications';
  static const String getRedDot = '/notifications/red-dot';
  static const String resetNotificationRedDot = '/notifications/reset-red-dot';
  static const String shareReferral = '/referrals/share';
  static const String globalId = '/chats/global-id';
  static const String globalmessages = '/chats/messages-paginated';
  static const String sendChatMessage =
      '/chats/messages'; // POST /api/chats/messages
  static const String visitedSpots = '/users';
  static const String explorePlace = '/explore/place';
  static const String explorePosts = '/explore/posts';
  static const String notificationSetting = '/me/notification-setting';
}
