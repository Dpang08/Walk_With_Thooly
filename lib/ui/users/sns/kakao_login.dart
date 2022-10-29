import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';

import 'package:walk_with_thooly/controller/state_controller.dart';
import 'package:walk_with_thooly/resources/model/user_model.dart';

final StateService _service = Get.put(StateService());

class KakaoLogin {
  KakaoLogin();
  static final KakaoLogin instance = KakaoLogin();

  bool isLogin = false;
  UserModel userInfo = UserModel();
  String? thumbnail;    // url for thumbnail images

  Future<String> login() async {
    String result = '';
    /// login process with SNS
    await _kakaoLogin();
    /// check if userID is existed @ database or new comer
    if (isLogin && userInfo.userid != null) {
      bool? isFound = await _checkIdFromFirestore();
      if (isFound != null && isFound) {   // userid found
        result = 'success';
      } else if (isFound != null && !isFound) {   // userid not found
        result =  'new';
      } else {
        result =  'error';    // in case, error occurred
      }
    } else {
      result =  'cancel';
    }
    return result;
  }

  Future<bool> createID() async {
    bool result = false;
    /// save user info to state service container
    _service.userInfo = userInfo.obs;
    // await _storage.write(Keys.USERINFO, userInfo.toFirestore());   // save userinfo in getStorage
    /// add new user in firestore
    // await _fbService.addUser(userInfo).then((_) {
    //   result = true;
    // }).catchError((err) {
    //   if (err is PlatformException && err.code == 'CANCELED') {
    //   } else {
    //     Get.snackbar('error @ create account', '$err');
    //   }
    //   result = false;
    // });
    return result;
  }

  Future<void> _kakaoLogin() async {
    /// 카카오톡 설치 여부 확인
    /// 카카오톡이 설치된 기기에서는 ID, 비밀번호 입력 없이 간편하게 로그인할 수 있도록 함
    /// 카카오톡에 연결(로그인)된 카카오계정이 없는 경우, 카카오계정으로 로그인 가능하도록 함
    var isKakaoInstalled = await isKakaoTalkInstalled();
    if (isKakaoInstalled) {
      try {
        await UserApi.instance.loginWithKakaoTalk().then((_) => isLogin = true);
        /// update Kakao User info into UserInfo model for internal use
        await _kakaoUserInfo();

      } catch (err) {
        /// 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
        /// 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
        if (err is PlatformException && err.code == 'CANCELED') {
          isLogin = false;
        }
        /// 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
        try {
          await UserApi.instance.loginWithKakaoAccount().then((_) => isLogin = true);
          /// update Kakao User info into UserInfo model for internal use
          await _kakaoUserInfo();

        } catch (err) {
          isLogin = false;
          if (err is PlatformException && err.code == 'CANCELED') {
          } else {
            Get.snackbar('Error @ loginWithKakaoAccount', '$err');
          }
        }
      }
    } else {    // in case no KakaoTalk installed
      try {
        await UserApi.instance.loginWithKakaoAccount().then((_) => isLogin = true);
        /// update Kakao User info into UserInfo model for internal use
        await _kakaoUserInfo();

      } catch (err) {
        isLogin = false;
        if (err is PlatformException && err.code == 'CANCELED') {
        } else {
          Get.snackbar('Error @ loginWithKakaoAccount', '$err');
        }
      }
    }
  }

  Future<void> _kakaoUserInfo() async {
    User user = await UserApi.instance.me();
    String kakaoUserId = user.id.toString();
    String? kakaoNickname = user.kakaoAccount?.profile?.nickname;
    String? userEmail = user.kakaoAccount?.email;
    thumbnail = user.kakaoAccount?.profile?.thumbnailImageUrl; // url for thumbnail images
    /// user info update - nickname, images(thumbnail)
    userInfo = UserModel(
      userid: kakaoUserId,
      password: kakaoUserId,
      username: kakaoNickname,
      email: userEmail,
      gender: 'NA',
      // countryCode: '${Get.deviceLocale?.countryCode}',
      // languageCode: '${Get.deviceLocale?.languageCode}',
      createdAt: DateTime.now(),
    );
  }

  Future<bool?> _checkIdFromFirestore() async {
    return null;

    // try {
    //   bool isFound = await _fbService.checkID(userInfo.userid!);
    //   if (isFound) {
    //     /// save user info to local storage
    //     _storage.write(Keys.USERINFO, userInfo.toFirestore());
    //     _service.userInfo = userInfo.obs;
    //     return true;
    //   } else {
    //     return false;
    //   }
    // } catch (error) {
    //   Get.snackbar('Error @ checkID from Firestore', '$error');
    //   return null;
    // }
  }

  // Future<File> _file() async {
  //   Directory dir = await getApplicationDocumentsDirectory();
  //   String pathName = p.join(dir.path, 'thumbnail.jpg');
  //   setState(() => _filename = File(pathName));
  //   print('---> file()  >> filename: $_filename');
  //   return File(pathName);
  // }
  //
  // Future<void> _saveImage() async {
  //   print('---> thumbnail  >> $_thumbnail');
  //   Image(
  //     images: NetworkToFileImage(
  //         url: _thumbnail,
  //         file: await _file()
  //     ),
  //   );
  // }

// Future<void> _loginWithKakao() async {
//   /// 기존 로그인을 통해 발급받은 토큰이 있는지 확인
//   /// 이미 로그인하여 유효한 토큰을 갖고 있는 사용자는 다시 로그인하지 않도록 함
//   /// 기존 토큰이 있는 경우에도 만료되었을 수 있으므로 유효성 확인 필요
//   if (await AuthApi.instance.hasToken()) {
//     try {
//       AccessTokenInfo tokenInfo = await UserApi.instance.accessTokenInfo();
//       print(
//           '---> _issueAccessToken()   >> 토큰 유효성 체크 성공 ${tokenInfo
//               .id} ${tokenInfo.expiresIn}');
//     } catch (error) {
//       if (error is KakaoException && error.isInvalidTokenError()) {
//         print('---> _issueAccessToken()   >> 토큰 만료 $error');
//       } else {
//         print('---> _issueAccessToken()   >> 토큰 정보 조회 실패 $error');
//       }
//       _loginKakao();
//     }
//   } else {
//     print('---> _issueAccessToken()   >> 발급된 토큰 없음');
//     _loginKakao();
//   }
// }

}