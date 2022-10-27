import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
// import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:walk_with_thooly/resources/kConstant.dart';

import 'resources/languages.dart';
import 'routes/app_pages.dart';
import 'ui/homepage.dart';

void main() async {
  await GetStorage.init(kStorageKey.CONTAINER);
  /// make sure the flutter was initiated properly at first
  WidgetsFlutterBinding.ensureInitialized();
  /// initialize the firebase core
  await Firebase.initializeApp().then((_) => _initFirestore());
  /// init for Kakao login
  // KakaoSdk.init(nativeAppKey: MyConst.kakaoNativeAppKey);
  /// lock the screen orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
    ]).then((_) => runApp(const MyApp())
  );
  /// screen size (width, height), font size (small, medium, large)
  // ScreenInfo().init();
}

Future<void> _initFirestore() async {
  FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  build(context) {
    return GetMaterialApp(
      title: 'Walking With Thooly',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      defaultTransition: Transition.rightToLeftWithFade,
      /// Locale setting
      translations: Languages(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      getPages: AppPages().pages,
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      home: const Homepage(),
    );
  }
}
