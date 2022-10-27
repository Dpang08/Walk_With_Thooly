import 'package:get/get.dart';

import 'package:walk_with_thooly/ui/users/login_page.dart';
import 'package:walk_with_thooly/ui/users/reset_password.dart';
import 'package:walk_with_thooly/ui/users/create_account_page.dart';
import 'package:walk_with_thooly/ui/users/terms_agreement.dart';
import 'package:walk_with_thooly/ui/users/forgot_password.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';
import 'package:walk_with_thooly/ui/journal_page.dart';
import 'package:walk_with_thooly/ui/users/terms_policy.dart';
import 'package:walk_with_thooly/ui/user_page.dart';
import 'package:walk_with_thooly/ui/widget/my_map.dart';
import 'package:walk_with_thooly/ui/widget/message.dart';
import 'package:walk_with_thooly/ui/message_page.dart';
import 'package:walk_with_thooly/ui/pages/settings.dart';

class AppPages {

  final pages = [
    GetPage(name: kRoutes.LOGIN, page: () => const Login()),
    GetPage(name: kRoutes.CREATE_ACCOUNT, page: () => const CreateAccount()),
    GetPage(name: kRoutes.TERMS_AGREEMENT, page: () => const TermsAgreement()),
    GetPage(name: kRoutes.TERMS_POLICY, page: () => const TermsPolicy()),
    GetPage(name: kRoutes.RESET_PASSWROD, page: () => const ResetPassword()),
    GetPage(name: kRoutes.FORGOT_PASSWORD, page: () => const ForgotPassword()),
    GetPage(name: kRoutes.JOURNAL, page: () => const JournalPage()),
    GetPage(name: kRoutes.USER_PAGE, page: () => const UserPage()),
    GetPage(name: kRoutes.MAP, page: () => const MyGoogleMap()),
    GetPage(name: kRoutes.MESSAGING, page: () => const Messaging()),
    GetPage(name: kRoutes.MESSAGE_PAGE, page: () => const MessagePage()),
    GetPage(name: kRoutes.SETTINGS, page: () => const Settings()),
  ];
}