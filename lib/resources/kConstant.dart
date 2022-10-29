
import 'package:flutter/material.dart';

const kArticle = "Walking can offer numerous health benefits to people of all ages and fitness levels. "
    "It may also help prevent certain diseases and even prolong your life. Walking is free to do and easy to "
    "fit into your daily routine. All you need to start walking is a sturdy pair of walking shoes. Read on to "
    "learn about some of the benefits of walking.";

/// constant variables used in project
class kConst {
  static String appTitle ='Walking with Thooly';
  static String privacyPathKR = 'assets/privacy_kr.txt';
  static String privacyPathEN = 'assets/privacy_en.txt';
  static String termsPathKR = 'assets/service_terms_kr.txt';
  static String termsPathEN = 'assets/service_terms_en.txt';
  static String kakaoImage = 'assets/images/kakao_icon_50px.png';
  static List<String> titleAppbar = ['Walking With Thooly', 'Map', 'Message', 'User Info'];
  static String titleJournal = 'Journal';
  static String fileJournal = 'journal.txt';
  static String thumbnailImage = 'user_thumbnail.jpg';
  static double walkingFactor = 0.57;
}

class FbCollection {
  static const USERS = 'Users';
  static const FRIENDS = 'Friends';
  static const WALKING = 'Walking';
  static const MESSAGE = 'Message';
  static const PLACES = 'Places';
}

class kStorageKey {
  static const String CONTAINER = 'thooly_container';
  static const String USERINFO = 'thooly_userinfo';
  static const String THUMBNAIL = 'thooly_thumbnail';
}

class kRoutes {
  static const LOGIN = '/login';
  static const HOME = '/';
  static const CREATE_ACCOUNT = '/createAccount';
  static const TERMS_AGREEMENT = '/termsAgreement';
  static const TERMS_POLICY = '/termsPolicy';
  static const RESET_PASSWROD = '/resetPassword';
  static const FORGOT_PASSWORD = '/forgotPassword';
  static const JOURNAL = '/journal';
  static const USER_PAGE = '/userPage';
  static const MAP = '/myMap';
  static const MESSAGING = '/messaging';
  static const MESSAGE_PAGE = '/messagePage';
  static const SETTINGS = '/settings';
}

const kNavPages = [kRoutes.HOME, kRoutes.MAP, kRoutes.MESSAGING, kRoutes.USER_PAGE];

class kColor {
  /// homepage
  static Color appbar = Colors.grey[200]!;
  static Color appbarMessage = Colors.indigo[400]!;
  static Color appbarMenu = Colors.green[700]!;
  static Color appbarText = Colors.green[700]!;
  static Color background = Colors.grey[200]!;
  static Color login = Colors.black54;
  static Color circleText = Colors.blue[800]!;
  static Color journal = Colors.black54;
  static Color rankText = Colors.black87;
  static Color rankTextHighlight = Colors.blueAccent;
  static Color emoji = Colors.blueGrey;
  static Color navigationBar = Colors.grey[200]!;
  static Color navigationBarSelected = Colors.blueAccent;
  static Color navigationBarUnselected = Colors.grey;
  static Color decorationBox = Colors.grey[50]!;
  /// login related
  static Color buttonColor = Colors.blueGrey[600]!;
  static Color buttonText = Colors.white;
  static Color loginContents = Colors.blueGrey[600]!;
  static Color termsText = Colors.black54;
  static Color defaultThumbnail = Colors.blueGrey;
  static Color userid = Colors.blueGrey[600]!;
  static Color dialogText = Colors.black87;
  /// chatting/message
  static Color inputTextField = Colors.grey[50]!;
  static Color textField = Colors.grey[200]!;
  static Color textFieldBorder = Colors.blueGrey[200]!;
  static Color submitIconOn = Colors.green[600]!;
  static Color submitIconOff = Colors.grey;
  static Color textFieldIcon = Colors.grey;
  static Color messageBoxReceiver = Colors.yellow[200]!;
  static Color messageBoxSender = Colors.green[200]!;

}

enum LoginMethod {
  google,
  apple,
  facebook,
  kakao,
  naver,
  none,
}
