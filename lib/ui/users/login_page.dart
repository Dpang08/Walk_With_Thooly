import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:roundcheckbox/roundcheckbox.dart';
import 'package:walk_with_thooly/controller/firebase_service.dart';

import 'package:walk_with_thooly/ui/users/sns/kakao_login.dart';
import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';
import 'package:walk_with_thooly/resources/model/user_model.dart';

final StateService _service = Get.put(StateService());
final FirebaseService _fbService = Get.put(FirebaseService());
final GetStorage _storage = GetStorage(kStorageKey.CONTAINER);

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _isAutoLogin = true;   // save userinfo in local storage for future auto login
  bool _isObscure = true;   // visible/invisible mode in password field
  bool _isProgressingLogin = false;    // used for indicator   (false -> no indicator, true - indicator)
  bool _isProgressingKakao = false;    // used for indicator   (false -> no indicator, true - indicator)
  List<bool> _queryResult = [];   // result [userid, password]
  String? _userid;
  String? _password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        title: Text('Sign In'.tr, style: TextStyle(color: kColor.appbarText),
        ),
        centerTitle: true,
        backgroundColor: kColor.appbar,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (context) => IconButton(
              onPressed: () => Get.offAllNamed('/'),
              icon: Icon(CupertinoIcons.back, color: kColor.appbarMenu,)),
        ),
      ),
      backgroundColor: kColor.background,
      resizeToAvoidBottomInset: false,    // to avoid overflow, when keyboard comes up
      body: WillPopScope(
        child: _body(),
        onWillPop: () {
          return Future(() => false);
        },
      ),
    );
  }

  Widget _body() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          /// Title & Subtitle
          // const SizedBox(height: 20.0),
          // Text('Sign In'.tr, textAlign: TextAlign.center,
          //   style: TextStyle(fontSize: 28, color: Colors.green[700], fontWeight: FontWeight.bold),
          // ),
          const SizedBox(height: 20.0),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.7,
            child: Text('Please enter your username & password to sign in'.tr, textAlign: TextAlign.center,
              style: TextStyle(color: kColor.loginContents, fontSize: 18),
            ),
          ),
          const SizedBox(height: 15.0),
          /// test field for password input
          SizedBox(
            height: 50,
            child: TextField(
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: 'User ID'.tr,
                prefixIcon: const Icon(Icons.person_outline, size: 25),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
              ),
              onChanged: (text) {
                setState(() {_userid = text;});
              },
            ),
          ),
          const SizedBox(height: 15.0),
          /// text field for password input
          SizedBox(
            height: 50,
            child: TextField(
              obscureText: _isObscure,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Password'.tr,
                prefixIcon: const Icon(Icons.lock_outline, size: 25),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                  icon: _isObscure ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility),
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
              ),
              onChanged: (text) {
                setState(() {_password = text;});
              },
            ),
          ),
          const SizedBox(height: 15.0),
          /// checkbox for Auto Login once log in
          _autoLogin(),
          const SizedBox(height: 30.0),
          /// Login/Sign in button
          _loginButton(),
          const SizedBox(height: 5.0),
          /// create new account
          _supportAccount(),
          const SizedBox(height: 40.0),
          /// another method for sign in/ sign up
          const _HorizontalSpacer(),
          const SizedBox(height: 10,),
          _kakaoLogin(),    // Kakao login
        ],
      ),
    );
  }

  Widget _autoLogin() {
    return Row(
      children: [
        RoundCheckBox(
            size: 20,
            isChecked: _isAutoLogin,
            checkedColor: Colors.lightGreen[700],
            checkedWidget: const Icon(Icons.check_rounded, size: 18, color: Colors.white,),
            onTap: (value) {
              setState(() {
                _isAutoLogin = !_isAutoLogin;
              });
            }
        ),
        const SizedBox(width: 10,),   // spacer
        Text('Auto sign in'.tr, style: const TextStyle(color: Colors.black87, fontSize: 15),),
      ],
    );
  }

  Future<void> _findUser() async {
    await _fbService.findUserWithPassword(_userid!, _password!)
        .then((value) => setState(() {     // _value -> result[userid, password]
            _queryResult = value;
            _isProgressingLogin = false;
          })).catchError((err) {
            Get.snackbar('error@firebase', 'find user: $err');
            setState(() {
              _isProgressingLogin = false;
            });
          });
    if (_queryResult[0] && _queryResult[1]) {    // true - found userid & password
      UserModel userinfo = _service.userInfo.value;
      /// save to local storage to reuse for auto login
      if (_isAutoLogin) {
        _storage.write(kStorageKey.USERINFO, userinfo.toFirestore());
      }
      /// get top10Friends from firebase db
      Get.offNamed('/');
      await _fbService.getTop10Friends();
    } else if (_queryResult[0] && !_queryResult[1]) {   // ID found but PW not matched
      String title = 'Password not matched'.tr;
      String content = 'Please check your password and try again'.tr;
      _showDialog(title, content, 1);
    } else {
      String title = 'User ID not valid'.tr;
      String content = 'Please check your user ID and try again'.tr;
      _showDialog(title, content, 1);
    }

  }

  Widget _loginButton() {
    return GestureDetector(
      onTap: () async {
        /// dismiss system keyboard when click
        FocusManager.instance.primaryFocus?.unfocus();

        if (_userid !=null && _password !=null) {
          setState(() => _isProgressingLogin = true);    // set true for indicator, after loading set to false
          /// find user via firestore
          await _findUser();  // result[userid, password]
        }
      },
      child: Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: kColor.buttonColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isProgressingLogin
            ? CupertinoActivityIndicator(radius: 15, color: kColor.buttonText)
            : Text('SIGN IN'.tr, style: TextStyle(fontSize: 20, color: kColor.buttonText,
                  fontWeight: FontWeight.bold,),
              ),
      ),
    );
  }

  Future _showDialog(String title, String content, int mode) {
    List<CupertinoDialogAction> actions = [];
    if (mode == 1) {    // in case error
      actions = [CupertinoDialogAction(
          child: Text('Close'.tr),
          onPressed: () => Get.back(),
        )];
    } else if (mode == 2) {   // in case login success (back home)
      actions = [CupertinoDialogAction(
        child: Text('Confirm'.tr),
        onPressed: () => Get.offNamed('/'),
      )];
    } else if (mode == 3) {   // in case create new ID (yes/no)
      actions = [
        CupertinoDialogAction(
          child: Text('NO'.tr),
          onPressed: () => Get.back(),
        ),
        CupertinoDialogAction(
          child: Text('YES'.tr),
          onPressed: () {
            _createKakaoID();
            Get.back();
          } ,
        ),
      ];
    }

    return showCupertinoDialog(
      context: context,
      builder: (context) => Theme(
        data: ThemeData.light(),
        child: CupertinoAlertDialog(
          title: Text(title,),
          content: Text(content,),
          actions: actions,
        ),
      ),
    );
  }

  void _createKakaoID() async {
    setState(() => _isProgressingKakao = true);   // true to run indicator
    bool isSuccess = await KakaoLogin.instance.createID();
    if (isSuccess) {
      String title = 'Registration completed successfully'.tr;
      String content = 'Thank you for your registration'.tr;
      setState(() => _isProgressingKakao = false);    // set false to stop indicator
      _showDialog(title, content, 2);
    } else {
      String title = 'Error occurred'.tr;
      String content = 'Please try again a moment later'.tr;
      setState(() => _isProgressingLogin = false);    // set false to stop indicator
      _showDialog(title, content, 1);
    }
  }

  /// forget password button
  Widget _forgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => Get.offNamed(kRoutes.FORGOT_PASSWORD),
        child: Container(
          alignment: Alignment.center,
          height: 40,
          child: Text('Forgot Password?'.tr,
            style: TextStyle(fontSize: 18, color: kColor.loginContents),
          ),
        ),
      ),
    );
  }

  Widget _signUp() {
    return GestureDetector(
      onTap: () => Get.toNamed('/termsAgreement'),
      child: Container(
        alignment: Alignment.center,
        height: 40,
        child: Text('Create account'.tr,
          style: TextStyle(fontSize: 18, color: kColor.loginContents),
        ),
      ),
    );
  }

  Widget _supportAccount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _forgotPassword(),
        const SizedBox(width: 12.5,),
        Container(    // spacer '|'
          height: 15,
          width: 2,
          color: Colors.blueGrey[300],
        ),
        const SizedBox(width: 12.5,),
        _signUp()
      ],
    );
  }

  Widget _kakaoLogin() {
    return ListTile(
      tileColor: Colors.yellowAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isProgressingKakao
                ? const CupertinoActivityIndicator(radius: 15, color: Colors.black,)
                : Text('kakao_login'.tr,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                    ),
                  ),
              const SizedBox(width: 40,)
            ]
          ),
      leading: Image.asset(kConst.kakaoImage, height: 30, width: 30,),
      onTap: () {
        // setState(() => _isProgressingKakao = true);
        // _kakaoLoginProcess();
      }
    );
  }

  Future<void> _kakaoLoginProcess() async {
    String status = await KakaoLogin.instance.login();    // return [success, new, error, cancel]
    if (status == 'success') {
      String title = 'Succeed to login'.tr;
      String content = 'Welcome to CaddiBoy.\nHope to enjoy the app'.tr;
      setState(() => _isProgressingKakao = false);    // set false to stop indicator
      _showDialog(title, content, 2);
    } else if (status == 'new') {
      String title = 'User ID not found'.tr;
      String content = 'Would you proceed to register as new user with Kakao account?'.tr;
      setState(() => _isProgressingKakao = false);    // set false to stop indicator
      _showDialog(title, content, 3);
    } else if (status == 'error') {
      String title = 'Error occurred'.tr;
      String content = 'Please try again a moment later'.tr;
      setState(() => _isProgressingKakao = false);    // set false to stop indicator
      _showDialog(title, content, 1);
    } else {
      setState(() => _isProgressingKakao = false);    // set false to stop indicator
    }
  }

  // Widget _facebookLogin() {
  //   return ListTile(
  //     tileColor: Colors.blue[800],
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
  //     title: Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Text('facebook_login'.tr,
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.w400,
  //               fontSize: 18,
  //             ),
  //           ),
  //           SizedBox(width: 40,)
  //         ]
  //     ),
  //     leading: Icon(FontAwesomeIcons.facebookSquare, color: Colors.white, size: 35),
  //     onTap: () async {
  //       setState(() => _busy = true);
  //       print('---> confirm button: busy - $_busy');
  //       await Future.delayed(Duration(seconds: 3)).then((_) =>
  //           setState(() => _busy = false)
  //       );
  //       print('---> confirm button: busy - $_busy');
  //     },
  //   );
  // }
  //
  // Widget _googleLogin() {
  //   return ListTile(
  //     tileColor: Colors.blue,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
  //     title: Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Text('google_login'.tr,
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontWeight: FontWeight.w400,
  //                   fontSize: 18,
  //                 ),
  //               ),
  //               SizedBox(width: 40,)
  //             ]
  //         ),
  //     leading: Icon(FontAwesomeIcons.google, color: Colors.white, size: 30),
  //     onTap: () async {
  //       setState(() => _busy = true);
  //       print('---> confirm button: busy - $_busy');
  //       await Future.delayed(Duration(seconds: 3)).then((_) =>
  //           setState(() => _busy = false)
  //       );
  //       print('---> confirm button: busy - $_busy');
  //     },
  //   );
  // }

}

class _HorizontalSpacer extends StatelessWidget {
  const _HorizontalSpacer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width * 0.9;
    return SizedBox(
      height: 30,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          Center(
            child: Container(
              height: 2,
              width: width,
              color: Colors.grey[300],
            ),
          ),
          Center(
            child: Container(
                padding: const EdgeInsets.only(left:15, right: 15),
                color: kColor.background,
                child: Text('sns_login'.tr, style: const TextStyle(color: Colors.black54),)
            ),
          ),
        ],
      ),
    );
  }
}
